from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

from PIL import Image, ImageStat


DEFAULT_DOCS = {
    "style_bible": "GAME_ART_UI.md",
    "count": "docs/asset_count_matrix.md",
    "coverage": "docs/asset_coverage_matrix.md",
    "composition": "docs/ui_composition_contracts.md",
    "screenshots": "docs/screenshot_verification_checklist.md",
    "gate": "docs/art_pipeline_validation_gate.md",
}

REQUIRED_STATUSES = [
    "CAPTURED_RAW",
    "RUNTIME_FIT_PASS",
    "RUNTIME_FIT_BLOCKED",
    "ART_DESIGN_PENDING",
    "OWNER_APPROVED",
]


IMAGE_QUALITY_PROFILES = {
    "prototype": {
        "min_runtime_ui_source_scale": 3,
        "min_editor_background_size": [480, 270],
        "min_ui_reference_viewport": [480, 270],
    },
    "mobile_high_quality": {
        "min_runtime_ui_source_scale": 4,
        "min_editor_background_size": [1280, 720],
        "min_ui_reference_viewport": [480, 270],
    },
    "mobile_ultra": {
        "min_runtime_ui_source_scale": 6,
        "min_editor_background_size": [1920, 1080],
        "min_ui_reference_viewport": [480, 270],
    },
}
RECT_SEMANTIC_BOUNDARY_LABEL = "rect semantic boundary"

UI_SOURCE_RESIZE_MODES = {
    "cover_crop_exact",
    "contain_with_bleed_exact",
}

PAYLOAD_BAKE_FLAGS = [
    "contains_runtime_text",
    "contains_runtime_icon",
    "contains_runtime_image",
    "contains_runtime_control",
]

DEFAULT_AGENT_DRAWN_OWNER_PROOF_DIRS = [
    "docs/screenshots/live_debug/owner_compare",
]

DEFAULT_AGENT_DRAWN_OWNER_PROOF_GLOBS = [
    "docs/screenshots/**/*owner*yellow*regions*.png",
    "docs/screenshots/**/*owner_compare*.png",
]

DEFAULT_SCREENSHOT_CAPTURE_POLICY = {
    "approved_methods": [
        "godot_scene_capture_runtime_stretch",
        "foreground_window_capture",
    ],
    "forbidden_methods": [
        "PrintWindow",
    ],
    "requires_visual_inspection": True,
    "requires_nonblank_pixel_audit": True,
    "min_sampled_unique_colors": 16,
    "min_luma_stddev": 2.0,
    "min_luma_mean": 1.0,
}

def validate_art_ui_gate(game_root: Path, contract_path: Path | None = None) -> list[str]:
    game_root = game_root.resolve()
    failures: list[str] = []
    contract = _load_contract(contract_path, failures)
    docs = dict(DEFAULT_DOCS)
    docs.update(contract.get("docs", {}))
    texts: dict[str, str] = {}
    for label, rel_path in docs.items():
        path = game_root / rel_path
        if not path.exists():
            failures.append(f"missing required art/UI gate doc: {rel_path}")
            texts[label] = ""
            continue
        texts[label] = path.read_text(encoding="utf-8")

    _require_core_tokens(texts, failures)
    _require_contract_tokens(texts, contract, failures)
    _require_no_fallback_contract_values(contract, failures)
    _require_ssot_registry_rules(game_root, contract, texts, failures)
    screenshot_rows = _require_screenshot_rows(texts.get("screenshots", ""), contract, failures)
    _require_art_process_rules(game_root, contract, texts, screenshot_rows, failures)
    _require_reference_lock_rules(game_root, contract, texts, failures)
    _require_source_extraction_rules(game_root, contract, texts, failures)
    screenshot_capture_policy = _require_screenshot_capture_policy(contract, texts, failures)
    _require_screenshot_dimensions(game_root, contract, screenshot_capture_policy, failures)
    _require_image_quality_profile(game_root, contract, failures)
    _require_visual_composition_rules(contract, screenshot_rows, failures)
    _require_manual_placement_rules(game_root, contract, screenshot_rows, failures)
    _require_no_agent_drawn_owner_proof(game_root, contract, failures)
    _require_no_forbidden_claims(texts, failures)
    return failures


def _load_contract(contract_path: Path | None, failures: list[str]) -> dict:
    if contract_path is None:
        return {}
    if not contract_path.exists():
        failures.append(f"missing art/UI gate contract: {contract_path}")
        return {}
    try:
        return json.loads(contract_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"invalid art/UI gate contract JSON: {exc}")
        return {}

def _require_no_fallback_contract_values(contract: dict, failures: list[str]) -> None:
    if not isinstance(contract, dict):
        return
    for path, key in _fallback_contract_keys(contract):
        failures.append(
            f"art/UI contract key is forbidden by no-fallback doctrine: {path}.{key}"
        )

def _fallback_contract_keys(value: object, path: str = "contract") -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    if isinstance(value, dict):
        for key, child in value.items():
            key_text = str(key)
            if _is_forbidden_fallback_contract_key(key_text):
                found.append((path, key_text))
            child_path = f"{path}.{key_text}"
            found.extend(_fallback_contract_keys(child, child_path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(_fallback_contract_keys(child, f"{path}[{index}]"))
    return found

def _is_forbidden_fallback_contract_key(key: str) -> bool:
    normalized = key.lower()
    if re.search(r"(^|[_\-.])fallback([_\-.]|$)", normalized):
        return True
    if re.search(r"(^|[_\-.])default([_\-.]|$)", normalized):
        return True
    if normalized.startswith("fallback_") or normalized.endswith("_fallback"):
        return True
    if normalized.startswith("default_") or normalized.endswith("_default"):
        return True
    return False


def _require_core_tokens(texts: dict[str, str], failures: list[str]) -> None:
    joined = "\n".join(texts.values())
    for token in REQUIRED_STATUSES + [
        "RUNTIME_FIT_PASS is not final art design approval",
        "Art Design Approval Gate",
    ]:
        if not _contains_token(joined, token):
            failures.append(f"missing core art/UI gate token: {token}")
    if re.search(r"\b(final|done|complete)\b", joined, re.IGNORECASE):
        if "ART_DESIGN_PENDING" not in joined or "OWNER_APPROVED" not in joined:
            failures.append("final/done/complete language appears without art-design status vocabulary")


def _require_contract_tokens(texts: dict[str, str], contract: dict, failures: list[str]) -> None:
    composition = texts.get("composition", "")
    coverage = texts.get("coverage", "")
    count = texts.get("count", "")
    screenshots = texts.get("screenshots", "")
    all_text = "\n".join(texts.values())

    for surface in contract.get("required_surfaces", []):
        if not _contains_token(composition, str(surface)):
            failures.append(f"missing UI composition surface: {surface}")
    for key in contract.get("required_asset_keys", []):
        token = str(key)
        if not _contains_token(coverage, token):
            failures.append(f"missing coverage asset key: {key}")
        if not _contains_token(count, token):
            failures.append(f"missing count asset key: {key}")
    for token in contract.get("required_tokens", []):
        if not _contains_token(all_text, str(token)):
            failures.append(f"missing game art/UI gate token: {token}")
    for token in contract.get("required_screenshot_tokens", []):
        if not _contains_token(screenshots, str(token)):
            failures.append(f"missing screenshot gate token: {token}")

def _require_ssot_registry_rules(game_root: Path, contract: dict, texts: dict[str, str], failures: list[str]) -> None:
    registry_contract = contract.get("ssot_registry")
    if not isinstance(registry_contract, dict):
        failures.append("ssot_registry required in art/UI gate contract")
        return

    registry_path_value = registry_contract.get("path")
    if not isinstance(registry_path_value, str) or not registry_path_value:
        failures.append("ssot_registry.path must be a game-relative JSON path")
        return
    registry_path = Path(registry_path_value)
    if registry_path.is_absolute():
        failures.append("ssot_registry.path must not be absolute")
        return
    resolved_registry_path = game_root / registry_path
    if not resolved_registry_path.exists():
        failures.append(f"ssot_registry.path missing file: {registry_path_value}")
        return

    try:
        registry = json.loads(resolved_registry_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"ssot_registry invalid JSON: {exc}")
        return
    if not isinstance(registry, dict):
        failures.append("ssot_registry JSON must be an object")
        return

    if registry.get("policy") != "one_function_one_canonical":
        failures.append("ssot_registry.policy must be one_function_one_canonical")
    functions = registry.get("functions")
    if not isinstance(functions, list) or not functions:
        failures.append("ssot_registry.functions must be a nonempty list")
        return

    allowed_roles = {
        "runtime_ssot",
        "owner_input_ssot",
        "doc_contract",
        "generated_artifact",
        "evidence",
    }
    seen_function_ids: dict[str, str] = {}
    seen_canonical_files: dict[str, str] = {}

    for index, entry in enumerate(functions):
        if not isinstance(entry, dict):
            failures.append(f"ssot_registry.functions[{index}] must be an object")
            continue
        function_id = str(entry.get("function_id", ""))
        if not function_id:
            failures.append(f"ssot_registry.functions[{index}].function_id required")
            continue
        canonical_role = str(entry.get("canonical_role", ""))
        if canonical_role not in allowed_roles:
            failures.append(f"ssot_registry {function_id}.canonical_role must be one of {sorted(allowed_roles)}")
        canonical_file = str(entry.get("canonical_file", ""))
        if not canonical_file:
            failures.append(f"ssot_registry {function_id}.canonical_file required")
            continue

        previous_file = seen_function_ids.get(function_id)
        if previous_file != None:
            failures.append(
                f"ssot_registry duplicate function_id {function_id}: {previous_file} and {canonical_file}"
            )
        seen_function_ids[function_id] = canonical_file

        previous_function = seen_canonical_files.get(canonical_file)
        if previous_function != None and previous_function != function_id:
            failures.append(
                f"ssot_registry canonical_file reused by multiple function_ids: {canonical_file}"
            )
        seen_canonical_files[canonical_file] = function_id

        canonical_path = _require_registry_file(game_root, canonical_file, f"ssot_registry {function_id}.canonical_file", failures)
        if canonical_path == None:
            continue

        _require_registry_file_list(game_root, function_id, entry, "runtime_consumers", failures)
        _require_registry_file_list(game_root, function_id, entry, "evidence_files", failures)
        _require_registry_derived_files(game_root, function_id, canonical_file, entry, failures)

    joined_docs = "\n".join(texts.values())
    if "one_function_one_canonical" not in joined_docs and "one function" not in joined_docs.lower():
        failures.append("ssot_registry policy must be documented in gate docs")

def _require_registry_file_list(
    game_root: Path,
    function_id: str,
    entry: dict,
    field_name: str,
    failures: list[str],
) -> None:
    values = entry.get(field_name, [])
    if values == None:
        values = []
    if not isinstance(values, list):
        failures.append(f"ssot_registry {function_id}.{field_name} must be a list")
        return
    for value in values:
        if isinstance(value, dict):
            role = str(value.get("role", ""))
            if role and role not in ["runtime_ssot", "owner_input_ssot", "doc_contract", "generated_artifact", "evidence"]:
                failures.append(f"ssot_registry {function_id}.{field_name} role is invalid: {role}")
            path_value = value.get("path")
        else:
            path_value = value
        _require_registry_file(game_root, path_value, f"ssot_registry {function_id}.{field_name}", failures)

def _require_registry_derived_files(
    game_root: Path,
    function_id: str,
    canonical_file: str,
    entry: dict,
    failures: list[str],
) -> None:
    derived_files = entry.get("derived_files", [])
    if derived_files == None:
        derived_files = []
    if not isinstance(derived_files, list):
        failures.append(f"ssot_registry {function_id}.derived_files must be a list")
        return
    for item in derived_files:
        if not isinstance(item, dict):
            failures.append(f"ssot_registry {function_id}.derived_files entries must be objects")
            continue
        path_value = item.get("path")
        source_value = item.get("source")
        if source_value != canonical_file:
            failures.append(
                f"ssot_registry {function_id}.derived_files source must match canonical_file {canonical_file}"
            )
        derived_path = _require_registry_file(game_root, path_value, f"ssot_registry {function_id}.derived_files", failures)
        if derived_path == None:
            continue
        if isinstance(source_value, str) and source_value:
            _require_generated_source_trace(derived_path, source_value, function_id, failures)

def _require_generated_source_trace(
    path: Path,
    source_value: str,
    function_id: str,
    failures: list[str],
) -> None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        failures.append(f"ssot_registry {function_id} generated artifact is not text-readable: {path.name}")
        return
    if source_value in text:
        return
    failures.append(
        f"ssot_registry {function_id} generated artifact missing source trace: {path.name} -> {source_value}"
    )

def _require_registry_file(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    if not isinstance(value, str) or not value:
        failures.append(f"{label} must be a game-relative path")
        return None
    path = Path(value)
    if path.is_absolute():
        failures.append(f"{label} must not be absolute")
        return None
    resolved = game_root / path
    if not resolved.exists():
        failures.append(f"{label} missing file: {value}")
        return None
    return resolved


def _table_cells(line: str) -> list[str]:
    return [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]


def _plain(text: str) -> str:
    return text.replace("`", "")


def _contains_token(text: str, token: str) -> bool:
    return token in text or _plain(token) in _plain(text)


def _parse_rows(text: str) -> dict[str, list[str]]:
    rows: dict[str, list[str]] = {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = _table_cells(line)
        if len(cells) < 2 or cells[0] in ["Screen", "---", "Status", "State"] + REQUIRED_STATUSES:
            continue
        rows[cells[0]] = cells
    return rows


def _require_screenshot_rows(text: str, contract: dict, failures: list[str]) -> dict[str, list[str]]:
    rows = _parse_rows(text)
    for screen, tokens in contract.get("runtime_fit_rows", {}).items():
        cells = rows.get(str(screen))
        if not cells:
            failures.append(f"missing runtime-fit screenshot row: {screen}")
            continue
        joined = " | ".join(cells)
        for token in tokens:
            if not _contains_token(joined, str(token)):
                failures.append(f"screenshot row {screen} missing runtime-fit token: {token}")
    for screen, tokens in contract.get("art_design_pending_rows", {}).items():
        cells = rows.get(str(screen))
        if not cells:
            failures.append(f"missing art-design screenshot row: {screen}")
            continue
        joined = " | ".join(cells)
        for token in tokens:
            if not _contains_token(joined, str(token)):
                failures.append(f"screenshot row {screen} missing art-design token: {token}")
    for screen, cells in rows.items():
        if len(cells) < 6:
            continue
        joined = " | ".join(cells)
        if "RUNTIME_FIT_BLOCKED" in joined:
            failures.append(f"runtime visual blocker remains: {screen}")
    return rows

def _require_art_process_rules(
    game_root: Path,
    contract: dict,
    texts: dict[str, str],
    screenshot_rows: dict[str, list[str]],
    failures: list[str],
) -> None:
    process = contract.get("art_process")
    if process == None:
        return
    if not isinstance(process, dict):
        failures.append("art_process must be an object")
        return

    valid_pipeline_states = [
        "ART_PIPELINE_RESET",
        "ART_PIPELINE_ACTIVE",
        "ART_PIPELINE_FINAL_REVIEW",
    ]
    valid_theme_states = [
        "MASTER_THEME_PENDING",
        "MASTER_THEME_APPROVED",
    ]
    valid_source_states = [
        "ART_SOURCE_NOT_READY",
        "SOURCE_ASSET_APPROVED",
    ]
    valid_old_art_states = [
        "OLD_ART_REJECTED",
        "OLD_ART_PROTOTYPE_ONLY",
        "OLD_ART_APPROVED_REFERENCE_ONLY",
    ]

    status = str(process.get("status", ""))
    theme_status = str(process.get("master_theme_status", ""))
    source_status = str(process.get("source_asset_status", ""))
    old_art_status = str(process.get("old_art_status", ""))
    manual_allowed = process.get("manual_placement_allowed")

    if status not in valid_pipeline_states:
        failures.append(f"art_process.status must be one of {valid_pipeline_states}: {status}")
    if theme_status not in valid_theme_states:
        failures.append(f"art_process.master_theme_status must be one of {valid_theme_states}: {theme_status}")
    if source_status not in valid_source_states:
        failures.append(f"art_process.source_asset_status must be one of {valid_source_states}: {source_status}")
    if old_art_status not in valid_old_art_states:
        failures.append(f"art_process.old_art_status must be one of {valid_old_art_states}: {old_art_status}")
    if not isinstance(manual_allowed, bool):
        failures.append("art_process.manual_placement_allowed must be true or false")

    joined_docs = "\n".join(texts.values())
    for token in [status, theme_status, source_status, old_art_status]:
        if token and not _contains_token(joined_docs, token):
            failures.append(f"art_process token missing from docs: {token}")

    if status == "ART_PIPELINE_RESET":
        if theme_status != "MASTER_THEME_PENDING":
            failures.append("ART_PIPELINE_RESET requires art_process.master_theme_status = MASTER_THEME_PENDING")
        if source_status != "ART_SOURCE_NOT_READY":
            failures.append("ART_PIPELINE_RESET requires art_process.source_asset_status = ART_SOURCE_NOT_READY")
        if old_art_status != "OLD_ART_REJECTED":
            failures.append("ART_PIPELINE_RESET requires art_process.old_art_status = OLD_ART_REJECTED")
        if manual_allowed is not False:
            failures.append("ART_PIPELINE_RESET requires art_process.manual_placement_allowed = false")

    if theme_status != "MASTER_THEME_APPROVED" or source_status != "SOURCE_ASSET_APPROVED":
        for screen, cells in screenshot_rows.items():
            joined = " | ".join(cells)
            if "RUNTIME_FIT_PASS" in joined or "OWNER_APPROVED" in joined:
                failures.append(
                    f"{screen} cannot claim RUNTIME_FIT_PASS or OWNER_APPROVED before MASTER_THEME_APPROVED and SOURCE_ASSET_APPROVED"
                )

    manual = contract.get("manual_placement", {})
    if manual_allowed is False and isinstance(manual, dict):
        if manual.get("required") is True:
            failures.append("manual_placement.required must be false while art_process.manual_placement_allowed is false")
        surfaces = manual.get("surfaces", {})
        if isinstance(surfaces, dict) and surfaces:
            failures.append("manual_placement.surfaces must be empty while art_process.manual_placement_allowed is false")
    if manual_allowed is False:
        for screen, cells in screenshot_rows.items():
            joined = " | ".join(cells)
            if "READY_FOR_OWNER_ADJUSTMENT" in joined or "OWNER_PLACEMENT_APPROVED" in joined:
                failures.append(f"{screen} has manual-placement status while manual placement is disabled")
        index_path = game_root / "docs" / "art_ui_manual_placement" / "index.html"
        if index_path.exists():
            index_text = index_path.read_text(encoding="utf-8")
            if "MANUAL_PLACEMENT_DISABLED" not in index_text:
                failures.append("manual placement index must show MANUAL_PLACEMENT_DISABLED while disabled")
            if "href=\"upgrade_" in index_text or "href=\"level_" in index_text or "href=\"result_" in index_text:
                failures.append("manual placement index must not link active editor pages while disabled")
            for config_path in sorted((game_root / "docs" / "art_ui_manual_placement").glob("*_region_editor_config.json")):
                config_text = config_path.read_text(encoding="utf-8")
                if "READY_FOR_OWNER_ADJUSTMENT" in config_text or "OWNER_PLACEMENT_APPROVED" in config_text:
                    failures.append(
                        f"manual placement config must not claim active owner placement while disabled: {config_path.relative_to(game_root)}"
                    )
                try:
                    config_data = json.loads(config_text)
                except json.JSONDecodeError as exc:
                    failures.append(f"manual placement config invalid JSON while disabled: {config_path.relative_to(game_root)}: {exc}")
                    continue
                if config_data.get("status") != "DRAFT_SEED_ONLY":
                    failures.append(
                        f"manual placement config must be DRAFT_SEED_ONLY while disabled: {config_path.relative_to(game_root)}"
                    )
            for html_path in sorted((game_root / "docs" / "art_ui_manual_placement").glob("*_region_editor.html")):
                html_text = html_path.read_text(encoding="utf-8")
                if 'config.status || "READY_FOR_OWNER_ADJUSTMENT"' in html_text or "config.status || 'READY_FOR_OWNER_ADJUSTMENT'" in html_text:
                    failures.append(
                        "manual placement editor must not invent READY_FOR_OWNER_ADJUSTMENT while disabled: "
                        f"{html_path.relative_to(game_root)}"
                    )


def _require_reference_lock_rules(game_root: Path, contract: dict, texts: dict[str, str], failures: list[str]) -> None:
    reference_lock = contract.get("reference_lock")
    if reference_lock == None:
        return
    if not isinstance(reference_lock, dict):
        failures.append("reference_lock must be an object")
        return

    valid_reference_states = ["REFERENCE_SHEET_PENDING", "REFERENCE_SHEET_LOCKED"]
    valid_generation_states = ["GENERATION_SPEC_PENDING", "GENERATION_SPEC_LOCKED"]
    reference_status = str(reference_lock.get("reference_sheet_status", ""))
    generation_status = str(reference_lock.get("generation_spec_status", ""))
    if reference_status not in valid_reference_states:
        failures.append(f"reference_lock.reference_sheet_status must be one of {valid_reference_states}: {reference_status}")
    if generation_status not in valid_generation_states:
        failures.append(f"reference_lock.generation_spec_status must be one of {valid_generation_states}: {generation_status}")

    process = contract.get("art_process", {})
    if isinstance(process, dict) and process.get("source_asset_status") == "SOURCE_ASSET_APPROVED":
        if reference_status != "REFERENCE_SHEET_LOCKED":
            failures.append("SOURCE_ASSET_APPROVED requires REFERENCE_SHEET_LOCKED")
        if generation_status != "GENERATION_SPEC_LOCKED":
            failures.append("SOURCE_ASSET_APPROVED requires GENERATION_SPEC_LOCKED")

    joined_docs = "\n".join(texts.values())
    for token in [reference_status, generation_status]:
        if token and not _contains_token(joined_docs, token):
            failures.append(f"reference_lock token missing from docs: {token}")

    if reference_status == "REFERENCE_SHEET_LOCKED":
        sheet_path = _game_relative_markdown_path(game_root, reference_lock.get("reference_sheet"), "reference_lock.reference_sheet", failures)
        if sheet_path != None:
            _require_reference_sheet_content(sheet_path, reference_lock, failures)
    if generation_status == "GENERATION_SPEC_LOCKED":
        spec_path = _game_relative_markdown_path(game_root, reference_lock.get("generation_spec"), "reference_lock.generation_spec", failures)
        if spec_path != None:
            _require_generation_spec_content(spec_path, failures)


def _require_reference_sheet_content(path: Path, reference_lock: dict, failures: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in ["Reference", "Bucket", "Learn This", "Do Not Copy", "Source Use"]:
        if token not in text:
            failures.append(f"{path.name} missing reference table token: {token}")
    rows = []
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = _table_cells(line)
        if len(cells) < 5 or cells[0] in ["Reference", "---"]:
            continue
        rows.append(cells)
    try:
        min_references = int(reference_lock.get("min_references", 10))
        max_references = int(reference_lock.get("max_references", 30))
    except (TypeError, ValueError):
        failures.append("reference_lock min_references and max_references must be integers")
        return
    if len(rows) < min_references:
        failures.append(f"{path.name} reference count {len(rows)} below min {min_references}")
    if len(rows) > max_references:
        failures.append(f"{path.name} reference count {len(rows)} above max {max_references}")
    buckets = {row[1] for row in rows}
    for bucket in reference_lock.get("required_buckets", []):
        if str(bucket) not in buckets:
            failures.append(f"{path.name} missing required bucket: {bucket}")
    for index, row in enumerate(rows, start=1):
        reference, bucket, learn, do_not_copy, source_use = row[:5]
        if not reference.startswith("http") and not reference.startswith("docs/") and not reference.startswith("res://"):
            failures.append(f"{path.name} row {index} reference must be URL or project path")
        if not bucket:
            failures.append(f"{path.name} row {index} missing bucket")
        if not learn:
            failures.append(f"{path.name} row {index} missing Learn This")
        if not do_not_copy:
            failures.append(f"{path.name} row {index} missing Do Not Copy")
        if not source_use:
            failures.append(f"{path.name} row {index} missing Source Use")


def _require_generation_spec_content(path: Path, failures: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in [
        "Vietnam Tech Fantasy Hybrid",
        "40% Vietnamese visual language",
        "60% sci-fi combat tech",
        "runtime job",
        "asset family",
        "9Router",
        "cx/gpt-5.5-image",
        "Photoroom",
        "polygon",
        "mobile_ultra",
        "Do not rename skills",
    ]:
        if token not in text:
            failures.append(f"{path.name} missing generation spec token: {token}")

def _require_source_extraction_rules(game_root: Path, contract: dict, texts: dict[str, str], failures: list[str]) -> None:
    source_extraction = contract.get("source_extraction")
    if source_extraction == None:
        return
    if not isinstance(source_extraction, dict):
        failures.append("source_extraction must be an object")
        return

    valid_statuses = [
        "SOURCE_MASTER_REJECTED_REGEN_REQUIRED",
        "SOURCE_MASTER_CANDIDATE_PENDING_PHOTOROOM",
        "OWNER_POLYGON_OUTLINE_PENDING",
        "OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA",
        "OWNER_POLYGON_OUTLINE_APPROVED",
        "EXTRACTION_QC_PASS",
        "SOURCE_ASSET_APPROVED",
    ]
    if not isinstance(source_extraction.get("required"), bool):
        failures.append("source_extraction.required must be true or false")
    families = source_extraction.get("families")
    if not isinstance(families, dict) or not families:
        failures.append("source_extraction.families must be a nonempty object")
        return

    joined_docs = "\n".join(texts.values())
    for token in [
        "owner_manual_polygon",
        "OWNER_POLYGON_OUTLINE_PENDING",
        "No auto-hull",
        "No grid slicing",
    ]:
        if not _contains_token(joined_docs, token):
            failures.append(f"source extraction token missing from docs: {token}")

    for family_name, family in families.items():
        if not isinstance(family, dict):
            failures.append(f"source_extraction.families.{family_name} must be an object")
            continue
        label = f"source_extraction.families.{family_name}"
        status = str(family.get("status", ""))
        if status not in valid_statuses:
            failures.append(f"{label}.status must be one of {valid_statuses}: {status}")
        if family.get("outline_author") != "owner_manual_polygon":
            failures.append(f"{label}.outline_author must be owner_manual_polygon")
        if family.get("extraction_allowed") is True and status in ["SOURCE_MASTER_REJECTED_REGEN_REQUIRED", "SOURCE_MASTER_CANDIDATE_PENDING_PHOTOROOM", "OWNER_POLYGON_OUTLINE_PENDING", "OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA"]:
            failures.append(f"{label}.extraction_allowed must be false while source extraction is pending")
        _require_game_relative_file(game_root, family.get("source_sheet"), f"{label}.source_sheet", failures)
        asset_keys = family.get("asset_keys")
        if not isinstance(asset_keys, list) or not asset_keys or not all(isinstance(key, str) and key for key in asset_keys):
            failures.append(f"{label}.asset_keys must be a nonempty string list")
        if status == "SOURCE_MASTER_REJECTED_REGEN_REQUIRED":
            continue
        if status == "SOURCE_MASTER_CANDIDATE_PENDING_PHOTOROOM":
            _game_relative_path(game_root, family.get("alpha_sheet"), f"{label}.alpha_sheet", failures)
            _game_relative_path(game_root, family.get("editor_html"), f"{label}.editor_html", failures)
            continue
        if status == "OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA":
            failures.append(f"{label}.status OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA is invalid for production flow; create Photoroom alpha before owner cutting")
        alpha_sheet = family.get("alpha_sheet")
        _require_game_relative_file(game_root, alpha_sheet, f"{label}.alpha_sheet", failures)
        editor_sheet = family.get("editor_sheet")
        if isinstance(editor_sheet, str) and editor_sheet:
            _require_game_relative_file(game_root, editor_sheet, f"{label}.editor_sheet", failures)
            if editor_sheet != alpha_sheet:
                failures.append(f"{label}.editor_sheet must equal alpha_sheet; owner polygon editor must display the Photoroom alpha sheet")
        _require_game_relative_file(game_root, family.get("editor_html"), f"{label}.editor_html", failures)
        editor_path = _game_relative_path(game_root, family.get("editor_html"), f"{label}.editor_html", failures)
        if editor_path != None and editor_path.exists():
            editor_text = editor_path.read_text(encoding="utf-8")
            if status in ["OWNER_POLYGON_OUTLINE_PENDING", "OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA", "OWNER_POLYGON_OUTLINE_APPROVED", "EXTRACTION_QC_PASS", "SOURCE_ASSET_APPROVED"]:
                for token in ["Owner Polygon", "owner_manual_polygon", "No grid", "Download JSON"]:
                    if token not in editor_text:
                        failures.append(f"{label}.editor_html missing owner polygon editor token: {token}")
            else:
                for token in ["Owner Polygon source regen required", "BLOCKED", "regen required"]:
                    if token not in editor_text:
                        failures.append(f"{label}.editor_html missing blocked source regen token: {token}")

        outline_json_value = family.get("owner_outline_json")
        if not isinstance(outline_json_value, str) or not outline_json_value:
            failures.append(f"{label}.owner_outline_json must be a game-relative path")
            continue
        _game_relative_path(game_root, outline_json_value, f"{label}.owner_outline_json", failures)
        if status in ["OWNER_POLYGON_OUTLINE_PENDING", "OWNER_POLYGON_OUTLINE_APPROVED_PENDING_ALPHA"]:
            continue
        outline_path = _require_game_relative_file(game_root, outline_json_value, f"{label}.owner_outline_json", failures)
        if outline_path == None:
            continue
        _require_owner_polygon_outline_json(outline_path, asset_keys if isinstance(asset_keys, list) else [], label, failures)

def _game_relative_path(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    if not isinstance(value, str) or not value:
        failures.append(f"{label} must be a game-relative path")
        return None
    path = Path(value)
    if path.is_absolute():
        failures.append(f"{label} must not be an absolute path")
        return None
    resolved = (game_root / path).resolve()
    try:
        resolved.relative_to(game_root.resolve())
    except ValueError:
        failures.append(f"{label} points outside game root: {value}")
        return None
    return resolved

def _require_game_relative_file(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    resolved = _game_relative_path(game_root, value, label, failures)
    if resolved == None:
        return None
    if not resolved.exists():
        failures.append(f"{label} missing path: {value}")
        return None
    return resolved

def _require_owner_polygon_outline_json(path: Path, asset_keys: list[object], label: str, failures: list[str]) -> None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"{label}.owner_outline_json invalid JSON: {exc}")
        return
    if not isinstance(data, dict):
        failures.append(f"{label}.owner_outline_json must be an object")
        return
    if data.get("outline_author") != "owner_manual_polygon":
        failures.append(f"{label}.owner_outline_json outline_author must be owner_manual_polygon")
    assets = data.get("assets")
    if not isinstance(assets, dict):
        failures.append(f"{label}.owner_outline_json missing assets object")
        return
    for key in asset_keys:
        item = assets.get(str(key))
        if not isinstance(item, dict):
            failures.append(f"{label}.owner_outline_json missing asset: {key}")
            continue
        outline = item.get("outline")
        if not isinstance(outline, list) or len(outline) < 3:
            failures.append(f"{label}.owner_outline_json {key} outline must have at least 3 points")
        rect = item.get("computed_rect")
        if not isinstance(rect, dict):
            failures.append(f"{label}.owner_outline_json {key} missing computed_rect")


def _png_dimensions(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as handle:
            header = handle.read(24)
    except OSError:
        return None
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", header[16:24])


def _require_screenshot_capture_policy(contract: dict, texts: dict[str, str], failures: list[str]) -> dict:
    expected_screenshots = contract.get("expected_screenshots", {})
    policy = contract.get("screenshot_capture_policy")
    if not expected_screenshots and not isinstance(policy, dict):
        return {}
    if not isinstance(policy, dict):
        failures.append("screenshot_capture_policy required when expected_screenshots are declared")
        return {}

    merged = dict(DEFAULT_SCREENSHOT_CAPTURE_POLICY)
    merged.update(policy)

    screenshots_doc = texts.get("screenshots", "")
    approved_methods = merged.get("approved_methods")
    if not isinstance(approved_methods, list) or not approved_methods:
        failures.append("screenshot_capture_policy.approved_methods must be a non-empty list")
    else:
        for method in approved_methods:
            if not _contains_token(screenshots_doc, str(method)):
                failures.append(f"screenshot checklist missing approved capture method token: {method}")

    forbidden_methods = merged.get("forbidden_methods")
    if not isinstance(forbidden_methods, list) or not forbidden_methods:
        failures.append("screenshot_capture_policy.forbidden_methods must be a non-empty list")
    else:
        for method in forbidden_methods:
            if not _contains_token(screenshots_doc, str(method)):
                failures.append(f"screenshot checklist missing forbidden capture method token: {method}")

    for boolean_key in ["requires_visual_inspection", "requires_nonblank_pixel_audit"]:
        if merged.get(boolean_key) is not True:
            failures.append(f"screenshot_capture_policy.{boolean_key} must be true")

    for numeric_key in ["min_sampled_unique_colors", "min_luma_stddev", "min_luma_mean"]:
        try:
            value = float(merged.get(numeric_key))
        except (TypeError, ValueError):
            failures.append(f"screenshot_capture_policy.{numeric_key} must be numeric")
            continue
        if value <= 0.0:
            failures.append(f"screenshot_capture_policy.{numeric_key} must be positive")

    return merged


def _require_screenshot_dimensions(game_root: Path, contract: dict, capture_policy: dict, failures: list[str]) -> None:
    for rel_path, expected in contract.get("expected_screenshots", {}).items():
        path = game_root / str(rel_path)
        if not path.exists():
            failures.append(f"missing screenshot proof: {rel_path}")
            continue
        actual = _png_dimensions(path)
        expected_tuple = _screenshot_expected_size(expected, str(rel_path), failures)
        if expected_tuple == None:
            continue
        if actual != expected_tuple:
            failures.append(f"{rel_path} has dimensions {actual}, expected {expected_tuple}")
        if capture_policy.get("requires_nonblank_pixel_audit") is True:
            _require_screenshot_pixel_content(path, str(rel_path), capture_policy, failures)


def _screenshot_expected_size(expected: object, rel_path: str, failures: list[str]) -> tuple[int, int] | None:
    if isinstance(expected, list):
        return _size_pair(expected, f"expected_screenshots.{rel_path}", failures)
    if isinstance(expected, dict):
        return _size_pair(expected.get("size"), f"expected_screenshots.{rel_path}.size", failures)
    failures.append(f"expected_screenshots.{rel_path} must be [w, h] or an object with size")
    return None


def _require_screenshot_pixel_content(path: Path, rel_path: str, policy: dict, failures: list[str]) -> None:
    try:
        with Image.open(path) as image:
            sample = image.convert("RGBA").resize((64, 64), Image.Resampling.BILINEAR)
            raw = sample.tobytes()
            unique_colors = len({raw[index:index + 4] for index in range(0, len(raw), 4)})
            luma = sample.convert("L")
            stats = ImageStat.Stat(luma)
            mean_luma = float(stats.mean[0])
            stddev_luma = float(stats.stddev[0])
    except Exception as exc:
        failures.append(f"{rel_path} pixel audit failed: {exc}")
        return

    min_unique = int(policy.get("min_sampled_unique_colors", DEFAULT_SCREENSHOT_CAPTURE_POLICY["min_sampled_unique_colors"]))
    min_stddev = float(policy.get("min_luma_stddev", DEFAULT_SCREENSHOT_CAPTURE_POLICY["min_luma_stddev"]))
    min_mean = float(policy.get("min_luma_mean", DEFAULT_SCREENSHOT_CAPTURE_POLICY["min_luma_mean"]))
    if unique_colors < min_unique:
        failures.append(f"{rel_path} looks blank: sampled unique colors {unique_colors} below {min_unique}")
    if stddev_luma < min_stddev:
        failures.append(f"{rel_path} looks blank: luma stddev {stddev_luma:.2f} below {min_stddev:.2f}")
    if mean_luma < min_mean:
        failures.append(f"{rel_path} looks blank: mean luma {mean_luma:.2f} below {min_mean:.2f}")

def _require_image_quality_profile(game_root: Path, contract: dict, failures: list[str]) -> None:
    if not contract:
        return
    profile_config = contract.get("image_quality_profile")
    if not isinstance(profile_config, dict):
        failures.append("image_quality_profile required in art/UI gate contract")
        return

    profile_id = str(profile_config.get("profile", ""))
    profile = IMAGE_QUALITY_PROFILES.get(profile_id)
    if profile == None:
        failures.append(f"image_quality_profile.profile unknown: {profile_id}")
        return

    runtime_scale = _positive_int(
        profile_config.get("runtime_ui_source_scale"),
        "image_quality_profile.runtime_ui_source_scale",
        failures,
    )
    min_scale = int(profile["min_runtime_ui_source_scale"])
    if runtime_scale != None and runtime_scale < min_scale:
        failures.append(
            f"image_quality_profile.runtime_ui_source_scale {runtime_scale} below {profile_id} minimum {min_scale}"
        )

    reference_viewport = _size_pair(
        profile_config.get("ui_reference_viewport"),
        "image_quality_profile.ui_reference_viewport",
        failures,
    )
    if reference_viewport != None:
        _require_min_size(
            reference_viewport,
            tuple(profile["min_ui_reference_viewport"]),
            "image_quality_profile.ui_reference_viewport",
            failures,
        )

    editor_min = _size_pair(
        profile_config.get("min_editor_background_size"),
        "image_quality_profile.min_editor_background_size",
        failures,
    )
    if editor_min != None:
        _require_min_size(
            editor_min,
            tuple(profile["min_editor_background_size"]),
            "image_quality_profile.min_editor_background_size",
            failures,
        )

    manual = contract.get("manual_placement", {})
    if isinstance(manual, dict):
        surfaces = manual.get("surfaces", {})
        if isinstance(surfaces, dict):
            for surface_name, placement in surfaces.items():
                if not isinstance(placement, dict):
                    continue
                placement_min = _size_pair(
                    placement.get("min_background_size"),
                    f"manual placement {surface_name}.min_background_size",
                    failures,
                )
                if editor_min != None and placement_min != None:
                    _require_min_size(
                        placement_min,
                        editor_min,
                        f"manual placement {surface_name}.min_background_size",
                        failures,
                    )

    source_assets = profile_config.get("ui_source_assets")
    if not isinstance(source_assets, dict) or not source_assets:
        failures.append("image_quality_profile.ui_source_assets must list runtime UI assets to validate")
        return
    for asset_key, spec in source_assets.items():
        _require_ui_source_asset_quality(
            game_root,
            str(asset_key),
            spec,
            runtime_scale,
            min_scale,
            failures,
        )
    gameplay_assets = profile_config.get("gameplay_source_assets", {})
    if gameplay_assets != {}:
        if not isinstance(gameplay_assets, dict):
            failures.append("image_quality_profile.gameplay_source_assets must be an object")
        else:
            for asset_key, spec in gameplay_assets.items():
                _require_alpha_source_asset_quality(
                    game_root,
                    "gameplay_source_assets",
                    str(asset_key),
                    spec,
                    runtime_scale,
                    min_scale,
                    failures,
                )
    alpha_assets = profile_config.get("alpha_source_assets", {})
    if alpha_assets != {}:
        if not isinstance(alpha_assets, dict):
            failures.append("image_quality_profile.alpha_source_assets must be an object")
        else:
            for asset_key, spec in alpha_assets.items():
                _require_alpha_source_asset_quality(
                    game_root,
                    "alpha_source_assets",
                    str(asset_key),
                    spec,
                    runtime_scale,
                    min_scale,
                    failures,
                )

def _require_ui_source_asset_quality(
    game_root: Path,
    asset_key: str,
    spec: object,
    runtime_scale: int | None,
    min_scale: int,
    failures: list[str],
) -> None:
    if not isinstance(spec, dict):
        failures.append(f"image_quality_profile.ui_source_assets.{asset_key} must be an object")
        return
    if runtime_scale == None:
        return

    size_policy = str(spec.get("size_policy", ""))
    if size_policy not in ["exact", "minimum"]:
        failures.append(f"image_quality_profile.ui_source_assets.{asset_key}.size_policy must be exact or minimum")
        return

    resize_mode = str(spec.get("resize_mode", ""))
    if resize_mode not in UI_SOURCE_RESIZE_MODES:
        failures.append(
            f"image_quality_profile.ui_source_assets.{asset_key}.resize_mode must be one of {sorted(UI_SOURCE_RESIZE_MODES)}"
        )

    source_scale = _positive_int(
        spec.get("source_scale", runtime_scale),
        f"image_quality_profile.ui_source_assets.{asset_key}.source_scale",
        failures,
    )
    if source_scale == None:
        return
    if source_scale < min_scale:
        failures.append(
            f"image_quality_profile.ui_source_assets.{asset_key}.source_scale {source_scale} below profile minimum {min_scale}"
        )
    if source_scale < runtime_scale:
        failures.append(
            f"image_quality_profile.ui_source_assets.{asset_key}.source_scale {source_scale} below runtime scale {runtime_scale}"
        )

    owner_size = _asset_owner_size(spec, asset_key, failures)
    path = _game_relative_png_path(
        game_root,
        spec.get("path"),
        f"image_quality_profile.ui_source_assets.{asset_key}.path",
        failures,
    )
    if owner_size == None or path == None:
        return
    actual = _png_dimensions(path)
    if actual == None:
        failures.append(f"image_quality_profile.ui_source_assets.{asset_key}.path is not a PNG: {spec.get('path')}")
        return
    expected = (owner_size[0] * source_scale, owner_size[1] * source_scale)
    if size_policy == "exact":
        if actual != expected:
            failures.append(
                f"image_quality_profile.ui_source_assets.{asset_key} PNG {actual[0]}x{actual[1]} must equal owner {owner_size[0]}x{owner_size[1]} * scale {source_scale} = {expected[0]}x{expected[1]}"
            )
    elif actual[0] < expected[0] or actual[1] < expected[1]:
        failures.append(
            f"image_quality_profile.ui_source_assets.{asset_key} PNG {actual[0]}x{actual[1]} below owner {owner_size[0]}x{owner_size[1]} * scale {source_scale} = {expected[0]}x{expected[1]}"
        )

def _asset_owner_size(spec: dict, asset_key: str, failures: list[str]) -> tuple[int, int] | None:
    owner_size = spec.get("owner_size")
    if isinstance(owner_size, list) and len(owner_size) == 2:
        return _size_pair(owner_size, f"image_quality_profile.ui_source_assets.{asset_key}.owner_size", failures)
    owner_rect = spec.get("owner_rect")
    if isinstance(owner_rect, list) and len(owner_rect) == 4:
        rect = _rect_from_value(owner_rect, f"image_quality_profile.ui_source_assets.{asset_key}.owner_rect", failures)
        if rect != None:
            return (int(round(rect[2])), int(round(rect[3])))
    failures.append(f"image_quality_profile.ui_source_assets.{asset_key} must declare owner_size [w, h] or owner_rect [x, y, w, h]")
    return None

def _require_alpha_source_asset_quality(
    game_root: Path,
    group_name: str,
    asset_key: str,
    spec: object,
    runtime_scale: int | None,
    min_scale: int,
    failures: list[str],
) -> None:
    if not isinstance(spec, dict):
        failures.append(f"image_quality_profile.{group_name}.{asset_key} must be an object")
        return
    if runtime_scale == None:
        return

    source_scale = _positive_int(
        spec.get("source_scale", runtime_scale),
        f"image_quality_profile.{group_name}.{asset_key}.source_scale",
        failures,
    )
    if source_scale == None:
        return
    if source_scale < min_scale:
        failures.append(
            f"image_quality_profile.{group_name}.{asset_key}.source_scale {source_scale} below profile minimum {min_scale}"
        )

    visual_size = _size_pair(
        spec.get("visual_size"),
        f"image_quality_profile.{group_name}.{asset_key}.visual_size",
        failures,
    )
    path = _game_relative_png_path(
        game_root,
        spec.get("path"),
        f"image_quality_profile.{group_name}.{asset_key}.path",
        failures,
    )
    if visual_size == None or path == None:
        return
    actual = _png_dimensions(path)
    if actual == None:
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.path is not a PNG: {spec.get('path')}")
        return
    expected = (visual_size[0] * source_scale, visual_size[1] * source_scale)
    if actual[0] < expected[0] or actual[1] < expected[1]:
        failures.append(
            f"image_quality_profile.{group_name}.{asset_key} PNG {actual[0]}x{actual[1]} below visual {visual_size[0]}x{visual_size[1]} * scale {source_scale} = {expected[0]}x{expected[1]}"
        )
    if spec.get("alpha_required", True) is True:
        _require_alpha_asset_qc(game_root, group_name, asset_key, spec, path, failures)

def _require_alpha_asset_qc(game_root: Path, group_name: str, asset_key: str, spec: dict, path: Path, failures: list[str]) -> None:
    qc_value = spec.get("qc")
    if not isinstance(qc_value, str) or not qc_value:
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc required when alpha_required is true")
        return
    qc_path = _game_relative_path(game_root, qc_value, f"image_quality_profile.{group_name}.{asset_key}.qc", failures)
    if qc_path == None:
        return
    if not qc_path.exists():
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc missing path: {qc_value}")
        return
    try:
        qc = json.loads(qc_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc invalid JSON: {exc}")
        return
    assets = qc.get("assets")
    if not isinstance(assets, dict):
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc missing assets object")
        return
    row = assets.get(asset_key)
    if not isinstance(row, dict):
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc missing asset row")
        return
    if row.get("alpha_ok") is not True:
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc alpha_ok must be true")
    if row.get("edge_ok") is not True:
        failures.append(f"image_quality_profile.{group_name}.{asset_key}.qc edge_ok must be true")
    expected_output = str(row.get("output", "")).replace("\\", "/")
    actual_output = str(path.resolve().relative_to(game_root.resolve())).replace("\\", "/")
    if expected_output != actual_output:
        failures.append(
            f"image_quality_profile.{group_name}.{asset_key}.qc output {expected_output} must match path {actual_output}"
        )

def _game_relative_png_path(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    if not isinstance(value, str) or not value:
        failures.append(f"{label} must be a game-relative PNG path")
        return None
    if value.startswith("res://"):
        value = value.replace("res://", "", 1)
    path = Path(value)
    if path.is_absolute():
        failures.append(f"{label} must not be an absolute path")
        return None
    resolved = game_root / path
    if not resolved.exists():
        failures.append(f"{label} missing path: {value}")
        return None
    return resolved


def _game_relative_markdown_path(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    if not isinstance(value, str) or not value:
        failures.append(f"{label} must be a game-relative markdown path")
        return None
    path = Path(value)
    if path.is_absolute():
        failures.append(f"{label} must not be an absolute path")
        return None
    if path.suffix.lower() != ".md":
        failures.append(f"{label} must point at a markdown file")
        return None
    resolved = game_root / path
    if not resolved.exists():
        failures.append(f"{label} missing path: {value}")
        return None
    return resolved


def _positive_int(value: object, label: str, failures: list[str]) -> int | None:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        failures.append(f"{label} must be an integer")
        return None
    if parsed <= 0:
        failures.append(f"{label} must be positive")
        return None
    return parsed

def _size_pair(value: object, label: str, failures: list[str]) -> tuple[int, int] | None:
    if not isinstance(value, list) or len(value) != 2:
        failures.append(f"{label} must be [w, h]")
        return None
    try:
        width = int(value[0])
        height = int(value[1])
    except (TypeError, ValueError):
        failures.append(f"{label} values must be integers")
        return None
    if width <= 0 or height <= 0:
        failures.append(f"{label} must be positive")
        return None
    return (width, height)

def _require_min_size(actual: tuple[int, int], minimum: tuple[int, int], label: str, failures: list[str]) -> None:
    if actual[0] < minimum[0] or actual[1] < minimum[1]:
        failures.append(f"{label} {actual[0]}x{actual[1]} below minimum {minimum[0]}x{minimum[1]}")

def _rect_from_value(value: object, label: str, failures: list[str]) -> tuple[float, float, float, float] | None:
    if not isinstance(value, list) or len(value) != 4:
        failures.append(f"visual composition rule {label} must be [x, y, w, h]")
        return None
    try:
        x, y, width, height = (float(value[0]), float(value[1]), float(value[2]), float(value[3]))
    except (TypeError, ValueError):
        failures.append(f"visual composition rule {label} rect values must be numeric")
        return None
    if width <= 0.0 or height <= 0.0:
        failures.append(f"visual composition rule {label} rect must have positive size")
        return None
    return (x, y, width, height)

def _rects_overlap(a: tuple[float, float, float, float], b: tuple[float, float, float, float], padding: float = 0.0) -> bool:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return not (
        ax + aw + padding <= bx
        or bx + bw + padding <= ax
        or ay + ah + padding <= by
        or by + bh + padding <= ay
    )

def _rect_inside(inner: tuple[float, float, float, float], outer: tuple[float, float, float, float], padding: float = 0.0) -> bool:
    ix, iy, iw, ih = inner
    ox, oy, ow, oh = outer
    return (
        ix >= ox + padding
        and iy >= oy + padding
        and ix + iw <= ox + ow - padding
        and iy + ih <= oy + oh - padding
    )

def _runtime_fit_screen_names(rows: dict[str, list[str]], contract: dict) -> set[str]:
    names: set[str] = set()
    for screen, cells in rows.items():
        joined = " | ".join(cells)
        if "RUNTIME_FIT_PASS" in joined or "OWNER_APPROVED" in joined:
            names.add(str(screen))
    for screen, tokens in contract.get("runtime_fit_rows", {}).items():
        if any(str(token) == "RUNTIME_FIT_PASS" for token in tokens):
            names.add(str(screen))
    return names

def _require_visual_composition_rules(contract: dict, screenshot_rows: dict[str, list[str]], failures: list[str]) -> None:
    rules = contract.get("visual_composition_rules", {})
    runtime_fit_screens = _runtime_fit_screen_names(screenshot_rows, contract)
    if not rules:
        if runtime_fit_screens:
            failures.append("visual_composition_rules required when screenshot rows claim RUNTIME_FIT_PASS or OWNER_APPROVED")
        return
    surfaces = rules.get("surfaces", {})
    if not isinstance(surfaces, dict):
        failures.append("visual_composition_rules.surfaces must be an object")
        return
    for screen_name in sorted(runtime_fit_screens):
        if screen_name not in surfaces:
            failures.append(f"visual composition rule missing for runtime-fit screen: {screen_name}")
    for surface_name, surface_rule in surfaces.items():
        if not isinstance(surface_rule, dict):
            failures.append(f"visual composition rule {surface_name} must be an object")
            continue
        viewport_size = surface_rule.get("viewport_size")
        if not isinstance(viewport_size, list) or len(viewport_size) != 2:
            failures.append(f"visual composition rule {surface_name} missing viewport_size [w, h]")
            continue
        try:
            viewport_width = float(viewport_size[0])
            viewport_height = float(viewport_size[1])
        except (TypeError, ValueError):
            failures.append(f"visual composition rule {surface_name} viewport_size values must be numeric")
            continue
        if viewport_width <= 0.0 or viewport_height <= 0.0:
            failures.append(f"visual composition rule {surface_name} viewport_size must be positive")
            continue

        surface_rect = _rect_from_value(surface_rule.get("surface_rect"), f"{surface_name}.surface_rect", failures)
        if surface_rect == None:
            continue
        max_ratio = surface_rule.get("max_surface_viewport_area_ratio")
        if max_ratio != None:
            try:
                max_ratio_value = float(max_ratio)
            except (TypeError, ValueError):
                failures.append(f"visual composition rule {surface_name}.max_surface_viewport_area_ratio must be numeric")
                max_ratio_value = -1.0
            if max_ratio_value <= 0.0 or max_ratio_value > 1.0:
                failures.append(f"visual composition rule {surface_name}.max_surface_viewport_area_ratio must be 0..1")
            else:
                _, _, surface_width, surface_height = surface_rect
                ratio = (surface_width * surface_height) / (viewport_width * viewport_height)
                if ratio > max_ratio_value:
                    failures.append(
                        f"visual composition rule {surface_name} surface area ratio {ratio:.3f} exceeds {max_ratio_value:.3f}"
                    )

        text_safe_zones = _parse_named_rects(surface_rule.get("text_safe_zones", {}), f"{surface_name}.text_safe_zones", failures)
        art_safe_zones = _parse_named_rects(surface_rule.get("art_safe_zones", {}), f"{surface_name}.art_safe_zones", failures)
        slot_rects = _parse_named_rects(surface_rule.get("slot_rects", {}), f"{surface_name}.slot_rects", failures)
        ornament_rects = _parse_named_rects(surface_rule.get("ornament_exclusion_zones", {}), f"{surface_name}.ornament_exclusion_zones", failures)
        safe_padding = _safe_padding(surface_rule, surface_name, failures)
        _require_rect_semantic_boundary(surface_name, surface_rule, failures)

        for zone_name, rect in text_safe_zones.items():
            if not _rect_inside(rect, surface_rect, 0.0):
                failures.append(f"visual composition rule {surface_name}.{zone_name} text_safe_zones rect outside surface_rect")
            art_rect = art_safe_zones.get(zone_name)
            if art_rect == None:
                failures.append(f"visual composition rule {surface_name}.{zone_name} text_safe_zones missing matching art_safe_zones rect")
            elif not _rect_inside(rect, art_rect, 0.0):
                failures.append(f"visual composition rule {surface_name}.{zone_name} text_safe_zones outside matching art_safe_zones rect")
        for zone_name, rect in art_safe_zones.items():
            if not _rect_inside(rect, surface_rect, 0.0):
                failures.append(f"visual composition rule {surface_name}.{zone_name} art_safe_zones rect outside surface_rect")
        for slot_name, rect in slot_rects.items():
            if not _rect_inside(rect, surface_rect, 0.0):
                failures.append(f"visual composition rule {surface_name}.{slot_name} slot_rects rect outside surface_rect")
        for zone_name, rect in ornament_rects.items():
            if not _rect_inside(rect, surface_rect, 0.0):
                failures.append(f"visual composition rule {surface_name}.{zone_name} ornament_exclusion_zones rect outside surface_rect")
            for text_name, text_rect in text_safe_zones.items():
                if _rects_overlap(rect, text_rect, safe_padding):
                    failures.append(
                        f"visual composition rule {surface_name} ornament_exclusion_zones.{zone_name} overlaps text_safe_zones.{text_name}"
                    )
            for art_name, art_rect in art_safe_zones.items():
                if _rects_overlap(rect, art_rect, safe_padding):
                    failures.append(
                        f"visual composition rule {surface_name} ornament_exclusion_zones.{zone_name} overlaps art_safe_zones.{art_name}"
                    )

        for slot_name, slot_rect in slot_rects.items():
            for text_name, text_rect in text_safe_zones.items():
                if slot_name == text_name:
                    continue
                if _rects_overlap(slot_rect, text_rect, safe_padding):
                    failures.append(
                        f"visual composition rule {surface_name} slot_rects.{slot_name} overlaps text_safe_zones.{text_name}"
                    )

def _require_rect_semantic_boundary(surface_name: str, surface_rule: dict, failures: list[str]) -> None:
    boundary = surface_rule.get("rect_semantic_boundary")
    if boundary == None:
        return
    if not isinstance(boundary, dict):
        failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary must be an object")
        return
    if boundary.get("required") is not True:
        return
    roles = boundary.get("roles")
    if not isinstance(roles, dict):
        failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary.roles must be an object")
        return
    for required_role in ["control_owner_rect", "visual_shell_rect"]:
        if required_role not in roles:
            failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary missing role {required_role}")
    for role_name, role_rule in roles.items():
        if not isinstance(role_rule, dict):
            failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary.{role_name} must be an object")
            continue
        coordinate_space = str(role_rule.get("coordinate_space", ""))
        source = str(role_rule.get("source", ""))
        if coordinate_space == "":
            failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary.{role_name} missing coordinate_space")
        if source == "":
            failures.append(f"visual composition rule {surface_name}.rect_semantic_boundary.{role_name} missing source")

def _require_manual_placement_rules(game_root: Path, contract: dict, screenshot_rows: dict[str, list[str]], failures: list[str]) -> None:
    runtime_fit_screens = _runtime_fit_screen_names(screenshot_rows, contract)
    manual = contract.get("manual_placement")
    if not runtime_fit_screens and not isinstance(manual, dict):
        return
    if not isinstance(manual, dict):
        failures.append("manual_placement required when screenshot rows claim RUNTIME_FIT_PASS or OWNER_APPROVED")
        return
    expected_seed_policy = {
        "draft_seed_status": "DRAFT_SEED_ONLY",
        "seed_regions_are_non_exportable": True,
        "owner_final_only": True,
        "copy_to_runtime_requires": "OWNER_PLACEMENT_APPROVED",
    }
    for key, expected_value in expected_seed_policy.items():
        if manual.get(key) != expected_value:
            failures.append(f"manual_placement.{key} must be {expected_value}")
    manual_required = manual.get("required") is True
    if runtime_fit_screens and not manual_required:
        failures.append("manual_placement.required must be true for runtime-fit art/UI surfaces")

    surfaces = manual.get("surfaces")
    if not isinstance(surfaces, dict):
        failures.append("manual_placement.surfaces must be an object")
        return

    visual_surfaces = contract.get("visual_composition_rules", {}).get("surfaces", {})
    if not isinstance(visual_surfaces, dict):
        visual_surfaces = {}

    screens_to_validate = set(runtime_fit_screens)
    if manual_required:
        screens_to_validate.update(str(name) for name in surfaces.keys())

    for screen_name in sorted(screens_to_validate):
        placement = surfaces.get(screen_name)
        if not isinstance(placement, dict):
            failures.append(f"manual placement editor missing for runtime-fit screen: {screen_name}")
            continue

        status = str(placement.get("status", ""))
        if status not in ["READY_FOR_OWNER_ADJUSTMENT", "OWNER_PLACEMENT_APPROVED"]:
            failures.append(
                f"manual placement {screen_name}.status must be READY_FOR_OWNER_ADJUSTMENT or OWNER_PLACEMENT_APPROVED"
            )
        row_text = " | ".join(screenshot_rows.get(screen_name, []))
        if ("RUNTIME_FIT_PASS" in row_text or "OWNER_APPROVED" in row_text or screen_name in runtime_fit_screens) and status != "OWNER_PLACEMENT_APPROVED":
            failures.append(
                f"manual placement {screen_name} must be OWNER_PLACEMENT_APPROVED before RUNTIME_FIT_PASS or OWNER_APPROVED"
            )
        if "OWNER_APPROVED" in row_text and status != "OWNER_PLACEMENT_APPROVED":
            failures.append(f"manual placement {screen_name} must be OWNER_PLACEMENT_APPROVED before OWNER_APPROVED")

        applies_to = placement.get("applies_to")
        if not isinstance(applies_to, list) or not applies_to:
            failures.append(f"manual placement {screen_name}.applies_to must list the editable text/icon slots")
            applies_to_names: set[str] = set()
        else:
            applies_to_names = {str(name) for name in applies_to}

        visual_rule = visual_surfaces.get(screen_name, {})
        if isinstance(visual_rule, dict):
            expected_names = set()
            for group_name in ["text_safe_zones", "slot_rects"]:
                group = visual_rule.get(group_name, {})
                if isinstance(group, dict):
                    expected_names.update(str(name) for name in group.keys())
            for name in sorted(expected_names - applies_to_names):
                failures.append(f"manual placement {screen_name}.applies_to missing visual slot: {name}")

        editor_config = _load_manual_placement_json(
            game_root,
            placement.get("editor_config"),
            f"{screen_name}.editor_config",
            failures,
        )
        editor_html = _require_manual_placement_file(
            game_root,
            placement.get("editor_html"),
            f"{screen_name}.editor_html",
            failures,
        )
        export_json = _load_manual_placement_json(
            game_root,
            placement.get("export_json"),
            f"{screen_name}.export_json",
            failures,
        )

        _require_manual_editor_regions(game_root, screen_name, applies_to_names, editor_config, "editor_config", failures)
        _require_manual_editor_regions(game_root, screen_name, applies_to_names, export_json, "export_json", failures)
        _require_manual_layer_contract(screen_name, editor_config, failures)
        _require_repeated_region_group_policy(screen_name, editor_config, failures)
        _require_manual_runtime_surface_lineage(game_root, screen_name, editor_config, failures)
        _require_manual_editor_navigation(screen_name, editor_html, editor_config, failures)
        _require_manual_stage_payload_preview(screen_name, editor_config, editor_html, failures)
        _require_manual_background_quality(screen_name, placement, editor_config, failures)
        _require_manual_clean_background_audit(game_root, screen_name, placement, editor_config, failures)
        if isinstance(export_json, dict):
            export_status = str(export_json.get("status", ""))
            if export_status != status:
                failures.append(
                    f"manual placement {screen_name}.export_json status {export_status} does not match contract status {status}"
                )

def _require_no_agent_drawn_owner_proof(game_root: Path, contract: dict, failures: list[str]) -> None:
    policy = contract.get("owner_proof_policy", {})
    if "art_process" in contract and "owner_proof_policy" not in contract:
        failures.append("owner_proof_policy missing from art UI gate contract")
        policy = {}
    elif "art_process" in contract and not isinstance(policy, dict):
        failures.append("owner_proof_policy must be an object")
        policy = {}
    forbidden_dirs = list(DEFAULT_AGENT_DRAWN_OWNER_PROOF_DIRS)
    forbidden_globs = list(DEFAULT_AGENT_DRAWN_OWNER_PROOF_GLOBS)
    if isinstance(policy, dict):
        extra_dirs = policy.get("forbidden_agent_drawn_dirs", [])
        if isinstance(extra_dirs, list):
            forbidden_dirs.extend(str(value) for value in extra_dirs if str(value))
        extra_globs = policy.get("forbidden_agent_drawn_globs", [])
        if isinstance(extra_globs, list):
            forbidden_globs.extend(str(value) for value in extra_globs if str(value))

    resolved_root = game_root.resolve()
    for rel_dir in sorted(set(forbidden_dirs)):
        path = (resolved_root / rel_dir).resolve()
        try:
            path.relative_to(resolved_root)
        except ValueError:
            failures.append(f"owner_proof_policy forbidden dir escapes game root: {rel_dir}")
            continue
        if path.exists():
            failures.append(
                f"agent-drawn owner proof directory is forbidden; use real editor/export evidence instead: {rel_dir}"
            )

    for pattern in sorted(set(forbidden_globs)):
        if Path(pattern).is_absolute():
            failures.append(f"owner_proof_policy forbidden glob must be game-relative: {pattern}")
            continue
        matches = sorted(resolved_root.glob(pattern))
        for match in matches:
            try:
                rel = match.resolve().relative_to(resolved_root)
            except ValueError:
                failures.append(f"owner_proof_policy forbidden glob escapes game root: {pattern}")
                continue
            failures.append(
                f"agent-drawn owner proof artifact is forbidden; use real editor/export evidence instead: {rel.as_posix()}"
            )
def _require_manual_editor_regions(
    game_root: Path,
    screen_name: str,
    applies_to_names: set[str],
    data: dict | None,
    label: str,
    failures: list[str],
) -> None:
    if data == None:
        return
    regions = _manual_region_coverage(data, label == "export_json")
    if not isinstance(regions, dict):
        failures.append(f"manual placement {screen_name}.{label} missing regions object")
        return
    for name in sorted(applies_to_names):
        if name not in regions:
            failures.append(f"manual placement {screen_name}.{label} missing region: {name}")
            continue
        region = regions.get(name)
        if not isinstance(region, dict):
            failures.append(f"manual placement {screen_name}.{label} region is not an object: {name}")
            continue
        slot_kind = region.get("slot_kind")
        if slot_kind not in ["text", "image", "icon", "control"]:
            failures.append(
                f"manual placement {screen_name}.{label} region {name} missing slot_kind text/image/icon/control"
            )
        sample_text = region.get("sample_text")
        if not isinstance(sample_text, str) or not sample_text.strip():
            failures.append(f"manual placement {screen_name}.{label} region {name} missing sample_text")
        if slot_kind in ["image", "icon"]:
            _require_manual_sample_asset(
                game_root,
                data,
                region.get("sample_asset"),
                f"manual placement {screen_name}.{label} region {name}.sample_asset",
                failures,
            )

def _manual_region_coverage(data: dict, require_derived_exports: bool) -> dict:
    coverage = {}
    regions = data.get("regions")
    if isinstance(regions, dict):
        for name, region in regions.items():
            if isinstance(region, dict):
                coverage[str(name)] = region
    derived_regions = data.get("derived_regions")
    if isinstance(derived_regions, dict):
        for name, region in derived_regions.items():
            if isinstance(region, dict):
                coverage[str(name)] = region
    repeated_groups = data.get("repeated_region_groups")
    if isinstance(repeated_groups, dict) and not require_derived_exports:
        for group in repeated_groups.values():
            if not isinstance(group, dict):
                continue
            templates = group.get("templates", {})
            instances = group.get("instances", [])
            if not isinstance(templates, dict) or not isinstance(instances, list):
                continue
            for instance in instances:
                if not isinstance(instance, dict):
                    continue
                exports = instance.get("exports", {})
                sample_text = instance.get("sample_text", {})
                sample_asset = instance.get("sample_asset", {})
                if not isinstance(exports, dict):
                    continue
                if not isinstance(sample_text, dict):
                    sample_text = {}
                if not isinstance(sample_asset, dict):
                    sample_asset = {}
                for role, template_name in templates.items():
                    export_name = exports.get(role)
                    template_region = coverage.get(str(template_name))
                    if not export_name or not isinstance(template_region, dict):
                        continue
                    derived = dict(template_region)
                    derived["sample_text"] = sample_text.get(role, derived.get("sample_text", ""))
                    derived["sample_asset"] = sample_asset.get(role, derived.get("sample_asset", ""))
                    coverage[str(export_name)] = derived
    return coverage

def _require_repeated_region_group_policy(screen_name: str, editor_config: dict | None, failures: list[str]) -> None:
    if editor_config == None:
        return
    regions = editor_config.get("regions")
    if not isinstance(regions, dict):
        return
    repeated_groups = editor_config.get("repeated_region_groups", {})
    if repeated_groups != {} and not isinstance(repeated_groups, dict):
        failures.append(f"manual placement {screen_name}.repeated_region_groups must be an object")
        repeated_groups = {}

    grouped_exports = _validate_repeated_region_groups(screen_name, regions, repeated_groups, failures)
    indexed_groups: dict[str, list[str]] = {}
    for region_name in regions.keys():
        signature = _indexed_region_signature(str(region_name))
        if signature == "":
            continue
        indexed_groups.setdefault(signature, []).append(str(region_name))
    for signature, names in sorted(indexed_groups.items()):
        if len(names) < 2:
            continue
        missing = [name for name in names if name not in grouped_exports]
        if missing:
            failures.append(
                "manual placement %s has repeated indexed regions %s without repeated_region_groups; "
                "use one canonical template and derive concrete slots"
                % (screen_name, ", ".join(sorted(names)))
            )

def _validate_repeated_region_groups(
    screen_name: str,
    regions: dict,
    repeated_groups: object,
    failures: list[str],
) -> set[str]:
    grouped_exports: set[str] = set()
    if not isinstance(repeated_groups, dict):
        return grouped_exports
    for group_name, group in repeated_groups.items():
        if not isinstance(group, dict):
            failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name} must be an object")
            continue
        if group.get("rule") != "drag_once_apply_to_all_instances":
            failures.append(
                f"manual placement {screen_name}.repeated_region_groups.{group_name}.rule must be drag_once_apply_to_all_instances"
            )
        templates = group.get("templates")
        if not isinstance(templates, dict) or not templates:
            failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name}.templates must be a nonempty object")
            continue
        for role, template_name in templates.items():
            if not isinstance(template_name, str) or template_name not in regions:
                failures.append(
                    f"manual placement {screen_name}.repeated_region_groups.{group_name}.templates.{role} missing editable template region: {template_name}"
                )
        instances = group.get("instances")
        if not isinstance(instances, list) or len(instances) < 2:
            failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances must list at least 2 derived instances")
            continue
        for index, instance in enumerate(instances):
            if not isinstance(instance, dict):
                failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances[{index}] must be an object")
                continue
            offset = instance.get("offset")
            if not isinstance(offset, list) or len(offset) != 2:
                failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances[{index}].offset must be [x, y]")
            else:
                try:
                    float(offset[0])
                    float(offset[1])
                except (TypeError, ValueError):
                    failures.append(
                        f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances[{index}].offset values must be numeric"
                    )
            exports = instance.get("exports")
            if not isinstance(exports, dict):
                failures.append(f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances[{index}].exports must be an object")
                continue
            for role in templates.keys():
                export_name = exports.get(role)
                if not isinstance(export_name, str) or not export_name:
                    failures.append(
                        f"manual placement {screen_name}.repeated_region_groups.{group_name}.instances[{index}].exports.{role} missing concrete slot id"
                    )
                    continue
                grouped_exports.add(export_name)
    return grouped_exports

def _require_manual_runtime_surface_lineage(
    game_root: Path,
    screen_name: str,
    editor_config: dict | None,
    failures: list[str],
) -> None:
    if editor_config == None:
        return
    surface_asset_keys = editor_config.get("surface_asset_keys")
    if not isinstance(surface_asset_keys, list) or not surface_asset_keys:
        failures.append(f"manual placement {screen_name}.editor_config surface_asset_keys must list unique runtime shell asset keys")
        surface_asset_keys = []
    normalized_keys = [str(key) for key in surface_asset_keys if isinstance(key, str) and str(key)]
    if len(normalized_keys) != len(surface_asset_keys):
        failures.append(f"manual placement {screen_name}.editor_config surface_asset_keys values must be nonempty strings")
    if len(normalized_keys) != len(set(normalized_keys)):
        failures.append(f"manual placement {screen_name}.editor_config surface_asset_keys must not repeat keys")

    runtime_asset_paths = editor_config.get("runtime_asset_paths")
    if not isinstance(runtime_asset_paths, dict) or not runtime_asset_paths:
        failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths must map each surface_asset_key")
        runtime_asset_paths = {}
    for key in normalized_keys:
        if key not in runtime_asset_paths:
            failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths missing key: {key}")
            continue
        _require_manual_runtime_asset_path(game_root, screen_name, editor_config, key, runtime_asset_paths.get(key), failures)
    for key in runtime_asset_paths.keys():
        if str(key) not in normalized_keys:
            failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths has undeclared key: {key}")
    _require_manual_clean_and_placeable_asset_sets(screen_name, editor_config, set(normalized_keys), runtime_asset_paths, failures)

    if editor_config.get("background_runtime_basis") != "clean_composite_from_surface_asset_keys":
        failures.append(
            f"manual placement {screen_name}.editor_config background_runtime_basis must be clean_composite_from_surface_asset_keys"
        )
    _require_manual_shell_samples_match_surface_lineage(game_root, screen_name, editor_config, runtime_asset_paths, failures)

def _require_manual_clean_and_placeable_asset_sets(
    screen_name: str,
    editor_config: dict,
    surface_keys: set[str],
    runtime_asset_paths: dict,
    failures: list[str],
) -> None:
    clean_keys = editor_config.get("clean_background_asset_keys")
    placeable_keys = editor_config.get("placeable_surface_asset_keys")
    if clean_keys == None and placeable_keys == None:
        return
    if not isinstance(clean_keys, list) or not clean_keys:
        failures.append(f"manual placement {screen_name}.editor_config clean_background_asset_keys must list baked clean background keys")
        clean_set: set[str] = set()
    else:
        clean_set = {str(key) for key in clean_keys if isinstance(key, str) and str(key)}
        if len(clean_set) != len(clean_keys):
            failures.append(f"manual placement {screen_name}.editor_config clean_background_asset_keys values must be nonempty strings")
    if not isinstance(placeable_keys, list):
        failures.append(f"manual placement {screen_name}.editor_config placeable_surface_asset_keys must be a list")
        placeable_set: set[str] = set()
    else:
        placeable_set = {str(key) for key in placeable_keys if isinstance(key, str) and str(key)}
        if len(placeable_set) != len(placeable_keys):
            failures.append(f"manual placement {screen_name}.editor_config placeable_surface_asset_keys values must be nonempty strings")
    for key in sorted((clean_set | placeable_set) - surface_keys):
        failures.append(f"manual placement {screen_name}.editor_config clean/placeable asset key not declared in surface_asset_keys: {key}")
    for key in sorted(clean_set | placeable_set):
        if key not in runtime_asset_paths:
            failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths missing clean/placeable asset key: {key}")
    for key in sorted(clean_set & placeable_set):
        failures.append(f"manual placement {screen_name}.editor_config asset key cannot be both clean-background and placeable: {key}")

def _require_manual_runtime_asset_path(
    game_root: Path,
    screen_name: str,
    editor_config: dict,
    key: str,
    value: object,
    failures: list[str],
) -> None:
    if not isinstance(value, str) or not value:
        failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths.{key} must be a nonempty path")
        return
    resolved = _resolve_manual_editor_path(game_root, editor_config, value)
    if resolved == None:
        failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths.{key} must stay inside game root: {value}")
        return
    if not resolved.exists():
        failures.append(f"manual placement {screen_name}.editor_config runtime_asset_paths.{key} missing file: {value}")

def _require_manual_shell_samples_match_surface_lineage(
    game_root: Path,
    screen_name: str,
    editor_config: dict,
    runtime_asset_paths: dict,
    failures: list[str],
) -> None:
    regions = editor_config.get("regions", {})
    if not isinstance(regions, dict) or not isinstance(runtime_asset_paths, dict):
        return
    declared_paths = {
        _resolve_manual_editor_path(game_root, editor_config, value)
        for value in runtime_asset_paths.values()
        if isinstance(value, str) and value
    }
    declared_paths.discard(None)
    for region_name, region in regions.items():
        if not isinstance(region, dict) or region.get("slot_kind") != "shell":
            continue
        sample_asset = region.get("sample_asset")
        if not isinstance(sample_asset, str) or not sample_asset:
            failures.append(f"manual placement {screen_name}.editor_config shell region {region_name} missing sample_asset")
            continue
        sample_path = _resolve_manual_editor_path(game_root, editor_config, sample_asset)
        if sample_path not in declared_paths:
            failures.append(
                f"manual placement {screen_name}.editor_config shell region {region_name}.sample_asset must match runtime_asset_paths"
            )

def _resolve_manual_editor_path(game_root: Path, editor_config: dict, value: str) -> Path | None:
    raw = value.replace("res://", "")
    path = Path(raw)
    if path.is_absolute():
        return None
    source_path_value = editor_config.get("__source_path")
    if isinstance(source_path_value, str) and source_path_value:
        resolved = (Path(source_path_value).parent / path).resolve()
    else:
        resolved = (game_root / path).resolve()
    try:
        resolved.relative_to(game_root.resolve())
    except ValueError:
        return None
    return resolved

def _indexed_region_signature(region_name: str) -> str:
    if not re.search(r"(^|_)\d+(_|$)", region_name):
        return ""
    return re.sub(r"(^|_)\d+(_|$)", lambda match: "%s#%s" % (match.group(1), match.group(2)), region_name)

def _require_manual_sample_asset(
    game_root: Path,
    data: dict,
    value: object,
    label: str,
    failures: list[str],
) -> None:
    if not isinstance(value, str) or not value:
        failures.append(f"{label} required for image/icon placement payload preview")
        return
    path = Path(value)
    if path.is_absolute():
        failures.append(f"{label} must be relative to editor config")
        return
    source_path_value = data.get("__source_path")
    if isinstance(source_path_value, str) and source_path_value:
        base_dir = Path(source_path_value).parent
        resolved = (base_dir / path).resolve()
    else:
        resolved = (game_root / path).resolve()
    try:
        resolved.relative_to(game_root.resolve())
    except ValueError:
        failures.append(f"{label} points outside game root: {value}")
        return
    if not resolved.exists():
        failures.append(f"{label} missing payload preview asset: {value}")

def _require_manual_layer_contract(screen_name: str, editor_config: dict | None, failures: list[str]) -> None:
    if editor_config == None:
        return
    layer_contract = editor_config.get("layer_contract")
    if not isinstance(layer_contract, dict):
        failures.append(f"manual placement {screen_name}.editor_config missing layer_contract")
        return
    background = layer_contract.get("background")
    content_panel = layer_contract.get("content_panel")
    stage_overlay = layer_contract.get("stage_overlay")
    if not isinstance(background, dict):
        failures.append(f"manual placement {screen_name}.layer_contract.background must be an object")
    elif background.get("contains_runtime_payload") is not False:
        failures.append(f"manual placement {screen_name}.layer_contract.background.contains_runtime_payload must be false")
    if not isinstance(content_panel, dict):
        failures.append(f"manual placement {screen_name}.layer_contract.content_panel must be an object")
    if not isinstance(stage_overlay, dict):
        failures.append(f"manual placement {screen_name}.layer_contract.stage_overlay must be an object")
    preview_required = _manual_stage_payload_preview_required(editor_config)
    if isinstance(content_panel, dict) and isinstance(stage_overlay, dict):
        if preview_required:
            if editor_config.get("stage_preview_enabled") is not True:
                failures.append(f"manual placement {screen_name}.editor_config.stage_preview_enabled must be true when icon/image/placeable shell slots use sample_asset")
            if content_panel.get("drawn_on_stage") is not True:
                failures.append(f"manual placement {screen_name}.layer_contract.content_panel.drawn_on_stage must be true for separate DOM payload preview")
            if stage_overlay.get("draws_payload") is not True:
                failures.append(f"manual placement {screen_name}.layer_contract.stage_overlay.draws_payload must be true for separate DOM payload preview")
            if stage_overlay.get("payload_preview_is_baked") is not False:
                failures.append(f"manual placement {screen_name}.layer_contract.stage_overlay.payload_preview_is_baked must be false")
        else:
            if content_panel.get("drawn_on_stage") is not False:
                failures.append(f"manual placement {screen_name}.layer_contract.content_panel.drawn_on_stage must be false when no stage preview is required")
            if stage_overlay.get("draws_payload") is not False:
                failures.append(f"manual placement {screen_name}.layer_contract.stage_overlay.draws_payload must be false when no stage preview is required")

    removed = editor_config.get("clean_background_payload_slot_kinds_removed")
    if not isinstance(removed, list) or not removed:
        failures.append(f"manual placement {screen_name}.editor_config missing clean_background_payload_slot_kinds_removed")
        removed_kinds: set[str] = set()
    else:
        removed_kinds = {str(kind) for kind in removed}
    regions = editor_config.get("regions", {})
    if not isinstance(regions, dict):
        return
    required_kinds: set[str] = set()
    for region in regions.values():
        if isinstance(region, dict):
            slot_kind = region.get("slot_kind")
            if slot_kind == "shell":
                continue
            if isinstance(slot_kind, str):
                required_kinds.add(slot_kind)
    for slot_kind in sorted(required_kinds - removed_kinds):
        failures.append(
            f"manual placement {screen_name}.clean_background_payload_slot_kinds_removed missing slot_kind: {slot_kind}"
        )

def _manual_stage_payload_preview_required(editor_config: dict) -> bool:
    regions = editor_config.get("regions", {})
    if not isinstance(regions, dict):
        return False
    clean_asset_paths = set()
    runtime_asset_paths = editor_config.get("runtime_asset_paths", {})
    clean_background_keys = editor_config.get("clean_background_asset_keys", [])
    if isinstance(runtime_asset_paths, dict) and isinstance(clean_background_keys, list):
        for key in clean_background_keys:
            value = runtime_asset_paths.get(key)
            if isinstance(value, str) and value:
                clean_asset_paths.add(value)
    for region in regions.values():
        if not isinstance(region, dict):
            continue
        slot_kind = region.get("slot_kind")
        sample_asset = region.get("sample_asset")
        if not isinstance(sample_asset, str) or not sample_asset:
            continue
        if slot_kind in ["icon", "image"]:
            return True
        if slot_kind == "shell" and sample_asset not in clean_asset_paths:
            return True
    return False

def _require_manual_stage_payload_preview(
    screen_name: str,
    editor_config: dict | None,
    editor_html: Path | None,
    failures: list[str],
) -> None:
    if editor_config == None or editor_html == None:
        return
    if not _manual_stage_payload_preview_required(editor_config):
        return
    try:
        html = editor_html.read_text(encoding="utf-8")
    except OSError as exc:
        failures.append(f"manual placement {screen_name}.editor_html cannot be read: {exc}")
        return
    for token in [
        "regionPayloadPreview",
        "getStagePreviewAsset",
        "stage_preview_enabled",
        "payload preview is a separate DOM layer",
    ]:
        if token not in html:
            failures.append(f"manual placement {screen_name}.editor_html missing stage payload preview: {token}")
    for region_name, region in dict(editor_config.get("regions", {})).items():
        if not isinstance(region, dict):
            continue
        slot_kind = region.get("slot_kind")
        sample_asset = region.get("sample_asset")
        if not isinstance(sample_asset, str) or not sample_asset:
            continue
        if slot_kind not in ["icon", "image", "shell"]:
            continue
        clean_asset_paths = {
            str(editor_config.get("runtime_asset_paths", {}).get(key, ""))
            for key in editor_config.get("clean_background_asset_keys", [])
            if isinstance(editor_config.get("runtime_asset_paths", {}), dict)
        }
        if slot_kind == "shell" and sample_asset in clean_asset_paths:
            continue
        if region.get("stage_preview_enabled") is not True:
            failures.append(f"manual placement {screen_name}.editor_config region {region_name}.stage_preview_enabled must be true")

def _require_manual_editor_navigation(
    screen_name: str,
    editor_html: Path | None,
    editor_config: dict | None,
    failures: list[str],
) -> None:
    if editor_html == None or editor_config == None:
        return
    home_href = editor_config.get("home_href", "index.html")
    if not isinstance(home_href, str) or not home_href:
        failures.append(f"manual placement {screen_name}.editor_config home_href must be a relative menu link")
        return
    try:
        html = editor_html.read_text(encoding="utf-8")
    except OSError as exc:
        failures.append(f"manual placement {screen_name}.editor_html cannot be read: {exc}")
        return
    if "Menu" not in html:
        failures.append(f"manual placement {screen_name}.editor_html missing Menu navigation")
    if f'href="{home_href}"' not in html:
        failures.append(f"manual placement {screen_name}.editor_html missing home_href link: {home_href}")
    for token in [
        "Image - mobile_ultra placement proof",
        "Text or slot content",
        "Yellow frame coordinates",
        "Payload references live here",
        "layerContract",
        "sampleAsset",
    ]:
        if token not in html:
            failures.append(f"manual placement {screen_name}.editor_html missing independent layer panel: {token}")
    for token in [
        "selectedKeys",
        "ctrlKey",
        "shiftKey",
        "metaKey",
        "isSelected",
        "selectAll",
        "clearSelection",
        "Drag any selected yellow frame",
        "proportionalGroupScaleFactor",
        "scale every selected frame proportionally",
    ]:
        if token not in html:
            failures.append(f"manual placement {screen_name}.editor_html missing multi-select control: {token}")

def _require_manual_background_quality(screen_name: str, placement: dict, editor_config: dict | None, failures: list[str]) -> None:
    if editor_config == None:
        return
    min_size_value = placement.get("min_background_size")
    if not isinstance(min_size_value, list) or len(min_size_value) != 2:
        failures.append(f"manual placement {screen_name}.min_background_size must be [w, h]")
        return
    try:
        min_width = int(min_size_value[0])
        min_height = int(min_size_value[1])
    except (TypeError, ValueError):
        failures.append(f"manual placement {screen_name}.min_background_size values must be integers")
        return
    if min_width <= 0 or min_height <= 0:
        failures.append(f"manual placement {screen_name}.min_background_size must be positive")
        return

    backgrounds = editor_config.get("backgrounds")
    if not isinstance(backgrounds, dict) or not backgrounds:
        failures.append(f"manual placement {screen_name}.editor_config missing backgrounds")
        return
    config_path_value = editor_config.get("__source_path")
    if not isinstance(config_path_value, str) or not config_path_value:
        failures.append(f"manual placement {screen_name}.editor_config missing source path")
        return
    config_path = Path(config_path_value)
    stage_aspect = editor_config.get("stage_aspect")
    expected_ratio = None
    if isinstance(stage_aspect, list) and len(stage_aspect) == 2:
        try:
            expected_ratio = float(stage_aspect[0]) / float(stage_aspect[1])
        except (TypeError, ValueError, ZeroDivisionError):
            expected_ratio = None
    for mode, rel_path in backgrounds.items():
        if not isinstance(rel_path, str) or not rel_path:
            failures.append(f"manual placement {screen_name}.backgrounds.{mode} must be a relative image path")
            continue
        background_path = (config_path.parent / rel_path).resolve()
        if not background_path.exists():
            failures.append(f"manual placement {screen_name}.backgrounds.{mode} missing image: {rel_path}")
            continue
        actual = _png_dimensions(background_path)
        if actual == None:
            failures.append(f"manual placement {screen_name}.backgrounds.{mode} is not a PNG: {rel_path}")
            continue
        actual_width, actual_height = actual
        if actual_width < min_width or actual_height < min_height:
            failures.append(
                f"manual placement {screen_name}.backgrounds.{mode} image {actual_width}x{actual_height} below min {min_width}x{min_height}"
            )
        if expected_ratio != None:
            actual_ratio = actual_width / actual_height
            if abs(actual_ratio - expected_ratio) > 0.02:
                failures.append(
                    f"manual placement {screen_name}.backgrounds.{mode} aspect {actual_ratio:.3f} does not match stage {expected_ratio:.3f}"
                )

def _require_manual_clean_background_audit(
    game_root: Path,
    screen_name: str,
    placement: dict,
    editor_config: dict | None,
    failures: list[str],
) -> None:
    if editor_config == None:
        return
    audit = _load_manual_placement_json(
        game_root,
        placement.get("clean_background_audit"),
        f"{screen_name}.clean_background_audit",
        failures,
    )
    if audit == None:
        return
    if audit.get("status") != "PASS":
        failures.append(f"manual placement {screen_name}.clean_background_audit status must be PASS")
    if audit.get("background_payload_policy") != "clean_shell_frame_only":
        failures.append(
            f"manual placement {screen_name}.clean_background_audit background_payload_policy must be clean_shell_frame_only"
        )
    capture_method = audit.get("capture_method")
    if not isinstance(capture_method, str) or not capture_method.strip():
        failures.append(f"manual placement {screen_name}.clean_background_audit missing capture_method")
    verification_basis = audit.get("verification_basis")
    allowed_verification_basis = [
        "asset_composition_from_canonical_assets_and_theme_metrics",
        "capture_pipeline_hidden_payload_nodes",
        "visual_inspection_and_capture_pipeline",
    ]
    if verification_basis not in allowed_verification_basis:
        failures.append(
            f"manual placement {screen_name}.clean_background_audit verification_basis must be one of {allowed_verification_basis}"
        )

    required_removed = _required_payload_slot_kinds(editor_config)
    backgrounds = editor_config.get("backgrounds", {})
    checked_backgrounds = audit.get("checked_backgrounds")
    if not isinstance(backgrounds, dict) or not isinstance(checked_backgrounds, dict):
        failures.append(f"manual placement {screen_name}.clean_background_audit checked_backgrounds must cover editor backgrounds")
        return
    for mode, rel_path in backgrounds.items():
        check = checked_backgrounds.get(mode)
        if not isinstance(check, dict):
            failures.append(f"manual placement {screen_name}.clean_background_audit missing background mode: {mode}")
            continue
        if check.get("path") != rel_path:
            failures.append(
                f"manual placement {screen_name}.clean_background_audit.{mode}.path must match editor background {rel_path}"
            )
        for field_name in PAYLOAD_BAKE_FLAGS:
            if check.get(field_name) is not False:
                failures.append(
                    f"manual placement {screen_name}.clean_background_audit.{mode}.{field_name} must be false"
                )
        removed = check.get("removed_slot_kinds")
        if not isinstance(removed, list):
            failures.append(f"manual placement {screen_name}.clean_background_audit.{mode}.removed_slot_kinds must be a list")
            continue
        removed_set = {str(kind) for kind in removed}
        for slot_kind in sorted(required_removed - removed_set):
            failures.append(
                f"manual placement {screen_name}.clean_background_audit.{mode}.removed_slot_kinds missing slot_kind: {slot_kind}"
            )

def _required_payload_slot_kinds(editor_config: dict) -> set[str]:
    kinds: set[str] = set()
    for region in _manual_region_coverage(editor_config, False).values():
        if not isinstance(region, dict):
            continue
        slot_kind = region.get("slot_kind")
        if slot_kind == "shell":
            continue
        if isinstance(slot_kind, str):
            kinds.add(slot_kind)
    return kinds

def _require_manual_placement_file(game_root: Path, value: object, label: str, failures: list[str]) -> Path | None:
    if not isinstance(value, str) or not value:
        failures.append(f"manual placement {label} must be a game-relative path")
        return None
    path = Path(value)
    if path.is_absolute():
        failures.append(f"manual placement {label} must not be an absolute path")
        return None
    resolved = game_root / path
    if not resolved.exists():
        failures.append(f"manual placement {label} missing path: {value}")
        return None
    return resolved

def _load_manual_placement_json(game_root: Path, value: object, label: str, failures: list[str]) -> dict | None:
    path = _require_manual_placement_file(game_root, value, label, failures)
    if path == None:
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"manual placement {label} invalid JSON: {exc}")
        return None
    if not isinstance(data, dict):
        failures.append(f"manual placement {label} JSON must be an object")
        return None
    data["__source_path"] = str(path)
    return data

def _parse_named_rects(value: object, label: str, failures: list[str]) -> dict[str, tuple[float, float, float, float]]:
    if not isinstance(value, dict):
        failures.append(f"visual composition rule {label} must be an object")
        return {}
    parsed: dict[str, tuple[float, float, float, float]] = {}
    for name, rect_value in value.items():
        rect = _rect_from_value(rect_value, f"{label}.{name}", failures)
        if rect != None:
            parsed[str(name)] = rect
    return parsed

def _safe_padding(surface_rule: dict, surface_name: str, failures: list[str]) -> float:
    safe_padding = surface_rule.get("safe_padding", 0.0)
    try:
        value = float(safe_padding)
    except (TypeError, ValueError):
        failures.append(f"visual composition rule {surface_name}.safe_padding must be numeric")
        return 0.0
    if value < 0.0:
        failures.append(f"visual composition rule {surface_name}.safe_padding must be >= 0")
        return 0.0
    return value


def _require_no_forbidden_claims(texts: dict[str, str], failures: list[str]) -> None:
    joined = "\n".join(texts.values())
    bad_patterns = [
        r"RUNTIME_FIT_PASS\s+means\s+final",
        r"RUNTIME_FIT_PASS\s+is\s+final",
        r"runtime fit\s+is\s+final art",
    ]
    for pattern in bad_patterns:
        if re.search(pattern, joined, re.IGNORECASE):
            failures.append(f"forbidden art/UI gate claim matches: {pattern}")


def main() -> int:
    parser = argparse.ArgumentParser(prog="validate_art_ui_gate")
    parser.add_argument("--game-root", required=True)
    parser.add_argument("--contract")
    args = parser.parse_args()
    failures = validate_art_ui_gate(
        Path(args.game_root),
        Path(args.contract) if args.contract else None,
    )
    if failures:
        print("validate_art_ui_gate: FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("validate_art_ui_gate: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
