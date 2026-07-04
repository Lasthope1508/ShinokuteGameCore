# Cyber 9Router Component Call Queue

Purpose: canonical queue for generating dark/light cyber GUI assets with synchronized R2 references. This is the step-by-step handoff for future agents.

## Non-Negotiables

- Use only `cx/gpt-5.5-image`.
- No fallback model, provider, style, or hand-drawn replacement.
- Verify `/v1/models/image` contains `cx/gpt-5.5-image` before every generation session.
- Use approved key order from `docs/9router_ui_generation_runbook.md`.
- Use R2 reference manifests on every call:
  - `docs/ui_cyber_reference_pack_r2.json`
  - `docs/ui_cyber_dark_light_component_refs_r2.json`
- Dark and light modes share canonical layout geometry.
- Trial A and Trial D are style references only, not production pixels.
- Production components are isolated object assets, except `background_full_portrait` and `background_full_landscape`.
- No poster, fake screenshot, sample HUD, baked text, fake logo, character, mascot, gameplay pipes, or board screenshot inside component assets.
- Every prompt must repeat the object-only rule.
- Prefer transparent PNG. If model rejects transparency, generate on flat `#ff00ff`, then run PhotoRoom for production alpha.
- Chroma-key cleanup is debug-only preview work. It is not a production background-removal method.
- Fixed production pipeline: 9Router design -> owner approval -> PhotoRoom cutout -> SSOT object placement -> text pass.
- Do not add or tune text until every object asset for the screen is PhotoRoom-cleaned, placed from SSOT, screenshot-audited, and owner-approved.
- Record raw output, alpha output, R2 URL, SHA256, pixel size, draw rect, anchor, padding, scale policy, prompt, source refs, and owner status.

## Shared Reference Set

Every component call must include:

- matching mode `full_demo_ref.png` for overall material language.
- matching mode component crop ref, when available.
- `current_cyber_gameplay.png` so pipe/board contrast stays readable.
- `project_logo.png` only for logo socket proportions. Do not ask model to invent logo.
- `cyber_cell_bg.png`, `cyber_pipe_i.png`, `cyber_pipe_l.png`, `cyber_pipe_t.png`, `cyber_pipe_x.png` only as gameplay scale/contrast refs. Do not put pipes into UI assets.
- `cyber_lightning_preview.png` for VFX tone, not as baked lightning unless component explicitly needs aura.

## Base Prompt Block

Use this exact block in every non-background prompt:

```text
Create one isolated production mobile game UI asset object, not a poster and not a full-screen mockup.
Use the reference images only for material, bevel depth, glow color, proportion, and style synchronization.
Output only this single object, centered, fully visible, uncropped, alpha-friendly edges.
Transparent background if supported; otherwise use a flat removable #ff00ff background.
No decorative scene background, no gameplay board, no pipes, no sample HUD, no fake screenshot.
No baked text, no fake logo, no characters, no mascot, no extra icon unless explicitly requested.
Keep geometry symmetrical and suitable for Godot placement through SSOT anchor/draw rect.
```

Use this exact block in `background_full_portrait` and `background_full_landscape` prompts:

```text
Create one portrait mobile game background asset for a cyber pipe puzzle, not a poster.
Keep a quiet center board zone with low visual noise and readable contrast for black graphite pipe sprites.
Use references for material, lighting, cyber tone, and gameplay scale.
No text, no logo, no character, no mascot, no pipes, no board cells, no sample HUD.
```

## Queue

### 0. Session Setup

- [ ] Run model check from `docs/9router_ui_generation_runbook.md`.
- [ ] Verify both R2 manifests exist.
- [ ] Verify first 3 R2 refs return `HTTP/1.1 200 OK`.
- [ ] Create output folders:
  - `Assets/UI/cyberpunk_theme/generated/production/dark/`
  - `Assets/UI/cyberpunk_theme/generated/production/light/`
  - `Assets/UI/cyberpunk_theme/generated/production/debug/`
- [ ] Open or update `docs/ui_cyber_component_generation_manifest.json`.

### 1. Background Full

- [x] dark `background_full_portrait`: call 9Router.
- [x] dark `background_full_portrait`: audit quiet board zone.
- [x] dark `background_full_portrait`: upload R2 and record metadata.
- [x] light `background_full_portrait`: call 9Router.
- [x] light `background_full_portrait`: audit quiet board zone.
- [x] light `background_full_portrait`: upload R2 and record metadata.
- [x] dark `background_full_landscape`: call 9Router.
- [x] dark `background_full_landscape`: audit quiet board zone.
- [x] dark `background_full_landscape`: upload R2 and record metadata.
- [x] light `background_full_landscape`: call 9Router.
- [x] light `background_full_landscape`: audit quiet board zone.
- [x] light `background_full_landscape`: upload R2 and record metadata.

Refs:

- mode `full_demo_ref.png`.
- mode `background_depth_ref.png`.
- current gameplay ref.
- cyber cell/pipe refs.
- lightning preview ref.

Mode prompt additions:

- dark: deep black-green cyber circuitry, cyan/green glow, cockpit depth, no clutter behind board.
- light: pearl white and pale mint sci-fi lab depth, icy cyan glow, not flat white, strong pipe readability.

Export targets:

- `background_full_portrait`: `1024x1792`, used for portrait phones and portrait tablets.
- `background_full_landscape`: `1792x1024`, used for landscape phones, landscape tablets, desktop, and browser windows.
- Do not stretch portrait into landscape or landscape into portrait. Use mode/orientation asset selection in SSOT.

### 2. Top Tray Layer

- [x] dark `top_tray_layer`: call 9Router.
- [x] dark `top_tray_layer`: create temporary alpha preview.
- [x] dark `top_tray_layer`: run PhotoRoom production cutout.
- [x] dark `top_tray_layer`: pass dark/light/checkerboard edge QA.
- [x] dark `top_tray_layer`: upload R2 and record metadata.
- [x] light `top_tray_layer`: call 9Router.
- [x] light `top_tray_layer`: create temporary alpha preview.
- [x] light `top_tray_layer`: run PhotoRoom production cutout.
- [x] light `top_tray_layer`: pass dark/light/checkerboard edge QA.
- [x] light `top_tray_layer`: upload R2 and record metadata.
- [ ] owner visual approval for both modes.

Refs:

- mode `full_demo_ref.png`.
- mode `top_tray_ref.png`.
- mode `top_tray_shell_ref.png`.
- current gameplay ref.
- logo socket ref for center cutout placement only.

### 3. Logo Socket

- [x] dark `logo_socket`: call 9Router.
- [x] dark `logo_socket`: create temporary alpha preview.
- [x] dark `logo_socket`: reject if character/fake logo appears.
- [x] dark `logo_socket`: upload R2 and record metadata.
- [x] light `logo_socket`: call 9Router.
- [x] light `logo_socket`: create temporary alpha preview.
- [x] light `logo_socket`: reject if character/fake logo appears.
- [x] light `logo_socket`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `logo_socket`.

Refs:

- light `logo_socket_ref.png` for clean empty shape.
- dark `logo_socket_ref.png` for material only. Ignore mascot content.
- `project_logo.png` for slot ratio only.
- mode `top_tray_layer_alpha.png` when approved.

Prompt additions:

- Empty raised socket only.
- Center hole or inset designed to hold real project logo rendered by Godot.
- No symbol, no face, no invented icon.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/logo_socket_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/logo_socket_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/logo_socket_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/logo_socket_alpha.png`.
- preview local: `debug/logo_socket_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/logo_socket_dark_light_alpha_preview.png`.

Audit:

- Both outputs are empty socket assets with no baked logo, no text, no mascot, and no character.
- Model used flat magenta background; current alpha files are temporary chroma-key previews until PhotoRoom production cutouts replace them.
- Dark mode required regeneration because first wide attempt included too much top-tray context.

### 4. Stats Capsule

- [x] dark `stats_capsule`: call 9Router.
- [x] dark `stats_capsule`: create temporary alpha preview.
- [x] dark `stats_capsule`: reject if text appears.
- [x] dark `stats_capsule`: upload R2 and record metadata.
- [x] light `stats_capsule`: call 9Router.
- [x] light `stats_capsule`: create temporary alpha preview.
- [x] light `stats_capsule`: reject if text appears.
- [x] light `stats_capsule`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `stats_capsule`.

Refs:

- mode `top_tray_ref.png`.
- mode `top_tray_shell_ref.png`.
- approved `top_tray_layer`.

Prompt additions:

- Blank readout capsule with three inner zones for Godot text/icons.
- No digits, no labels, no fake avatar.

Generated outputs:

- dark local: `Assets/UI/cyberpunk_theme/generated/production/dark/stats_capsule_alpha.png`.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/stats_capsule_alpha.png`.
- light local: `Assets/UI/cyberpunk_theme/generated/production/light/stats_capsule_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/stats_capsule_alpha.png`.
- preview local: `debug/stats_capsule_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/stats_capsule_dark_light_alpha_preview.png`.

Audit:

- Both outputs are blank 3-zone readout assets with no text, no digits, no labels, no icons, and no avatar.
- Model used flat magenta background; current alpha files are temporary chroma-key previews until PhotoRoom production cutouts replace them.

### 5. Floating Menu Button

- [x] dark `floating_menu_button_default`: call 9Router.
- [x] dark `floating_menu_button_pressed`: call 9Router.
- [x] dark `floating_menu_button_disabled`: call 9Router.
- [x] dark `floating_menu_button_modal_blocked`: call 9Router.
- [x] light `floating_menu_button_default`: call 9Router.
- [x] light `floating_menu_button_pressed`: call 9Router.
- [x] light `floating_menu_button_disabled`: call 9Router.
- [x] light `floating_menu_button_modal_blocked`: call 9Router.
- [x] all menu button states: create temporary alpha previews, upload R2, record metadata.
- [x] default dark/light `floating_menu_button` regenerated as PhotoRoom-cleaned baked-icon assets.
- [ ] non-default menu button states must be regenerated with baked icons before runtime use.

Refs:

- mode `floating_menu_ref.png`.
- approved mode `top_tray_layer`.

Prompt additions:

- Purple floating settings button with centered gear/settings icon baked into the PNG.
- Runtime must not create `GeneratedButtonIcon` overlay for current cyber buttons.
- Keep same silhouette and size across all states.
- Pressed state lower/deeper shadow, disabled state dim/desaturated, modal-blocked state muted shield-like glow.

Generated outputs:

- dark default R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_menu_button_default_alpha.png`.
- dark pressed R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_menu_button_pressed_alpha.png`.
- dark disabled R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_menu_button_disabled_alpha.png`.
- dark modal-blocked R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_menu_button_modal_blocked_alpha.png`.
- light default R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_menu_button_default_alpha.png`.
- light pressed R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_menu_button_pressed_alpha.png`.
- light disabled R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_menu_button_disabled_alpha.png`.
- light modal-blocked R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_menu_button_modal_blocked_alpha.png`.
- preview local: `debug/floating_menu_button_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/floating_menu_button_dark_light_alpha_preview.png`.

Audit:

- Current runtime default outputs are baked-icon PhotoRoom assets with no text, no logo, and no mascot.
- Older shell-only state outputs are source/archive candidates only until regenerated with baked icons.

### 6. Floating Replay Button

- [x] dark `floating_replay_button_default`: call 9Router.
- [x] dark `floating_replay_button_pressed`: call 9Router.
- [x] dark `floating_replay_button_disabled`: call 9Router.
- [x] dark `floating_replay_button_modal_blocked`: call 9Router.
- [x] light `floating_replay_button_default`: call 9Router.
- [x] light `floating_replay_button_pressed`: call 9Router.
- [x] light `floating_replay_button_disabled`: call 9Router.
- [x] light `floating_replay_button_modal_blocked`: call 9Router.
- [x] all replay button states: create temporary alpha previews, upload R2, record metadata.
- [x] default dark/light `floating_replay_button` regenerated as PhotoRoom-cleaned baked-icon assets.
- [ ] non-default replay button states must be regenerated with baked icons before runtime use.

Refs:

- mode `floating_replay_ref.png`.
- approved mode `top_tray_layer`.

Prompt additions:

- Yellow floating replay button with centered replay arrow icon baked into the PNG.
- Runtime must not create `GeneratedButtonIcon` overlay for current cyber buttons.
- Keep same silhouette and size across all states.

Generated outputs:

- dark default R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_replay_button_default_alpha.png`.
- dark pressed R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_replay_button_pressed_alpha.png`.
- dark disabled R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_replay_button_disabled_alpha.png`.
- dark modal-blocked R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/floating_replay_button_modal_blocked_alpha.png`.
- light default R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_replay_button_default_alpha.png`.
- light pressed R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_replay_button_pressed_alpha.png`.
- light disabled R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_replay_button_disabled_alpha.png`.
- light modal-blocked R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/floating_replay_button_modal_blocked_alpha.png`.
- preview local: `debug/floating_replay_button_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/floating_replay_button_dark_light_alpha_preview.png`.

Audit:

- All outputs are button-shell assets with no baked replay icon, no arrow, no text, no logo, and no mascot.
- Light pressed/default required regeneration because first pass was clipped or too small in raw preview.
- Model used flat magenta background; current alpha files are temporary connected-edge chroma-key previews until PhotoRoom production cutouts replace them.

### 7. Bottom Tray Layer

- [x] dark `bottom_reserve_layer`: legacy reserve strip already generated.
- [x] light `bottom_reserve_layer`: legacy reserve strip already generated.
- [x] dark `bottom_tray_layer`: call 9Router.
- [x] dark `bottom_tray_layer`: visual audit against top tray stack.
- [x] light `bottom_tray_layer`: call 9Router.
- [x] light `bottom_tray_layer`: visual audit against top tray stack.
- [x] owner visual approval for dark/light `bottom_tray_layer`.
- [x] After owner approval, run PhotoRoom production cutout and replace or alias runtime `bottom_reserve_layer` through SSOT.

Refs:

- mode `bottom_reserve_ref.png`.
- mode `full_demo_ref.png`.
- approved top tray for material matching.
- mode `top_tray_ref.png` and `top_tray_shell_ref.png` for layer depth language.

Prompt additions:

- Empty lower tray shell only, acting as the real bottom tray visual layer.
- Lower visual weight than top tray.
- No icons, no text, no booster art.
- Slightly wider and flatter than top tray, built for future booster/ad/progress slots.
- Must read as a fake3D layer floating above the background, not a closed card and not a poster.

Generated outputs:

- dark candidate local: `Assets/UI/cyberpunk_theme/generated/production/dark/bottom_tray_layer_raw.png`.
- light candidate local: `Assets/UI/cyberpunk_theme/generated/production/light/bottom_tray_layer_raw.png`.
- dark PhotoRoom local: `Assets/UI/cyberpunk_theme/generated/production/dark/bottom_tray_layer_photoroom.png`.
- dark PhotoRoom R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/bottom_tray_layer_photoroom.png`.
- light PhotoRoom local: `Assets/UI/cyberpunk_theme/generated/production/light/bottom_tray_layer_photoroom.png`.
- light PhotoRoom R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/bottom_tray_layer_photoroom.png`.
- preview local: `debug/bottom_tray_layer_dark_light_candidate_preview.png`.

Audit:

- Candidate must be a bottom tray asset, not just a reserve placeholder.
- Candidate must have no text, no logo, no booster art, no gameplay pipes, and no sample HUD.
- Candidate must not duplicate top tray. It should echo the same material family but stay visually secondary.
- PhotoRoom production cutouts passed alpha QA with transparent/opaque extrema and are recorded in `docs/ui_cyber_component_generation_manifest.json`.

### 8. Modal Frame

- [x] dark `modal_frame`: call 9Router.
- [x] dark `modal_frame`: create temporary alpha preview.
- [x] dark `modal_frame`: upload R2 and record metadata.
- [x] light `modal_frame`: call 9Router.
- [x] light `modal_frame`: create temporary alpha preview.
- [x] light `modal_frame`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `modal_frame`.

Refs:

- approved top tray.
- approved stats capsule.
- mode `full_demo_ref.png`.

Prompt additions:

- Empty modal shell with corner close slot only.
- No full-row close button.
- No title, no settings labels, no leaderboard rows.

Generation notes:

- Model used flat magenta background; current alpha files are temporary connected-edge chroma-key previews until PhotoRoom production cutouts replace them.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/modal_frame_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/modal_frame_alpha.png`.
- preview local: `debug/modal_frame_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/modal_frame_dark_light_alpha_preview.png`.

### 9. Board Backplate

- [x] dark `board_backplate`: call 9Router.
- [x] dark `board_backplate`: create temporary alpha preview.
- [x] dark `board_backplate`: upload R2 and record metadata.
- [x] light `board_backplate`: call 9Router.
- [x] light `board_backplate`: create temporary alpha preview.
- [x] light `board_backplate`: upload R2 and record metadata.
- [ ] owner visual approval for dark/light `board_backplate`.

Refs:

- mode `board_region_ref.png`.
- current gameplay ref.
- cyber cell/pipe refs.

Prompt additions:

- Board support frame/backplate only.
- No actual cells, no pipes, no solved-path markings.
- Must improve contrast behind existing canonical cells.

Generation notes:

- Model used flat magenta background; current alpha files are temporary connected-edge chroma-key previews until PhotoRoom production cutouts replace them.
- dark R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/dark/board_backplate_alpha.png`.
- light R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/light/board_backplate_alpha.png`.
- preview local: `debug/board_backplate_dark_light_alpha_preview.png`.
- preview R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/board_backplate_dark_light_alpha_preview.png`.

## Per-Asset Audit

For every generated asset:

- [ ] Image opens and is not blank.
- [ ] Correct mode tone.
- [ ] Uses same material language as approved mode refs.
- [ ] Object is centered and fully visible.
- [ ] No text/logo/mascot/character/pipe contamination.
- [ ] Production alpha comes from PhotoRoom for every non-background object.
- [ ] Chroma-key preview files are marked temporary and never approved as final.
- [ ] Alpha edge is approved on dark, light, and checkerboard backgrounds.
- [ ] Pixel size recorded.
- [ ] SHA256 recorded.
- [ ] R2 URL recorded.
- [ ] SSOT geometry fields recorded before Godot integration.
- [ ] Owner status recorded: `pending_owner_visual_approval`, `approved`, or `rejected`.

## Godot Integration Gate

Do not wire asset into scene until:

- owner approves visual candidate.
- manifest has complete metadata.
- every non-background object has a PhotoRoom production cutout.
- edge QA is approved on dark, light, and checkerboard backgrounds.
- `ThemeConfig` or canonical UI asset resource owns geometry.
- every object asset for the screen is placed through SSOT before text work starts.
- visual screenshot proves scale and alignment.
- docs tests pass.

## PhotoRoom Cutout Pass

- [x] Generated 28 PhotoRoom production cutouts for every dark/light non-background UI object.
- [x] Uploaded 28 PhotoRoom production cutouts to R2.
- [x] Updated `docs/ui_cyber_component_generation_manifest.json` with `background_removal_method = photoroom`.
- [x] Updated `Resources/Data/Themes/cyberpunk_theme.tres` runtime paths from `_alpha.png` preview assets to `_photoroom.png` production cutouts.
- [x] Recomputed runtime `alpha_bbox` from PhotoRoom alpha channels.
- [x] Saved QA sheet: `debug/photoroom_cutout_edge_qa_preview.png`.
- [x] Saved QA manifest: `debug/photoroom_cutout_qc.json`.

## SSOT Object Placement Pass

- [x] Attached top tray shell from `GeneratedTopTrayLayer` using `ThemeConfig.ui_generated_asset_paths`.
- [x] Kept `stats_capsule` and `logo_socket` as optional library assets; current `ThemeConfig.ui_top_tray_art_stack` renders `top_tray_layer` only.
- [x] Placed `LogoCore` with the real trimmed project logo from owner-approved `ThemeConfig.ui_top_tray_regions.logo_core`.
- [x] Kept top tray text absent; text pass remains blocked until owner approves object placement screenshots.
- [x] Placed menu, replay, and real logo controls from `ThemeConfig.ui_top_tray_regions`, not scene offsets.
- [x] Runtime object cropping uses PhotoRoom `alpha_bbox` metadata from `ThemeConfig.ui_generated_asset_geometry`.
- [x] Captured dark/light portrait/landscape layout screenshots in `debug/generated_ui_layout_*`.
- [ ] Owner visual approval for object placement before any logo/text tuning.
