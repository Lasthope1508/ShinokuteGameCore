# {{GAME_NAME}} Game Art And UI Bible

Use this file before changing game UI, HUD, overlays, backgrounds, sprites, VFX, generated assets, or screenshots.

Core gate:
- `{{CORE_PATH}}/docs/art_ui_design_gate.md`
- `{{CORE_PATH}}/docs/art_ui_asset_inventory_method.md`
- `{{CORE_PATH}}/tools/validate_art_ui_gate.py`

Validation:

```powershell
python {{CORE_PATH}}/tools/validate_art_ui_gate.py --game-root {{GAME_ROOT}} --contract {{GAME_ROOT}}/docs/art_ui_gate_contract.json
```

## Current Art State

- Style name: {{STYLE_NAME}}
- Target platforms: {{TARGET_PLATFORMS}}
- Primary viewport: {{PRIMARY_VIEWPORT}}
- Mobile viewport: {{MOBILE_VIEWPORT}}
- Current final-art status: {{FINAL_ART_STATUS}}

RUNTIME_FIT_PASS is not final art design approval.
Text-bearing RUNTIME_FIT_PASS surfaces must have `manual_placement` editor config, generated HTML, export JSON, editable slot ids, and `OWNER_PLACEMENT_APPROVED` before runtime-fit acceptance.
Generated/runtime UI images must satisfy the selected core `image_quality_profile`; mobile production art should use `mobile_high_quality` or stronger.
Manual placement backgrounds must be clean shell/frame proof only. Runtime text, icon, image, or control payloads must not be baked into the background. Icon, image, and placeable shell payloads that runtime draws inside owner slots must appear as separate DOM previews inside the yellow frame through `stage_preview_enabled`; side-panel-only preview is not enough.
Manual placement editor configs must declare `surface_asset_keys`, `runtime_asset_paths`, and `background_runtime_basis = clean_composite_from_surface_asset_keys` before owner dragging starts.
Screenshot proof must use `godot_scene_capture_runtime_stretch` or `foreground_window_capture`; `PrintWindow` is forbidden for Godot/Vulkan runtime proof because it can capture a black or stale surface.

## Visual Pillars

- {{VISUAL_PILLAR_1}}
- {{VISUAL_PILLAR_2}}
- {{VISUAL_PILLAR_3}}

## Art Design Approval Gate

| Surface | Design state | Reason |
|---|---|---|
| {{SURFACE_ID}} | `ART_DESIGN_PENDING` | {{PENDING_REASON}} |

## Negative Rules

- No fallback asset, fallback metric, fallback label, or fallback art path.
- No `fallback_*`, `*_fallback`, `default_*`, or `*_default` keys in art/UI contracts, asset ids, placement fields, visual-composition fields, or runtime asset maps.
- Generic core missing-value helpers are not reskin fallbacks and must not create UI/art assets, labels, paths, metrics, placement, or owner approval.
- No final art claim while any required row is `ART_DESIGN_PENDING`.
- No agent-picked text placement claim. The game-owned HTML manual placement editor creates draft values; only owner-approved exports may drive final runtime fit.
- No runtime text, icon, image, or control payload baked into shell art or manual-placement backgrounds unless explicitly static branding.
- No generated source sheet as runtime asset without extraction/QC record.
- No screenshot claim from blank, wrong-window, stale, or `PrintWindow` captures.
