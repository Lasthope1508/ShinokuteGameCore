# {{GAME_NAME}} Art Pipeline Validation Gate

Core gate: `{{CORE_PATH}}/docs/art_ui_design_gate.md`

Command:

```powershell
python {{CORE_PATH}}/tools/validate_art_ui_gate.py --game-root {{GAME_ROOT}} --contract {{GAME_ROOT}}/docs/art_ui_gate_contract.json
```

## Hard Fail Conditions

- missing count matrix
- missing coverage matrix
- missing composition contract
- missing screenshot checklist
- missing required surface rows
- missing required asset keys
- `RUNTIME_FIT_PASS` described as final art design approval
- final art claim while a row remains `ART_DESIGN_PENDING`
- missing core `image_quality_profile`
- generated/runtime UI PNG below selected profile source scale
- missing `screenshot_capture_policy`
- screenshot proof using `PrintWindow` instead of `godot_scene_capture_runtime_stretch` or `foreground_window_capture`
- screenshot proof failing nonblank pixel audit or visual inspection
- core `visual_composition_rules` fail: `max_surface_viewport_area_ratio`, `text_safe_zones`, `slot_rects`, `ornament_exclusion_zones`, or `safe_padding`
- core `manual_placement` fails: missing editor config, missing generated HTML, missing menu navigation, missing export JSON, missing editable slot ids, missing `surface_asset_keys`, missing `runtime_asset_paths`, missing `background_runtime_basis = clean_composite_from_surface_asset_keys`, shell preview asset not matching declared runtime paths, undersized editor background image, `RUNTIME_FIT_PASS` without `OWNER_PLACEMENT_APPROVED`, or owner-approved claim without owner-approved placement status
- core `source_extraction` fails: missing owner polygon editor, missing Photoroom alpha sheet, `outline_author` not `owner_manual_polygon`, extraction allowed while outline is pending, or approved owner outline JSON missing polygon points
- fallback asset, fallback metric, fallback label, or fallback art path
- fallback/default-looking contract keys such as `fallback_*`, `*_fallback`, `default_*`, or `*_default`

## Game Contract

The game-owned `docs/art_ui_gate_contract.json` supplies concrete surface ids, asset keys, screenshot rows, pending-art rows, required tokens, `screenshot_capture_policy`, `image_quality_profile`, `visual_composition_rules`, `manual_placement`, and `source_extraction`.
