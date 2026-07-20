# SSOT Registry Doctrine

This is the mandatory anti-spam rule for Shinokute reskins and core/game/UI work. It applies to every SSOT-like function: runtime config, game content, progression, layout, UI/theme, asset manifests, manual placement, save/profile shape, evidence gates, and generated tooling.

Policy: `one_function_one_canonical`.

Every function that has config, layout, asset, placement, progression, content, save, or presentation data must be registered before an agent creates or edits another SSOT-like file.

## Required Roles

Use these roles only:

| Role | Meaning | May runtime read it? |
|---|---|---|
| `runtime_ssot` | Runtime source of truth consumed by game/core code. | yes |
| `owner_input_ssot` | Owner-authored input such as polygon regions or manual placement config. | no, unless explicitly promoted after owner approval |
| `doc_contract` | Human-readable rules, checklist, or surface contract. | no |
| `generated_artifact` | HTML, export JSON, generated report, packed derivative, or generated copy from a canonical file. | no |
| `evidence` | Screenshot, QC, audit, approval packet, or proof. | no |

## Registry Shape

Each game keeps a game-owned JSON registry such as `docs/ssot_registry.json`:

```json
{
  "schema_version": 1,
  "policy": "one_function_one_canonical",
  "functions": [
    {
      "function_id": "upgrade_overlay_placement",
      "canonical_role": "owner_input_ssot",
      "canonical_file": "docs/art_ui_manual_placement/skill_board_text_region_editor_config.json",
      "derived_files": [
        {
          "path": "docs/art_ui_manual_placement/skill_board_text_region_editor.html",
          "role": "generated_artifact",
          "source": "docs/art_ui_manual_placement/skill_board_text_region_editor_config.json"
        }
      ],
      "evidence_files": [
        {
          "path": "docs/art_ui_manual_placement/skill_board_text_clean_background_audit.json",
          "role": "evidence"
        }
      ],
      "runtime_consumers": [
        "Resources/Data/last_hope_theme_config.tres"
      ]
    }
  ]
}
```

## Hard Rules

- One `function_id` has one `canonical_file`.
- One `canonical_file` belongs to one `function_id`.
- Generated files must name their source canonical file.
- Evidence files prove state; they do not become canonical.
- Draft exports are generated artifacts, not runtime SSOT.
- Runtime may read only `runtime_ssot` files unless the game records an owner-approved promotion.
- Before adding a new config/doc/export/QC file, update the registry first.
- Before deleting or replacing a file, update the registry and validator together.
- If two files can answer the same question, one is canonical and the other is derived/evidence or must be removed.
- No local convenience SSOT may be created outside the registry, even temporarily. Temporary files must be marked generated/evidence and must trace back to one canonical file.

## Core Validator

`tools/validate_art_ui_gate.py` reads `docs/art_ui_gate_contract.json` `ssot_registry.path`.

The core gate fails when:

- `ssot_registry` is missing.
- registry policy is not `one_function_one_canonical`.
- a `function_id` appears twice.
- two function ids reuse one canonical file.
- any registered file is missing.
- a generated artifact does not contain its canonical source path.
- docs do not mention the registry policy.

## Agent Rule

Do not create another SSOT-like file because a task feels local. Add a registry row first. If the row already exists, edit the canonical file or regenerate its derived artifacts. Do not create a parallel branch.
