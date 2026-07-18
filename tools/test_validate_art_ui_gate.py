from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from validate_art_ui_gate import (
    _require_art_process_rules,
    _require_manual_clean_background_audit,
    _require_manual_placement_rules,
    _require_reference_lock_rules,
    _require_repeated_region_group_policy,
)


class ManualPlacementRepeatedRegionPolicyTest(unittest.TestCase):
    def test_art_pipeline_reset_blocks_manual_placement_claims(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_RESET",
                "master_theme_status": "MASTER_THEME_PENDING",
                "source_asset_status": "ART_SOURCE_NOT_READY",
                "old_art_status": "OLD_ART_REJECTED",
                "manual_placement_allowed": False,
            },
            "manual_placement": {
                "required": True,
                "surfaces": {
                    "Level HUD": {
                        "status": "READY_FOR_OWNER_ADJUSTMENT",
                    }
                },
            },
        }
        texts = {
            "style_bible": "ART_PIPELINE_RESET MASTER_THEME_PENDING ART_SOURCE_NOT_READY OLD_ART_REJECTED",
        }
        screenshot_rows = {
            "Level HUD": ["Level HUD", "", "", "READY_FOR_OWNER_ADJUSTMENT"],
        }

        _require_art_process_rules(contract, texts, screenshot_rows, failures)

        self.assertTrue(any("manual_placement.required must be false" in failure for failure in failures), failures)
        self.assertTrue(any("manual_placement.surfaces must be empty" in failure for failure in failures), failures)
        self.assertTrue(any("manual-placement status while manual placement is disabled" in failure for failure in failures), failures)

    def test_art_pipeline_reset_requires_unapproved_theme_and_source(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_RESET",
                "master_theme_status": "MASTER_THEME_APPROVED",
                "source_asset_status": "SOURCE_ASSET_APPROVED",
                "old_art_status": "OLD_ART_PROTOTYPE_ONLY",
                "manual_placement_allowed": True,
            }
        }
        texts = {
            "style_bible": "ART_PIPELINE_RESET MASTER_THEME_APPROVED SOURCE_ASSET_APPROVED OLD_ART_PROTOTYPE_ONLY",
        }

        _require_art_process_rules(contract, texts, {}, failures)

        self.assertTrue(any("MASTER_THEME_PENDING" in failure for failure in failures), failures)
        self.assertTrue(any("ART_SOURCE_NOT_READY" in failure for failure in failures), failures)
        self.assertTrue(any("OLD_ART_REJECTED" in failure for failure in failures), failures)
        self.assertTrue(any("manual_placement_allowed = false" in failure for failure in failures), failures)

    def test_source_approval_requires_reference_lock(self) -> None:
        failures: list[str] = []
        contract = {
            "art_process": {
                "status": "ART_PIPELINE_ACTIVE",
                "master_theme_status": "MASTER_THEME_APPROVED",
                "source_asset_status": "SOURCE_ASSET_APPROVED",
                "old_art_status": "OLD_ART_REJECTED",
                "manual_placement_allowed": False,
            },
            "reference_lock": {
                "reference_sheet_status": "REFERENCE_SHEET_PENDING",
                "generation_spec_status": "GENERATION_SPEC_PENDING",
                "reference_sheet": "docs/art_reference_sheet.md",
                "generation_spec": "docs/art_generation_spec.md",
                "min_references": 10,
                "max_references": 30,
                "required_buckets": ["Vietnamese form language"],
            },
        }

        _require_reference_lock_rules(Path.cwd(), contract, {}, failures)

        self.assertTrue(any("SOURCE_ASSET_APPROVED requires REFERENCE_SHEET_LOCKED" in failure for failure in failures), failures)
        self.assertTrue(any("SOURCE_ASSET_APPROVED requires GENERATION_SPEC_LOCKED" in failure for failure in failures), failures)

    def test_locked_reference_sheet_requires_rows_and_buckets(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "docs"
            docs.mkdir()
            (docs / "art_reference_sheet.md").write_text(
                "\n".join(
                    [
                        "# Art Reference Sheet",
                        "",
                        "| Reference | Bucket | Learn This | Do Not Copy | Source Use |",
                        "|---|---|---|---|---|",
                        "| https://example.com/ref-01 | Vietnamese form language | bronze rhythm | exact protected artwork | silhouette only |",
                    ]
                ),
                encoding="utf-8",
            )
            (docs / "art_generation_spec.md").write_text(
                "# Art Generation Spec\n\nVietnam Tech Fantasy Hybrid\n\nruntime job\nasset family\n9Router\ncx/gpt-5.5-image\n",
                encoding="utf-8",
            )
            failures: list[str] = []
            contract = {
                "art_process": {
                    "source_asset_status": "ART_SOURCE_NOT_READY",
                },
                "reference_lock": {
                    "reference_sheet_status": "REFERENCE_SHEET_LOCKED",
                    "generation_spec_status": "GENERATION_SPEC_LOCKED",
                    "reference_sheet": "docs/art_reference_sheet.md",
                    "generation_spec": "docs/art_generation_spec.md",
                    "min_references": 10,
                    "max_references": 30,
                    "required_buckets": [
                        "Vietnamese form language",
                        "Vietnamese material language",
                    ],
                },
            }

            _require_reference_lock_rules(root, contract, {}, failures)

        self.assertTrue(any("reference count 1 below min 10" in failure for failure in failures), failures)
        self.assertTrue(any("missing required bucket: Vietnamese material language" in failure for failure in failures), failures)

    def test_runtime_fit_requires_owner_placement_approval(self) -> None:
        failures: list[str] = []
        contract = {
            "runtime_fit_rows": {
                "Upgrade overlay": ["RUNTIME_FIT_PASS"],
            },
            "manual_placement": {
                "required": True,
                "surfaces": {
                    "Upgrade overlay": {
                        "status": "READY_FOR_OWNER_ADJUSTMENT",
                        "applies_to": ["panel_title"],
                    }
                },
            },
        }
        screenshot_rows = {
            "Upgrade overlay": ["Upgrade overlay", "", "", "RUNTIME_FIT_PASS"],
        }

        _require_manual_placement_rules(Path.cwd(), contract, screenshot_rows, failures)

        self.assertTrue(
            any("must be OWNER_PLACEMENT_APPROVED before RUNTIME_FIT_PASS" in failure for failure in failures),
            failures,
        )

    def test_indexed_duplicate_regions_require_repeated_group(self) -> None:
        failures: list[str] = []
        config = {
            "regions": {
                "card_1_title": {
                    "slot_kind": "text",
                    "sample_text": "Skill A",
                    "x": 0.1,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                },
                "card_2_title": {
                    "slot_kind": "text",
                    "sample_text": "Skill B",
                    "x": 0.4,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                },
            }
        }

        _require_repeated_region_group_policy("Upgrade overlay", config, failures)

        self.assertTrue(
            any("without repeated_region_groups" in failure for failure in failures),
            failures,
        )

    def test_template_group_derives_concrete_instances(self) -> None:
        failures: list[str] = []
        config = {
            "regions": {
                "card_title_template": {
                    "slot_kind": "text",
                    "sample_text": "Skill Name Lv 1",
                    "x": 0.1,
                    "y": 0.2,
                    "w": 0.2,
                    "h": 0.1,
                }
            },
            "repeated_region_groups": {
                "upgrade_cards": {
                    "rule": "drag_once_apply_to_all_instances",
                    "templates": {"title": "card_title_template"},
                    "instances": [
                        {
                            "id": "card_1",
                            "offset": [0.0, 0.0],
                            "exports": {"title": "card_1_title"},
                        },
                        {
                            "id": "card_2",
                            "offset": [0.25, 0.0],
                            "exports": {"title": "card_2_title"},
                        },
                    ],
                }
            },
        }

        _require_repeated_region_group_policy("Upgrade overlay", config, failures)

        self.assertEqual([], failures)

    def test_clean_background_audit_is_required(self) -> None:
        failures: list[str] = []

        _require_manual_clean_background_audit(Path.cwd(), "Upgrade overlay", {}, self._editor_config(), failures)

        self.assertTrue(any("clean_background_audit" in failure for failure in failures), failures)

    def test_clean_background_audit_blocks_baked_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "audit.json").write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "background_payload_policy": "clean_shell_frame_only",
                        "capture_method": "hide runtime labels and icon nodes before capture",
                        "verification_basis": "capture_pipeline_hidden_payload_nodes",
                        "checked_backgrounds": {
                            "desktop": {
                                "path": "../screenshots/upgrade_clean.png",
                                "contains_runtime_text": True,
                                "contains_runtime_icon": False,
                                "contains_runtime_image": False,
                                "contains_runtime_control": False,
                                "removed_slot_kinds": ["text", "icon"],
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_manual_clean_background_audit(
                root,
                "Upgrade overlay",
                {"clean_background_audit": "audit.json"},
                self._editor_config(),
                failures,
            )

        self.assertTrue(any("contains_runtime_text" in failure for failure in failures), failures)

    def test_clean_background_audit_accepts_clean_payload_proof(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "audit.json").write_text(
                json.dumps(
                    {
                        "status": "PASS",
                        "background_payload_policy": "clean_shell_frame_only",
                        "capture_method": "hide runtime labels and icon nodes before capture",
                        "verification_basis": "capture_pipeline_hidden_payload_nodes",
                        "checked_backgrounds": {
                            "desktop": {
                                "path": "../screenshots/upgrade_clean.png",
                                "contains_runtime_text": False,
                                "contains_runtime_icon": False,
                                "contains_runtime_image": False,
                                "contains_runtime_control": False,
                                "removed_slot_kinds": ["text", "icon"],
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            failures: list[str] = []

            _require_manual_clean_background_audit(
                root,
                "Upgrade overlay",
                {"clean_background_audit": "audit.json"},
                self._editor_config(),
                failures,
            )

        self.assertEqual([], failures)

    def _editor_config(self) -> dict:
        return {
            "backgrounds": {"desktop": "../screenshots/upgrade_clean.png"},
            "regions": {
                "panel_title": {
                    "slot_kind": "text",
                    "sample_text": "SIGNAL SKILL",
                    "x": 0.1,
                    "y": 0.1,
                    "w": 0.2,
                    "h": 0.1,
                },
                "card_icon_template": {
                    "slot_kind": "icon",
                    "sample_text": "Icon",
                    "sample_asset": "../icons/icon.png",
                    "x": 0.1,
                    "y": 0.3,
                    "w": 0.1,
                    "h": 0.1,
                },
            },
        }


if __name__ == "__main__":
    unittest.main()
