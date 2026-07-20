# Art UI Asset Inventory Method

Use this before any reskin, final art pass, generated asset batch, UI rewrite, HUD pass, or overlay pass.

Count from this chain:

`runtime surface -> asset family -> semantic key -> state variant -> proof requirement`

Do not count folder contents. Folders contain raw sheets, rejected variants, imports, masks, and old assets.

## 1. Runtime Surfaces

List every visible surface:

- title/menu
- gameplay world
- HUD
- overlays
- result/score screens
- settings/profile/leaderboard
- touch/gamepad UI
- actors, projectiles, pickups, VFX
- loading/error/empty states

## 2. Ownership Split

For each surface, record:

- core: reusable behavior, validation, lifecycle, resolver, or service only
- game: rules, ids, tuning, content semantics, progression, spawn, rewards
- UI/art: labels, descriptions, icons, panels, board art, background, font, color, layout, screenshot proof

## 3. Composition Before Art

For each UI surface, record:

- owner rect
- safe content rect
- text slot
- icon slot
- image slot
- button/hitbox rect
- `visual_composition_rules`
- `max_surface_viewport_area_ratio`
- `text_safe_zones`
- `art_safe_zones`
- `slot_rects`
- `ornament_exclusion_zones`
- `safe_padding`
- rect semantic boundary: declare `control_owner_rect`, `visual_shell_rect`, text/icon slot rects, and `coordinate_space` separately before runtime wiring
- `manual_placement` editor config, generated HTML, export JSON, and editable slot ids
- `min_background_size` for the placement editor background image
- `image_quality_profile` selected from core profile names
- UI source PNG scale and exact/minimum pixel size policy
- UI source resize mode: `cover_crop_exact` or `contain_with_bleed_exact`
- screenshot capture method and nonblank pixel audit for every proof image
- line count and max chars
- font token and line height
- state assets
- desktop and mobile proof requirement

No PNG decides layout by itself. The game-owned composition contract decides layout first.
No ornament decides layout by itself. Text safe zones, art-safe zones, and ornament exclusion zones are declared before art is generated around them. A `RUNTIME_FIT_PASS` screenshot row must have a matching owner-approved visual composition surface rule.
No agent-picked coordinate can be treated as final fit by itself. For every text-bearing runtime-fit surface, create a game-owned HTML drag editor from the composition contract, let the owner adjust text/icon slots, and record the export JSON before applying approved values to runtime SSOT.
No owner placement rect may answer multiple runtime questions. A `control_owner_rect` is the Control/Button/Hitbox size, a `visual_shell_rect` is art placement, a text safe rect is payload placement, and an icon slot rect is image placement. If the owner drags a yellow visual frame, the game must convert it into the correct runtime role through documented `coordinate_space` rules instead of reusing it as a control size.
Use `READY_FOR_OWNER_ADJUSTMENT` while the editor/export is draft. Draft values are not runtime-fit evidence. Use `OWNER_PLACEMENT_APPROVED` only after the owner accepts the placement values.
Do not use blurry or undersized screenshots as placement backgrounds. The editor background must meet the game contract `min_background_size` before the owner starts dragging slots.
Do not use `PrintWindow` on a Godot/Vulkan runtime window for proof captures. Use in-engine scene capture or foreground screen capture, then inspect the pixels before trusting the file.
Do not ask for or accept generated UI images before the game contract declares `image_quality_profile`. For production mobile/web UI, use core `mobile_high_quality` or stronger, then record every runtime UI PNG under `ui_source_assets` with `owner_size`, `source_scale`, `size_policy`, and `path`.
Do not crop cards, buttons, or frame objects just to match owner ratio when their transparent bleed is part of the source. Record `resize_mode = contain_with_bleed_exact` so exact runtime packaging preserves the full object inside a transparent canvas.

## 3b. Source Sheet Extraction Before Runtime Packaging

For generated sheets or dense concept sheets, count and record the extraction contract before any crop:

- source sheet path
- Photoroom full-sheet alpha path
- owner polygon editor HTML path
- owner outline JSON path
- `outline_author = owner_manual_polygon`
- `status = OWNER_POLYGON_OUTLINE_PENDING` before the owner draws
- `extraction_allowed = false` until owner approval
- asset keys covered by the sheet

No auto-hull, auto-bbox, grid slicing, raw-sheet crop, or agent-picked rectangle may create production extraction regions. The owner draws polygon outlines in a game-owned HTML editor. Extraction can run only from owner-approved JSON.

## 4. World Art Before Runtime

For each gameplay-world asset, record:

- arena/world size
- camera viewport
- coverage mode
- source pixel size
- repeat/tile/stretch policy
- actor/projectile/pickup visual size
- screenshot proof at gameplay density

If source art is undersized and not tileable, mark missing art.

## 5. Asset Family Expansion

For each countable key, record:

- family
- semantic key
- runtime use
- PNG/source size
- SSOT size/metric
- core image quality profile and required source scale when the asset is UI art
- runtime path
- state variant
- proof path

Interactive controls must explicitly decide normal, hover, pressed, disabled, focus, selected, loading, and error states. If a state is not final art scope, record it as pending.

## 6. Runtime And Art Gates

Every screenshot row must separate:

- runtime fit status
- art design status
- owner approval status

`RUNTIME_FIT_PASS` proves fit only. It does not approve art design.

## 7. Mandatory Output

Every game art/UI pass leaves:

- updated count matrix
- updated coverage matrix
- updated composition contract
- updated screenshot checklist
- updated game style bible
- updated manual placement editor config/export when text or icon slot geometry changes
- updated tests
- passing core `validate_art_ui_gate.py`
- clear list of pending art-design surfaces
