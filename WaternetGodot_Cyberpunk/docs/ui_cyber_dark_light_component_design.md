# Cyber Dark/Light UI Component Design

Purpose: split the approved dark and light cyber mockups into reusable reference components and define how to generate production UI assets without treating demo images as final game assets.

## Source Decision

Owner decision on 2026-07-01:

- Keep both Trial A dark cyber and Trial D bright cyber.
- Build dark/light mode support.
- Trial A and Trial D are demo references only.
- Do not crop demo pixels into production assets.
- Use the demo crops as references for 9Router production generation.
- Production output must be object assets, not poster images.
- Generate isolated UI objects on transparent or removable plain background.
- Do not generate full-screen beauty compositions for production components.
- Every generated component must be usable as a Godot asset with known anchor, draw rect, and SSOT geometry.

## Reference Manifests

- Full reference pack: `docs/ui_cyber_reference_pack_r2.json`.
- Component crop reference pack: `docs/ui_cyber_dark_light_component_refs_r2.json`.
- Contact sheet: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-components/ui_dark_light_component_refs_contact_sheet.png`.

Local component refs:

- `Assets/UI/cyberpunk_theme/component_refs/dark/`.
- `Assets/UI/cyberpunk_theme/component_refs/light/`.

Reference-only components per mode:

- `full_demo_ref.png`.
- `top_tray_ref.png`.
- `top_tray_shell_ref.png`.
- `logo_socket_ref.png`.
- `floating_menu_ref.png`.
- `floating_replay_ref.png`.
- `board_region_ref.png`.
- `bottom_reserve_ref.png`.
- `background_depth_ref.png`.

## Shared Geometry

Dark and light modes must share the same canonical layout geometry.

Shared components:

- `background_full`.
- `top_tray_layer`.
- `stats_capsule`.
- `logo_socket`.
- `floating_menu_button`.
- `floating_replay_button`.
- `bottom_reserve_layer`.
- `modal_frame`.
- `board_backplate`.

Shared layout rules:

- Same portrait top region: 16% to 19% of viewport height.
- Same board region and square board sizing.
- Same bottom reserve height ratio.
- Same button anchors and touch target sizes.
- Same logo socket anchor.
- Same modal usable rect.

Mode-specific visuals:

- dark mode uses black/deep-green/cyan cockpit materials.
- light mode uses pearl white/pale mint/cyan lab materials.
- pipe sprites remain canonical in both modes.
- board tiles can be mode-specific only if contrast remains strong against fixed dark pipes.

## Component Production Plan

Generate each production component separately for dark and light after owner approves the component direction.

Production asset rule:

- Prompt for one object per image.
- Prefer transparent PNG when model supports it.
- If transparent output is not clean, use a flat single-color background and remove it with PhotoRoom.
- Object must be centered, fully visible, not cropped, no perspective mismatch.
- No decorative scene background, board, pipes, sample HUD, fake screenshot, or poster composition.
- No baked text, fake logos, characters, mascots, or extra gameplay pieces.
- Save production object only after background removal or alpha verification.

### 1. Background Full

Purpose:

- Full-screen visual depth behind board and UI.
- Must keep a quiet board zone.

Dark prompt direction:

- deep black-green cyber circuitry, subtle cyan depth, no bright clutter, no pipes.

Light prompt direction:

- luminous sci-fi lab glass, pale mint/white depth, board quiet zone, no flat white.

Production notes:

- Export portrait and landscape as separate production assets.
- Do not stretch portrait into landscape or landscape into portrait.
- Store crop policy and safe quiet zones in SSOT.
- Background is the only full-screen production image allowed.
- Background must still be functional game background, not poster art.

### 2. Top Tray Layer

Purpose:

- Main fake3D layer floating above gameplay.
- Can overflow visual bounds but not scene safe area.

Dark prompt direction:

- black graphite beveled cockpit bar, cyan edge light, dark green accents.

Light prompt direction:

- pearl white beveled cockpit bar, cyan glass light, graphite inset panels.

Production notes:

- Transparent PNG preferred.
- Use PhotoRoom for every non-background UI object cutout if 9Router outputs a background.
- Chroma-key cleanup is temporary preview only and cannot be production alpha.
- Place every object asset through SSOT before any text pass starts.
- Store pixel size, anchor, draw rect, padding, and overdraw in SSOT.
- Generate only the tray object, not the whole game screen.

### 3. Stats Capsule

Purpose:

- Small inner readout capsule inside top tray.
- Contains level/moves/best readouts through Godot text, not baked text.

Production notes:

- No readable text in image.
- Generate blank readout panels.
- Godot renders actual text/icons.
- Generate only the capsule object.

### 4. Logo Socket

Purpose:

- Center raised socket for real project logo.

Rules:

- No character, mascot, face, fake avatar, or invented logo.
- Dark Trial A logo socket is style reference only and rejected for production because it contains a mascot.
- Light Trial D logo socket is cleaner and preferred as shape reference.
- Production asset should be an empty socket. Godot inserts `res://Assets/Icons/logo.png`.
- Generate only the socket object.

### 5. Floating Buttons

Purpose:

- Purple menu button on left.
- Yellow replay button on right.

Production notes:

- Generate blank button shells or icon-safe button bases.
- Godot uses canonical icons for menu/replay.
- Required states: default, pressed, disabled, modal-blocked.
- Same dimensions across dark/light; mode may change bevel/glow.
- Generate one button object per state, not a screenshot with button in context.

### 6. Bottom Reserve Layer

Purpose:

- Future booster/ad/reward/progress reserve without redesigning board.

Production notes:

- Empty shell only in this pass.
- No baked text, no fake icons.
- Keep visual weight lower than top tray.
- Generate only the reserve shell object.

### 7. Modal Frame

Purpose:

- Settings, leaderboard, pause, and win modal shell.

Production notes:

- One framed panel per mode.
- Corner close slot, not full-row close.
- Godot renders content.
- Reuse top tray material language.
- Generate only the modal frame object.

### 8. Board Backplate

Purpose:

- Optional board support layer behind actual pipe cells.

Production notes:

- Must not include pipes.
- Must not replace canonical `cell_bg_texture` unless owner approves a new tile skin.
- For light mode, add enough dark edge/shadow so black pipes stay visible.
- Generate only a board support/backplate object, not a board screenshot.

## VFX Color Rules

Pipe sprite color:

- Do not recolor existing pipe sprites through UI generation.
- Pipe base assets stay black/dark graphite with silver rims.

Changeable VFX:

- Procedural live VFX colors are theme-driven through `ThemeConfig` and `Scripts/pipe_vfx_layer.gd`.
- Changeable: contact spark, trail, path wave, energy stream, target pulse, source emission, idle hum, disconnect decay, error spark, rotation spark, win burst, lightning modulation.

Not cleanly changeable:

- Static energy overlay sheets are PNG/atlas based.
- Exact hue changes require regenerating energy sheets or adding a future shader path.
- Current cyber pipe-body static overlay is disabled, but target energy overlay can still use baked sheet pixels.

Light mode recommendation:

- Use icy cyan/white-blue procedural VFX.
- Keep tiny lime glints only as accents.
- Avoid recoloring pipe sprites.

Dark mode recommendation:

- Keep cyan/green electric VFX stack.
- Retain current black/deep-green board contrast.

## 9Router Production Order

Generate in this order:

1. dark `background_full`.
2. light `background_full`.
3. dark `top_tray_layer`.
4. light `top_tray_layer`.
5. shared/dark/light `logo_socket`.
6. dark/light floating button bases.
7. dark/light bottom reserve.
8. dark/light modal frame.
9. optional board backplate.

Reason:

- Background and top tray set the style.
- Logo socket and buttons must match tray bevel/material.
- Modal and bottom reserve follow after material language is stable.

## Acceptance Gate

For each generated component:

- Must be generated from the same R2 reference pack plus the matching component crop reference.
- Must be an isolated object asset, not a poster/mockup/full-screen composition.
- Must have transparent background or a PhotoRoom-cleaned transparent output, except `background_full`.
- Must preserve shared geometry.
- Must contain no baked text.
- Must contain no generated characters.
- Must not include gameplay pipes unless it is a board/playboard reference only.
- Must have local path, R2 URL, pixel size, intended draw rect, anchor, and SSOT key recorded.
- Must pass visible screenshot audit in Godot before production approval.
