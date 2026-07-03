# Cyber Component Generation Checklist

Purpose: generate dark/light cyber gameplay UI as real Godot-ready asset objects, not poster art. Every item must use references for style synchronization and must record SSOT geometry before integration.

## Global Rules

- Use only `cx/gpt-5.5-image`.
- No fallback model or provider.
- Use R2 references from:
  - `docs/ui_cyber_reference_pack_r2.json`
  - `docs/ui_cyber_dark_light_component_refs_r2.json`
- Use canonical component queue:
  - `docs/ui_cyber_9router_component_call_queue.md`
- Use `docs/9router_ui_generation_runbook.md` for exact command shape.
- Demo images are references only.
- Production output is one isolated object per image.
- No poster, no full-screen mockup, no sample screenshot, no decorative composition.
- Transparent PNG preferred.
- If transparent output is not clean, use flat removable background and PhotoRoom.
- PhotoRoom is mandatory for every non-background UI object that needs transparency before it can be marked production-ready.
- Chroma-key cleanup is allowed only as a temporary debug candidate, never as final production alpha.
- Order is fixed: 9Router design, owner approval, PhotoRoom cutout, SSOT object placement, then text pass.
- Do not add or tune text until all object assets for that screen are placed and owner-approved.
- No baked text.
- No fake logo.
- No characters or mascots.
- No gameplay pipes inside UI components.
- `background_full` is the only allowed full-screen generated asset.

## Shared SSOT Fields To Record Per Asset

For each generated component record:

- `mode`: `dark` or `light`.
- `component_key`.
- `local_path`.
- `r2_url`.
- `pixel_size`.
- `sha256`.
- `anchor`.
- `draw_rect`.
- `content_padding`.
- `safe_overdraw`.
- `scale_policy`.
- `source_refs`.
- `prompt_path` or prompt text.
- `acceptance_status`.
- `reject_reason` if rejected.
- `background_removal_method`: must be `photoroom` for production cutouts.
- `edge_qa_status`: `pending`, `approved_dark_light_checkerboard`, or `rejected`.

## Mandatory Per-Object Pipeline Gate

Every non-background UI object must pass this gate in order. Future agents must not skip forward.

- [ ] 9Router design candidate uses approved R2 references and `cx/gpt-5.5-image`.
- [ ] Owner approves visual design candidate before production cutout work.
- [x] Run PhotoRoom on the approved object candidate for transparent production alpha.
- [x] QA PhotoRoom edges on dark, light, and checkerboard backgrounds.
- [x] Record `background_removal_method = photoroom` and `edge_qa_status = approved_dark_light_checkerboard`.
- [x] Place every object asset for the screen through SSOT geometry before adding text.
- [ ] Text pass starts only after owner approves all object placements.

Temporary magenta/chroma-key files are debug previews only. They can help owner review silhouette, but they cannot be final production assets and cannot unblock text placement.

## Production Order

Source of truth for generation calls:

- `docs/ui_cyber_9router_component_call_queue.md`.

Do not create a new prompt or asset outside that queue. If owner adds a UI component, extend the queue first with required refs, prompt additions, output paths, SSOT geometry fields, and audit gates.

### 1. Top Tray Layer

- [x] dark `top_tray_layer`: generate object asset.
- [x] dark `top_tray_layer`: verify isolated object, no poster.
- [x] dark `top_tray_layer`: create temporary magenta alpha candidate for preview only.
- [x] dark `top_tray_layer`: run PhotoRoom cutout before production approval.
- [x] dark `top_tray_layer`: edge QA on dark/light/checkerboard.
- [x] dark `top_tray_layer`: upload R2 and record metadata.
- [x] light `top_tray_layer`: generate object asset.
- [x] light `top_tray_layer`: verify isolated object, no poster.
- [x] light `top_tray_layer`: create temporary magenta alpha candidate for preview only.
- [x] light `top_tray_layer`: run PhotoRoom cutout before production approval.
- [x] light `top_tray_layer`: edge QA on dark/light/checkerboard.
- [x] light `top_tray_layer`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `top_tray_layer`.

References:

- full R2 style pack.
- dark/light `top_tray_ref`.
- dark/light `top_tray_shell_ref`.
- logo socket ref only for cutout/socket placement, not for mascot generation.

Prompt constraints:

- one isolated cockpit tray object only.
- no board, no pipes, no buttons, no background scene.
- blank readout areas only.
- centered, fully visible, alpha-friendly edges.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/top_tray_layer_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/top_tray_layer_alpha.png`.
- dark PhotoRoom local: `Assets/UI/cyberpunk_theme/generated/production/dark/top_tray_layer_photoroom.png`.
- dark PhotoRoom R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/top_tray_layer_photoroom.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/top_tray_layer_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/top_tray_layer_alpha.png`.
- light PhotoRoom local: `Assets/UI/cyberpunk_theme/generated/production/light/top_tray_layer_photoroom.png`.
- light PhotoRoom R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/top_tray_layer_photoroom.png`.
- preview local: `debug/top_tray_layer_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/top_tray_layer_alpha_preview.png`.
- manifest: `docs/ui_cyber_component_generation_manifest.json`.

Audit:

- Both outputs are isolated object assets, not posters.
- Both outputs have no baked text, no fake logo, no characters, no gameplay pipes.
- Model did not support transparent background, so generation used flat magenta and chroma-key preview cleanup. Final production alpha now uses PhotoRoom.
- PhotoRoom QA sheet: `debug/photoroom_cutout_edge_qa_preview.png`.
- PhotoRoom QC manifest: `debug/photoroom_cutout_qc.json`.

### 2. Logo Socket

- [x] dark `logo_socket`: generate empty socket object.
- [x] dark `logo_socket`: verify no character/fake logo.
- [x] dark `logo_socket`: upload R2 and record metadata.
- [x] light `logo_socket`: generate empty socket object.
- [x] light `logo_socket`: verify no character/fake logo.
- [x] light `logo_socket`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `logo_socket`.

References:

- light `logo_socket_ref` preferred for clean empty shape.
- project logo ref only for logo slot proportions.
- dark logo socket ref is rejected for character content; use material shape only.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/logo_socket_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/logo_socket_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/logo_socket_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/logo_socket_alpha.png`.
- preview local: `debug/logo_socket_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/logo_socket_dark_light_alpha_preview.png`.

### 3. Stats Capsule

- [x] dark `stats_capsule`: generate blank readout object.
- [x] dark `stats_capsule`: verify no baked text.
- [x] dark `stats_capsule`: upload R2 and record metadata.
- [x] light `stats_capsule`: generate blank readout object.
- [x] light `stats_capsule`: verify no baked text.
- [x] light `stats_capsule`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `stats_capsule`.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/stats_capsule_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/stats_capsule_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/stats_capsule_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/stats_capsule_alpha.png`.
- preview local: `debug/stats_capsule_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/stats_capsule_dark_light_alpha_preview.png`.

### 4. Floating Menu Button

- [x] dark `floating_menu_button_default`.
- [x] dark `floating_menu_button_pressed`.
- [x] dark `floating_menu_button_disabled`.
- [x] dark `floating_menu_button_modal_blocked`.
- [x] light `floating_menu_button_default`.
- [x] light `floating_menu_button_pressed`.
- [x] light `floating_menu_button_disabled`.
- [x] light `floating_menu_button_modal_blocked`.
- [ ] owner visual approval for dark/light `floating_menu_button` states.

Rules:

- Purple button base.
- No baked menu icon if Godot will render icon.
- If baked icon is requested later, icon must be canonical and consistent.

Generated outputs:

- dark/light state alpha files: `Assets/UI/cyberpunk_theme/generated/production/<mode>/floating_menu_button_<state>_alpha.png`.
- preview local: `debug/floating_menu_button_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/floating_menu_button_dark_light_alpha_preview.png`.

### 5. Floating Replay Button

- [x] dark `floating_replay_button_default`.
- [x] dark `floating_replay_button_pressed`.
- [x] dark `floating_replay_button_disabled`.
- [x] dark `floating_replay_button_modal_blocked`.
- [x] light `floating_replay_button_default`.
- [x] light `floating_replay_button_pressed`.
- [x] light `floating_replay_button_disabled`.
- [x] light `floating_replay_button_modal_blocked`.
- [ ] owner visual approval for dark/light `floating_replay_button` states.

Rules:

- Yellow button base.
- No baked replay icon if Godot will render icon.

Generated outputs:

- dark/light state alpha files: `Assets/UI/cyberpunk_theme/generated/production/<mode>/floating_replay_button_<state>_alpha.png`.
- preview local: `debug/floating_replay_button_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/floating_replay_button_dark_light_alpha_preview.png`.

### 6. Bottom Reserve Layer

- [x] dark `bottom_reserve_layer`.
- [x] light `bottom_reserve_layer`.
- [ ] owner visual approval for dark/light `bottom_reserve_layer`.

Rules:

- Empty shell only.
- No icons, no text.
- Lower visual weight than top tray.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/bottom_reserve_layer_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/bottom_reserve_layer_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/bottom_reserve_layer_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/bottom_reserve_layer_alpha.png`.
- preview local: `debug/bottom_reserve_layer_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/bottom_reserve_layer_dark_light_alpha_preview.png`.

### 7. Modal Frame

- [x] dark `modal_frame`.
- [x] light `modal_frame`.
- [ ] owner visual approval for dark/light `modal_frame`.

Rules:

- Isolated frame object.
- Corner close slot allowed.
- No content text.

Outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/modal_frame_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/modal_frame_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/modal_frame_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/modal_frame_alpha.png`.
- preview local: `debug/modal_frame_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/modal_frame_dark_light_alpha_preview.png`.

### 8. Board Backplate

- [x] dark `board_backplate`.
- [x] light `board_backplate`.
- [ ] owner visual approval for dark/light `board_backplate`.

Rules:

- No pipes.
- No cell sprites unless owner approves replacing board tile skin.
- Support contrast under existing black pipe sprites.

Outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/board_backplate_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/board_backplate_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/board_backplate_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/board_backplate_alpha.png`.
- preview local: `debug/board_backplate_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/board_backplate_dark_light_alpha_preview.png`.

### 9. Background Full

- [x] dark `background_full_portrait`.
- [x] light `background_full_portrait`.
- [x] dark `background_full_landscape`.
- [x] light `background_full_landscape`.
- [ ] owner visual approval for dark/light portrait/landscape backgrounds.

Rules:

- This is the only full-screen production image.
- Must be functional game background, not poster art.
- Must preserve quiet board zone.
- Must cover both portrait and landscape. Do not stretch one orientation into the other.

Generated outputs:

- dark portrait local: `Assets/UI/cyberpunk_theme/generated/production/dark/background_full_portrait.png`.
- dark portrait R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/background_full_portrait.png`.
- light portrait local: `Assets/UI/cyberpunk_theme/generated/production/light/background_full_portrait.png`.
- light portrait R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/background_full_portrait.png`.
- dark landscape local: `Assets/UI/cyberpunk_theme/generated/production/dark/background_full_landscape.png`.
- dark landscape R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/background_full_landscape.png`.
- light landscape local: `Assets/UI/cyberpunk_theme/generated/production/light/background_full_landscape.png`.
- light landscape R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/background_full_landscape.png`.
- preview local: `debug/background_full_dark_light_portrait_landscape_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/background_full_dark_light_portrait_landscape_preview.png`.

## 9Router Prompt Template

Use this template for all non-background components:

```text
Create one isolated production mobile game UI asset object, not a poster and not a full-screen mockup.
Asset: <component_key>.
Mode: <dark/light>.
Use the reference images only for material, bevel depth, glow color, proportion, and style synchronization.
Output only this single object, centered, fully visible, no crop, alpha-friendly edge, transparent background if possible or flat removable background.
No decorative scene background, no gameplay board, no pipes, no sample HUD, no fake screenshot.
No baked text, no fake logo, no characters, no mascot, no extra icon unless explicitly requested.
Keep geometry symmetrical and suitable for Godot placement with a known anchor/draw rect.
```

## Owner Gate

- Owner can approve/reject each component visually.
- Rejected components keep metadata and reject reason.
- Approved components move to SSOT asset geometry.
