# Gameplay UI Layout Checklist

Purpose: keep the cyber gameplay UI pass ordered, owner-approved, and reusable for later skins. No manual Godot tweaking before layout, assets, and SSOT are approved.

## B1. Responsive Frame

- [x] Owner approved B1 on 2026-07-01.
- [x] Board remains the primary visual area.
- [x] Current gameplay board scales from 5x5 to 10x10.
- [x] Source position remains top-left and target position remains bottom-right.
- [x] Source and target can rotate; layout must not block endpoint interaction.
- [x] Screen-level layout SSOT audit added: `test_screen_layout_ssot.gd`.
- [x] Level select grid, pagination, and back button are centered from layout containers and `ThemeConfig` values, not manual coordinates.
- [x] Level select button font size, locked alpha, pagination button width, and grid gaps live in `ThemeConfig`.
- [x] Main menu secondary button height, modal close padding, and profile popup score font size live in `ThemeConfig`.
- [x] Main menu title/subtitle/button/copyright typography, menu gap, and logo size live in `ThemeConfig`.
- [x] Level select title typography, container gap, and pagination gap live in `ThemeConfig`.
- [x] Splash typography, layout gap, margins, colors, and animation timing are applied from `ThemeConfig`; missing theme is an error, not a fallback.
- [x] Settings, solved, and profile modal content margins/gaps live in `ThemeConfig`.
- [x] Rule: screen layout scenes may keep placeholder `.tscn` defaults for editor visibility, but runtime sizing/alignment must be applied from `ThemeConfig` or a canonical layout resource.
- [x] VFX needs breathing room around the board for aura, lightning, glow, and fake3D shadows.
- [x] Current prototype tray and stripe background are not production reference.

Approved B1 geometry model:

- Portrait top region: 16% to 19% of viewport height.
- Portrait board region: 58% to 64% of viewport height after top tray and gap.
- Portrait bottom region: 10% to 14% of viewport height reserved even if initially empty.
- Landscape top region: 13% to 16% of viewport height.
- Board square size: min(available width, available board height).
- Board overdraw guard: proportional to cell size, not fixed pixels.
- Modal usable rect: centered, safe-area aware, capped by viewport ratios.

Required B1 SSOT fields:

- `ui_safe_padding_min`
- `ui_safe_padding_ratio`
- `ui_top_region_height_ratio`
- `ui_top_region_min_height`
- `ui_top_region_max_height`
- `ui_board_region_gap`
- `ui_board_overdraw_cell_ratio`
- `ui_bottom_region_height_ratio`
- `ui_modal_width_ratio`
- `ui_modal_height_ratio`
- `ui_breakpoint_small_phone`
- `ui_breakpoint_normal_phone`
- `ui_breakpoint_tablet`
- `ui_breakpoint_landscape_ratio`

Implementation rule:

- Store region ratios, min/max sizes, and safe-area rules in `ThemeConfig` or a canonical UI layout resource.
- Scene nodes define semantic hierarchy only.
- Do not store production dimensions only in node offsets.

## B2. Owner Layout Gate

- [x] Owner approved B2 on 2026-07-01.
- [x] Confirm gameplay screen regions.
- [x] Confirm top tray contents.
- [x] Confirm bottom tray contents or empty reserve.
- [x] Confirm floating controls.
- [x] Confirm required modals.
- [x] Confirm monetization reserve.

Approved B2 region model:

- Top tray exists as a fake3D layer above gameplay.
- Top tray contains logo center, stat capsule, and gameplay readouts.
- Bottom tray keeps an empty reserve for future booster, ad, reward, or progress UI.
- Floating controls: purple menu on the left, yellow replay on the right.
- Required modals for this pass: settings, leaderboard, pause, and win.
- Fail, shop, and reward modals are out of this pass unless owner expands scope.
- Monetization reserve exists only as bottom layout space in this pass; no ad implementation yet.

Do not start B3 asset generation until background direction is approved.

## B3. Background Asset

- [ ] Confirm mood and depth style.
- [ ] Confirm quiet zone behind board.
- [ ] Confirm crop rules for portrait and landscape.
- [x] Build a reference pack before generation.
- [x] Upload reference pack to R2 for 9Router reference usage.
- [x] Draft style trials for owner to choose the main style.
- [x] Use the same style anchor for every generated UI/background asset.
- [x] Generate Trial A full-screen style mockup through 9Router.
- [x] Upload Trial A mockup to R2.
- [x] Record Trial A metadata and visual audit notes.
- [x] Generate Trial D bright cyber mockup through 9Router.
- [x] Upload Trial D mockup to R2.
- [x] Record VFX color constraints for bright cyber.
- [x] Accept both dark and light cyber directions as mode references.
- [x] Crop dark/light component references from demo mockups.
- [x] Upload dark/light component references to R2.
- [x] Write dark/light component design and production order.
- [x] Lock production component rule: object assets only, no poster/mockup output.
- [x] Create per-component generation checklist.
- [x] Generate dark/light `top_tray_layer` object candidates.
- [x] Create temporary magenta alpha candidates for `top_tray_layer`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `top_tray_layer` dark/light.
- [x] Upload PhotoRoom `top_tray_layer` cutouts to R2 and record generation manifest.
- [x] Upload `top_tray_layer` candidates to R2 and record generation manifest.
- [x] Write canonical 9Router component call queue for dark/light GUI assets.
- [x] Lock rule: every production GUI component call must use R2 refs for style sync.
- [x] Lock rule: future agents must extend the queue before generating new GUI parts.
- [x] Lock rule: background assets require both portrait and landscape outputs.
- [x] Lock rule: UI asset pipeline order is 9Router design -> owner approval -> PhotoRoom cutout -> SSOT object placement -> text pass.
- [x] Lock rule: chroma-key cleanup is debug-only and cannot be accepted as production alpha for UI object assets.
- [x] Lock rule: no top tray/stat/modal text may be added until every object asset for that screen is placed and owner-approved.
- [x] Generate dark/light `background_full_portrait` candidates.
- [x] Generate dark/light `background_full_landscape` candidates.
- [x] Upload background candidates to R2 and record generation manifest.
- [x] Create dark/light portrait/landscape background preview sheet for owner approval.
- [x] Generate dark/light `logo_socket` candidates.
- [x] Create temporary magenta alpha candidates for `logo_socket`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `logo_socket` dark/light.
- [x] Upload `logo_socket` candidates to R2 and record generation manifest.
- [x] Generate dark/light `stats_capsule` candidates.
- [x] Create temporary magenta alpha candidates for `stats_capsule`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `stats_capsule` dark/light.
- [x] Upload `stats_capsule` candidates to R2 and record generation manifest.
- [x] Generate dark/light `floating_menu_button` state candidates.
- [x] Create temporary magenta alpha candidates for `floating_menu_button`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for all `floating_menu_button` dark/light states.
- [x] Upload `floating_menu_button` states to R2 and record generation manifest.
- [x] Generate dark/light `floating_replay_button` state candidates.
- [x] Create temporary magenta alpha candidates for `floating_replay_button`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for all `floating_replay_button` dark/light states.
- [x] Upload `floating_replay_button` states to R2 and record generation manifest.
- [x] Generate dark/light `bottom_reserve_layer` candidates.
- [x] Create temporary magenta alpha candidates for `bottom_reserve_layer`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `bottom_reserve_layer` dark/light.
- [x] Upload `bottom_reserve_layer` candidates to R2 and record generation manifest.
- [x] Clarified that `bottom_reserve_layer` is legacy reserve art, not the finished bottom tray design.
- [x] Added canonical `bottom_tray_layer` queue item for the real bottom tray visual layer.
- [x] Generated dark/light `bottom_tray_layer` 9Router raw design candidates with approved R2 references.
- [x] Owner visually approved dark/light `bottom_tray_layer` candidates.
- [x] Run PhotoRoom on approved `bottom_tray_layer` candidates before any Godot integration.
- [x] Add approved `bottom_tray_layer` to theme SSOT and alias it to runtime `bottom_reserve_layer` through `ThemeConfig.ui_generated_asset_paths`.
- [x] Recompute bottom tray `alpha_bbox` values in `ThemeConfig.ui_generated_asset_geometry`.
- [x] Upload `bottom_tray_layer` PhotoRoom cutouts and QA sheet to R2.
- [x] Generate dark/light `modal_frame` candidates.
- [x] Create temporary magenta alpha candidates for `modal_frame`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `modal_frame` dark/light.
- [x] Upload `modal_frame` candidates to R2 and record generation manifest.
- [x] Generate dark/light `board_backplate` candidates.
- [x] Create temporary magenta alpha candidates for `board_backplate`; production replacement must go through PhotoRoom before final approval.
- [x] Run PhotoRoom production cutouts for `board_backplate` dark/light.
- [x] Upload `board_backplate` candidates to R2 and record generation manifest.
- [ ] Generate through 9Router only after approval.
- [x] Store prompt, model, references, output path, and crop notes.
- [x] Store generated UI asset paths in `ThemeConfig.ui_generated_asset_paths`.
- [x] Store generated UI asset anchors and scale policies in `ThemeConfig.ui_generated_asset_geometry`.
- [x] Store generated UI object alpha bounding boxes in `ThemeConfig.ui_generated_asset_geometry[*].alpha_bbox` so runtime places the real object area, not transparent canvas padding.
- [x] Add `ThemeConfig.validate_ui_generated_assets()` for canonical generated UI asset validation.
- [x] Add GameScene generated UI hooks for background, top tray, logo socket, stats capsule, floating buttons, bottom reserve, modal frame, and board backplate.
- [x] Wire `bottom_reserve_layer` as a semantic HUD node and place it from SSOT bottom reserve ratios.
- [x] Move `TopTrayLayer` to non-container `Panel` so anchored floating buttons do not expand across the tray.
- [x] Reserve center stats slot for logo socket; left label owns level/moves, right label owns best.
- [x] Render only one generated top tray shell; `StatsCapsule` is a transparent layout control, and `LogoCore` renders the real project logo from the owner-approved `logo_core` region.
- [x] Store optional `GeneratedStatsCapsule` and `GeneratedLogoSocket` as library assets, but keep them inactive in current cyber top tray stack.
- [x] Generated UI object assets are the primary visuals; legacy Godot panel/button styleboxes are transparent hitboxes only when matching generated assets exist.
- [x] Store normalized top tray sub-regions in `ThemeConfig.ui_top_tray_regions`; use them only for controls/readouts, not full-tray art stack components.
- [x] Runtime top tray region placement uses the settled control size when available and falls back to `TopTrayRoot.custom_minimum_size` so SSOT placement works before Godot containers finish layout.
- [x] Top tray region coordinate SSOT: `docs/ui_top_tray_region_ssot.md`.
- [x] GameScene wraps generated object PNGs in `AtlasTexture` regions from SSOT `alpha_bbox`; full-source exceptions are explicitly marked by `runtime_region = "full_source"`.
- [x] Owner-approved floating menu/replay button placement uses full PhotoRoom PNG source in runtime, matching the drag editor preview; their `alpha_bbox` is audit metadata only.
- [x] Settings modal uses generated `modal_frame` as the visual shell; `SettingsOverlay` is a non-container `Panel` so anchored close/content controls cannot expand into a full-row or full-panel icon.
- [x] Store modal portrait/landscape size ratios in ThemeConfig and place modal rect from viewport ratios.
- [x] Modal frame currently uses SSOT `runtime_stretch_mode = "scale"` until a real 9-slice/sliced modal frame pass is implemented.
- [x] Leaderboard/Profile popup uses generated `modal_frame`, non-container root, corner close button, and GameScene injects active theme/mode before display.
- [x] Solved/win popup uses generated `modal_frame`, non-container root, and modal rect from the same ThemeConfig portrait/landscape ratios as settings and leaderboard.
- [x] Store top tray stat slot ratios and font size in ThemeConfig so logo clearance and readout typography scale without per-scene magic numbers.
- [x] Store HUD margins in theme SSOT with `ui_hud_margin_*`.
- [x] Store landscape top spacing in `game_landscape_top_margin` to prevent tray/button overlap with board.
- [x] Capture portrait and landscape generated UI layout screenshots.
- [x] Capture dark portrait, dark landscape, light portrait, and light landscape generated UI layout screenshots.
- [x] Capture dark/light portrait/landscape settings modal screenshots.
- [x] Capture dark/light portrait/landscape leaderboard modal screenshots.
- [x] Capture dark/light portrait/landscape solved/win modal screenshots.
- [x] Store final asset path in theme SSOT.

Current production caveat:

- [x] Replace temporary chroma-key alpha UI object assets with PhotoRoom-cleaned production cutouts before final UI approval.
- [x] Re-audit PhotoRoom edges on dark background, light background, and checkerboard.
- [x] Re-place all PhotoRoom object assets through SSOT before any text pass resumes.
- [x] Top tray object-placement pass: current cyber `ui_top_tray_art_stack` renders `GeneratedTopTrayLayer` only; menu button, replay button, and bottom reserve are attached from SSOT-controlled PhotoRoom assets.
- [x] Top tray art stack rule: active top tray art components share the full `TopTrayLayer` rect; `ui_top_tray_regions` is for menu/replay/readout/logo control ownership only.
- [x] Floating button shell/icon split: generated menu/replay button PNGs are shells; symbols come from `ThemeConfig.ui_top_tray_button_icon_paths` and explicit `_icon` regions in `ThemeConfig.ui_top_tray_regions`.
- [x] Top tray placement editors must use clean production object assets as the coordinate basis, never runtime screenshots with baked stat text or gameplay UI overlays.
- [x] Top tray mode split: dark and light use `ThemeConfig.ui_top_tray_region_sets` because their generated top tray source canvases have different aspect ratios.
- [x] Owner-provided light portrait top tray coordinates stored in `ThemeConfig.ui_top_tray_region_sets.light`; dark final coordinates remain the legacy fallback in `ThemeConfig.ui_top_tray_regions`.
- [x] Floating button icon regions must align to the visible shell alpha center or owner-approved `_icon` region; never auto-center icons against the full square button PNG canvas.
- [x] Owner visual approved menu, replay, and logo top tray placement before text pass starts.
- [x] Owner approved `total_play_time_readout = Vector4(0.6687, 0.3494, 0.1843, 0.1843)` for elapsed level time.
- [x] Top tray elapsed time uses SSOT `ThemeConfig.ui_top_tray_time_*` typography: Poppins Bold, energy-green text, dark outline, cyan-green shadow.
- [x] Runtime freezes elapsed top tray time when the level is solved, so it records total time from level start to finish.
- [x] Runtime treats `total_play_time_readout` as a hard clipping region: `TotalPlayTimeLabel.clip_contents = true`, and font fitting subtracts padding, outline, and shadow bleed.
- [x] `TotalPlayTimeLabel` layout is two rows: elapsed time on top, current round moves on bottom, right-aligned inside the owner region.
- [x] `LeftStatsLabel` uses `left_stats_readout`: username on top, best wave on bottom, left-aligned and clipped/fitted by the same SSOT typography rules.
- [x] Create light landscape playboard context editor with approved top tray and bottom tray fixed, and only `board_backplate_rect` draggable/resizable over the middle gameplay area.
- [x] Editor separates owner-adjusted `board_backplate_rect` from derived inner `playboard_rect`; do not mix art placement and gameplay grid placement in one ambiguous box.
- [x] Extend playboard context editor so light landscape menu/replay icon regions are draggable/resizable in the same scene; icon boxes have no text labels and output top-tray-source coordinates.
- [x] Icon preview uses aspect-preserving contain draw so coordinate boxes do not visually stretch `menuList.png` or `return.png`.
- [x] Owner approved light landscape `board_backplate_rect = Vector4(0.319277, 0.210843, 0.350699, 0.623465)`.
- [x] Owner approved light landscape `playboard_rect = Vector4(0.329825, 0.229594, 0.329604, 0.585963)`.
- [x] Owner approved light top tray icon regions: `left_floating_menu_icon = Vector4(0.163958, 0.849153, 0.035616, 0.092832)`, `right_floating_replay_icon = Vector4(0.798786, 0.850601, 0.036816, 0.091968)`.
- [x] Store light landscape playboard placement in `ThemeConfig.ui_playboard_region_sets.light.landscape`; runtime falls back to dynamic layout when a mode/orientation is absent.
- [x] Generate owner drag editors for all gameplay playboard contexts: `debug/ui_dark_portrait_playboard_editor.html`, `debug/ui_dark_landscape_playboard_editor.html`, `debug/ui_light_portrait_playboard_editor.html`, and `debug/ui_light_landscape_playboard_editor.html`.
- [x] Add `debug/ui_playboard_editor_index.html` as the owner handoff page for dark/light portrait/landscape playboard coordinate picking.
- [x] Owner approved all four playboard contexts on 2026-07-03; store dark/light portrait/landscape `board_backplate_rect` and `playboard_rect` in `ThemeConfig.ui_playboard_region_sets`.
- [x] Store playboard source sizes for portrait `Vector2(720, 1280)` and landscape `Vector2(1280, 720)`, plus pixel audit rects in `ThemeConfig.ui_playboard_region_pixel_rect_sets`.
- [x] Packaging audit nudged dark landscape `board_backplate_rect` and `playboard_rect` down by 13px to satisfy `ui_landscape_board_top_tray_gap = 24` against visible top tray icons while preserving approved size and x placement.
- [x] Keep playboard editor visual simple: only the yellow `board_backplate_rect` is visible/draggable; hidden `playboard_rect` scales with it and remains in exported SSOT output.
- [x] Brighten cyber dry pipes through theme-owned values only: `pipe_dry_modulate = Color(0.32, 0.34, 0.34, 1)` and `pipe_shadow_alpha = 0.22`; do not edit pipe PNGs for this pass.
- [x] Generate first-pass 9Router owner-review candidates for dark/light empty gameplay cell tiles; candidates live in `debug/gameplay_tile_candidates/`.
- [x] Owner rejected first-pass gameplay tile candidates as boring/button-like; do not reuse this direction for production tile art.
- [x] Generate second-pass 9Router candidates with stronger art direction: fake3D sci-fi floor-plate, material depth, calm center for existing pipes, and R2 style references; candidates live in `debug/gameplay_tile_candidates_v2/`.
- [x] Gameplay tile candidates keep existing pipe sprites; preview sheets may brighten existing pipe art only for contrast review.
- [x] Save second-pass preview sheet: `debug/gameplay_tile_candidates_v2/tile_floorplate_candidate_preview_sheet.png`.
- [x] Save second-pass generation manifest: `debug/gameplay_tile_candidates_v2/manifest.json`.
- [x] Owner selected gameplay cell tiles on 2026-07-03: dark uses `dark_floorplate_b`, light uses `light_floorplate_a`.
- [x] Copy selected gameplay cell tiles into canonical theme assets: `Assets/Themes/cyberpunk_theme/cell_tiles/dark_floorplate_b.png` and `Assets/Themes/cyberpunk_theme/cell_tiles/light_floorplate_a.png`.
- [x] Store selected gameplay cell tile paths in `ThemeConfig.ui_cell_texture_paths`; runtime must resolve through `get_cell_bg_texture_for_mode(mode)`, never direct hardcoded draw paths.
- [x] Lock cyber gameplay cell textures to strict mode paths with `ThemeConfig.ui_cell_texture_strict_mode_paths = true`; no default/fallback cell texture is allowed for this theme.
- [x] Add `test_gameplay_cell_texture_ssot.gd` to lock owner-selected cell tile paths and helper behavior.
- [x] Reference old `WaternetGodot` only for gameplay/rendering invariants; do not copy old UI/layout/skin code over the cyber reskin.
- [x] Materialize mode-specific gameplay cell textures through `ThemeConfig.get_cell_bg_texture_for_mode(mode)` and cache the resulting `ImageTexture`; this prevents runtime GameScene draws from showing white cells while preserving strict SSOT paths.
- [x] Add `test_game_scene_cell_texture_visible.gd` to assert the actual GameScene runtime cell sample is not white when the selected dark gameplay tile is active.
- [x] Final owner approval covers all four generated UI layout contexts: dark portrait, dark landscape, light portrait, and light landscape.
- [x] Settings modal includes a `ThemeModeBtn` runtime toggle for `ThemeConfig.ui_generated_asset_mode`; supported modes come from `ThemeConfig.ui_generated_asset_paths`, not per-scene hardcoded mode lists.
- [x] Theme mode choice persists through `SaveManager` key `cyber_ui_generated_asset_mode`; runtime switches refresh generated UI assets, top tray regions, playboard SSOT layout, HUD labels, modal frame, and VFX layer without mutating owner-approved coordinates.
- [x] Add `test_settings_theme_mode_toggle.gd` to lock settings button wiring and dark/light playboard switch behavior.
- [x] Save PhotoRoom QA data into canonical manifest: `docs/ui_cyber_component_generation_manifest.json`.
- [x] Keep PhotoRoom dark/light/checkerboard QA sheet as remote R2 evidence only, not as local production `debug/` asset.
- [x] Upload PhotoRoom QA sheet to R2: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-production/debug/photoroom_cutout_edge_qa_preview.png`.

Style sync requirements:

- Reference pack must include owner reference image, current cyber pipe/cell screenshot, project logo, final pipe/cell sprites, and any approved mockup.
- Every 9Router prompt must repeat the same art direction anchor: cyber puzzle, fake3D cockpit layer, black/green gameplay tone, cyan electric accent, beveled glossy depth, mobile game readability.
- Production assets must be generated from the approved full-screen mockup or shared references, not isolated prompts.
- Do not change camera angle, perspective, bevel language, glow color family, material finish, or edge thickness between assets.
- Do not let generated assets include placeholder text, fake logos, extra icons, pipes, characters, or gameplay pieces unless explicitly requested.
- Save prompt, reference paths, model, output path, intended asset rect, and reject reason for failed variants.
- If a generated part does not match style, regenerate from references; do not hand-paint production fixes in Godot.
- If an alpha edge looks dirty or jagged, rerun PhotoRoom or regenerate the source; do not accept manual chroma-key cleanup as production.
- UI screen order for future agents: design all objects first, place all objects second, add text last.
- Current R2 reference manifest: `docs/ui_cyber_reference_pack_r2.json`.
- Current style trial doc: `docs/ui_cyber_style_trials.md`.
- 9Router UI generation runbook: `docs/9router_ui_generation_runbook.md`.
- Dark/light component design: `docs/ui_cyber_dark_light_component_design.md`.
- Dark/light component R2 manifest: `docs/ui_cyber_dark_light_component_refs_r2.json`.
- 9Router component call queue: `docs/ui_cyber_9router_component_call_queue.md`.
- Component generation checklist: `docs/ui_cyber_component_generation_checklist.md`.
- Component generation manifest: `docs/ui_cyber_component_generation_manifest.json`.
- Generated UI layout captures:
  - `debug/generated_ui_layout_dark_portrait.png`
  - `debug/generated_ui_layout_dark_landscape.png`
  - `debug/generated_ui_layout_light_portrait.png`
  - `debug/generated_ui_layout_light_landscape.png`
  - `debug/generated_ui_layout_portrait.png` (dark alias)
  - `debug/generated_ui_layout_landscape.png` (dark alias)
- Generated settings modal captures:
  - `debug/generated_ui_settings_dark_portrait.png`
  - `debug/generated_ui_settings_dark_landscape.png`
  - `debug/generated_ui_settings_light_portrait.png`
  - `debug/generated_ui_settings_light_landscape.png`
- Generated leaderboard modal captures:
  - `debug/generated_ui_leaderboard_dark_portrait.png`
  - `debug/generated_ui_leaderboard_dark_landscape.png`
  - `debug/generated_ui_leaderboard_light_portrait.png`
  - `debug/generated_ui_leaderboard_light_landscape.png`
- Generated solved/win modal captures:
  - `debug/generated_ui_solved_dark_portrait.png`
  - `debug/generated_ui_solved_dark_landscape.png`
  - `debug/generated_ui_solved_light_portrait.png`
  - `debug/generated_ui_solved_light_landscape.png`
- Owner approved using `NINEROUTER_KEY` for image generation in this project on 2026-07-01.
- If `NINEROUTER_IMAGE_KEY` is missing, use `NINEROUTER_KEY` as the image authorization key.
- This key rule is a project exception to the default 9Router image skill preference.
- Before generation, verify `/v1/models/image` lists `cx/gpt-5.5-image` with the approved key.

## B4. Fake3D Layer Asset

- [ ] Confirm fake3D method.
- [ ] Generate top tray layer assets through 9Router if needed.
- [x] Use PhotoRoom for every non-background transparent cutout; chroma-key cleanup is debug-only preview.
- [x] Store asset sizes, anchors, draw rects, padding, and slice rules in SSOT.
- [ ] Verify all fake3D layer assets use the same reference pack and style anchor as B3.

## B5. Visual Audit Loop

- [x] Open visible Godot debug.
- [x] Capture screenshot.
- [ ] Compare against owner reference.
- [x] Check responsive framing.
- [x] Check overlap, scale, hierarchy, contrast, touch targets.
- [x] Fix through SSOT tokens or regenerate assets.
- [ ] Repeat until owner approves.

Capture note: generated UI runtime captures must run windowed, not `--headless`, because `root.get_texture().get_image()` returns null under the current headless renderer.
