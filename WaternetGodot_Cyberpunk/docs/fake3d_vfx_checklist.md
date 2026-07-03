# Fake3D To VFX Checklist

Purpose: keep cyber skin work ordered, SSOT-first, and safe for later VFX. No fallback pipeline in this project.

## 1. Gameplay Contract

- [x] Keep source fixed at top-left: `Vector2i(0, 0)`.
- [x] Keep target fixed at bottom-right: `Vector2i(width - 1, height - 1)`.
- [x] Preserve level difficulty scaling by board size.
- [x] Randomize pipe layout/rotations per level instead of fixed boards.
- [x] Test random level variation and fixed endpoints.
- [x] Update legacy `test_suite.gd` generator expectations to current 5x5/6x6+ difficulty contract.

## 2. Pipe Logic And Visual Mapping

- [x] Use canonical port order: North, East, South, West.
- [x] Use canonical pipe types: cap, I, L, T, X, source, target.
- [x] Fix L rotation mapping so visual ports match logical ports.
- [x] Remove ad hoc L scale hacks after sprite sheet rebuild.
- [x] Keep slice/flow mask logic in `PipeVisualMapping`, not scattered in scene code.

## 3. Cyber Sprite Sheet Reset

- [x] Rebuild pipe types on a shared 512x512 frame.
- [x] Keep consistent origin: `Vector2(256, 256)`.
- [x] Keep shared port coordinates on frame edges.
- [x] Generate base assets first: source, target, cap, I, L, T, X, cell.
- [x] Generate energy frame sheets from matching base refs.
- [x] Avoid magic/hats/non-pipe artifacts in generated assets.
- [x] Use background removal for generated refs when needed.

## 4. Fake3D Visual Pass

- [x] Restore cyber background and cell tile background.
- [x] Add fake3D cell inset, bevel, border, and pipe shadow.
- [x] Keep fake3D params in `ThemeConfig`.
- [x] Keep rendering deterministic, no AI/runtime fallback.
- [x] Capture runtime screenshot after visual changes.
- [x] Capture size sweep levels: 1, 6, 9, 12, 15, 16.

## 5. Geometry SSOT

- [x] Create `AssetGeometryConfig`.
- [x] Store `frame_size`, `draw_origin`, `center`.
- [x] Store `content_rect` for visual bounds.
- [x] Store `energy_rect` for energy/VFX bounds.
- [x] Store North/East/South/West port points.
- [x] Assign geometry resources in `cyberpunk_theme.tres`.
- [x] Add `ThemeConfig.get_all_asset_geometries()`.
- [x] Add `ThemeConfig.get_asset_geometry(asset_key)`.
- [x] Make `GameScene` read geometry through theme lookup.
- [x] Test geometry manifest, scaling, and port alignment.

## 6. Energy Overlay

- [x] Keep base pipe sprite separate from energy overlay.
- [x] Draw base pipe first.
- [x] Draw energy atlas overlay only for watered cells.
- [x] Clip energy overlay to `energy_rect`.
- [x] Keep frame timing and sheet path lookup deterministic.
- [x] Test atlas region and draw rect contract.
- [x] Capture runtime screenshot and size sweep.

## 7. Pre-VFX Data Layer

- [x] Add flow visual state: order, input direction, output directions, flow mask, age.
- [x] Add VFX anchor helper: center, ports, energy center.
- [x] Test flow state on straight and branching paths.
- [x] Test anchors use geometry SSOT and cell transform.
- [x] Keep VFX data independent from gameplay solver mutation.
- [x] Sync `GameScene.flow_visual_state` for future VFX layer reads.

## 8. VFX Layer Skeleton

- [x] Add separate `PipeVfxLayer` or equivalent draw/update unit.
- [x] Read only flow state, anchors, theme, and time.
- [x] Toggle VFX/debug overlays without changing gameplay.
- [x] Capture screenshots with VFX enabled/disabled.
- [x] Keep all VFX sizes/colors in theme SSOT.

## 9. VFX Effects

- [x] Port contact spark when energy enters a tile.
- [x] Directional glow/trail from input port to output port.
- [x] Target receive pulse.
- [x] Source emission pulse.
  - [x] Add `get_source_emissions()` data method on `PipeVfxLayer`.
  - [x] Detect source by canonical `geometry.asset_key == "source"`.
  - [x] Spawn emission only when source has active `output_dirs`.
  - [x] Use source `energy_center` from geometry SSOT.
  - [x] Keep color, duration, radius, and ring width in `ThemeConfig`.
  - [x] Cover behavior with `test_pipe_vfx_source_emission.gd`.
  - [x] Include emission in VFX toggle capture.
- [x] Optional idle hum on watered path after fill completes.
  - [x] Define behavior: only old watered pipe cells hum after active entry/trail/pulse window.
  - [x] Keep hum data read-only from `PipeVfxLayer`, independent from gameplay mutation.
  - [x] Add RED contract test: `test_pipe_vfx_idle_hum.gd`.
  - [x] Add hum SSOT fields to `ThemeConfig` and `cyberpunk_theme.tres`.
  - [x] Add `get_idle_hums()` data method on `PipeVfxLayer`.
  - [x] Draw idle hum in VFX layer without changing `GameScene._draw()`.
  - [x] Include idle hum in VFX toggle capture.
  - [x] Animate idle hum radius/alpha after path settles so powered pipes keep visible motion.
  - [x] Cover idle hum motion with `test_pipe_vfx_idle_hum_motion.gd`.
  - [x] Capture idle hum motion frames with `capture_vfx_idle_hum_motion.gd`.
- [x] Performance check on 10x10 board.
  - [x] Add deterministic 10x10 VFX budget script.
  - [x] Verify VFX counts stay bounded by flow state and board geometry.
  - [x] Capture or log evidence for 10x10 board.

## 10. Before Any New Skin

- [x] Fill geometry resources first.
  - [x] Canonical required keys live in `ThemeConfig.get_required_asset_keys()`.
  - [x] Current cyber skin has geometry resources for `cell`, `source`, `target`, `cap`, `I`, `L`, `T`, `X`.
- [x] Verify frame size, origin, content rect, energy rect, ports.
  - [x] `ThemeConfig.validate_geometry_manifest()` checks missing assets, key mismatch, frame bounds, rect bounds, and port edge placement.
  - [x] `test_skin_geometry_pipeline_contract.gd` fails early if a skin omits required geometry.
- [x] Run geometry and port tests.
  - [x] `test_theme_geometry_ssot.gd`.
  - [x] `test_asset_geometry_contract.gd`.
  - [x] `test_asset_port_alignment.gd`.
  - [x] `test_skin_geometry_pipeline_contract.gd`.
- [x] Run screenshot size sweep.
  - [x] `capture_fake3d_size_sweep.gd`.
  - [x] `capture_fake3d_screenshot.gd`.
  - [x] `capture_vfx_layer_toggle.gd`.
- [x] Do not tune `GameScene` for a skin-specific mismatch.
  - [x] Scene geometry lookup verified through `theme.get_asset_geometry(...)`.
  - [x] Skin mismatch must be fixed in geometry resources or asset sheet, not in scene draw math.

## 11. Next Phase: Energy Animation Polish

- [x] Define canonical energy animation timing per pipe type.
  - [x] Store `energy_sheet_frame_count`, `energy_sheet_frame_size`, `energy_default_frame_duration`, and `energy_frame_duration_by_asset_key` in `ThemeConfig`.
  - [x] Expose `ThemeConfig.get_energy_frame_duration()`, `get_energy_animation_duration()`, and `get_energy_sheet_expected_size()`.
- [x] Tie 8-frame energy sheets to `FlowVisualState.age`.
  - [x] `GameScene._get_energy_frame_index()` reads `flow_visual_state[cell].age` when available.
  - [x] `GameScene._get_energy_frame_index_for_age()` clamps to configured frame count.
- [x] Ensure source/target timing respects fixed endpoints.
  - [x] Source and target use the same canonical frame helper and geometry asset keys.
  - [x] Endpoint positions remain owned by level generation contract from step 1.
- [x] Add tests for frame progression and no fallback texture path.
  - [x] `test_energy_animation_timing.gd`.
  - [x] `test_energy_sheet_no_fallback.gd`.
- [x] Capture animated flow states after timing changes.
  - [x] `capture_energy_animation_frames.gd` writes `debug/energy_animation_frames.png`.

## 12. Runtime No-Fallback Audit

- [x] Remove runtime references to AI/fallback energy sheet roots.
- [x] Keep energy sheet lookup under canonical `ThemeConfig.energy_sheet_root`.
- [x] Store `energy_sheet_manifest_path` in `ThemeConfig`.
- [x] Add `ThemeConfig.validate_energy_sheet_manifest()`.
- [x] Validate manifest frame count, frame size, canonical root, duplicate sheet paths, and sheet existence.
- [x] Add `test_energy_sheet_manifest_contract.gd`.
- [x] Add `test_no_runtime_fallback_contract.gd`.

## 13. Live Gameplay Visual QA Contract

- [x] Add scene-space visual contract hooks on `GameScene`.
  - [x] `get_board_rect()`.
  - [x] `get_cell_rect(cell_pos)`.
  - [x] `get_endpoint_cell_positions()`.
- [x] Add `test_game_scene_visual_contract_hooks.gd`.
- [x] Add deterministic live-scene capture `capture_live_gameplay_visual_contract.gd`.
- [x] Validate source remains top-left and target remains bottom-right in a rendered scene.
- [x] Validate board fits viewport and source/target cells render visible detail.
- [x] Validate live scene has VFX layer and full watered visual state.
- [x] Write screenshot to `debug/live_gameplay_visual_contract.png`.

## 14. Gameplay Interaction QA Contract

- [x] Add `GameScene.get_cell_at_screen_position(screen_position)`.
- [x] Add `GameScene.try_rotate_cell(cell_pos, animate := true)` as canonical interaction hook.
- [x] Allow source and target port rotation while keeping endpoint positions fixed.
- [x] Count endpoint rotations as moves.
- [x] Keep `PipeGrid.source_ports` and `PipeGrid.target_ports` synced after endpoint rotation.
- [x] Rotate normal pipes through `PipeGrid.rotate_tile()`.
- [x] Reset energy starts and refresh VFX flow state after pipe or endpoint rotation.
- [x] Refresh solver win state after rotation.
- [x] Guard solved popup access for headless/test scenes.
- [x] Add `test_gameplay_interaction_contract.gd`.
- [x] Add before/after interaction capture `capture_gameplay_interaction_rotate.gd`.
- [x] Write screenshots:
  - [x] `debug/gameplay_interaction_before.png`.
  - [x] `debug/gameplay_interaction_after.png`.

## 15. Gameplay Reset/Lifecycle QA Contract

- [x] Add `GameScene.reset_current_level(is_randomized := true)` as canonical reset hook.
- [x] Route reset button through `reset_current_level(true)`.
- [x] Reset clears `moves`.
- [x] Reset clears `energy_flow_start_times`.
- [x] Reset clears `flow_visual_state`.
- [x] Reset rebuilds `visual_rotations` from canonical grid data.
- [x] Reset refreshes solver win state.
- [x] Reset preserves fixed source at top-left and target at bottom-right.
- [x] Reset supports deterministic non-randomized mode for tests.
- [x] Add `test_gameplay_reset_contract.gd`.
- [x] Add before/after reset capture `capture_gameplay_reset_contract.gd`.
- [x] Write screenshots:
  - [x] `debug/gameplay_reset_before.png`.
  - [x] `debug/gameplay_reset_after.png`.

## 16. Endpoint Rotation Visual QA Contract

- [x] Source and target positions remain fixed, but their ports can rotate.
- [x] Endpoint rotation uses `GameScene.try_rotate_cell(...)`, same as normal pipes.
- [x] Endpoint rotation increments moves and refreshes solver state.
- [x] Endpoint rotation resets energy and refreshes VFX flow state.
- [x] `PipeGrid.source_ports` and `PipeGrid.target_ports` stay synced with rotated tile ports.
- [x] `GameScene.visual_rotations` syncs immediately when rotation is non-animated.
- [x] Add endpoint visual assertions to `test_gameplay_interaction_contract.gd`.
- [x] Add before/after endpoint capture `capture_endpoint_interaction_rotate.gd`.
- [x] Write screenshots:
  - [x] `debug/endpoint_rotation_before.png`.
  - [x] `debug/endpoint_rotation_after.png`.

## 17. Live VFX Gameplay Integration

- [x] Use solver and `FlowVisualState` as SSOT for powered path.
- [x] Add transition data for old/new flow around `try_rotate_cell(...)`.
- [x] Keep VFX transition data read-only and separate from gameplay mutation.
- [x] Add theme SSOT fields for disconnect decay, error spark, and debug overlay.
- [x] Add enter/lost cell and contact diff tests.
- [x] Add disconnect decay VFX contract.
- [x] Add tiny error spark VFX contract.
- [x] Add GameScene -> PipeVfxLayer transition hook contract.
- [x] Add VFX debug overlay contract.
- [x] Add live VFX gameplay capture: before rotate, connected, disconnected.
- [x] Add debug overlay capture for anchors, input/output dirs, and flow order.
- [x] Run full `test_*.gd` suite.
- [x] Run full `capture_*.gd` suite.

## 18. VFX Runtime Motion Contract

- [x] Keep VFX time-based motion owned by `PipeVfxLayer`, not `GameScene._draw()`.
- [x] Add `PipeVfxLayer.has_active_motion(now := -1.0)` using theme-configured durations as SSOT.
- [x] Include source emission, target pulse, contact spark, directional trail, animated idle hum, disconnect decay, and error spark in active-motion checks.
- [x] Add `_process(_delta)` on `PipeVfxLayer` to `queue_redraw()` only while active VFX motion exists.
- [x] Cover redraw/motion ownership with `test_pipe_vfx_motion_redraw_contract.gd`.

## 19. VFX Final Polish And Library Prep

- [x] Write final polish design spec: `docs/superpowers/specs/2026-07-01-vfx-final-polish-design.md`.
- [x] Write final polish implementation plan: `docs/superpowers/plans/2026-07-01-vfx-final-polish.md`.
- [x] Add continuous powered path wave.
  - [x] Store color, period, segment length, width, alpha, and max effects in `ThemeConfig`.
  - [x] Derive wave paths from `FlowVisualState` plus geometry anchors.
  - [x] Cap wave records by `vfx_path_wave_max_effects`.
  - [x] Cover data contract with `test_pipe_vfx_path_wave.gd`.
- [x] Add rotate spark feedback.
  - [x] Store color, duration, radius, ray count, and width in `ThemeConfig`.
  - [x] Trigger through `GameScene.try_rotate_cell(...)` after valid rotation.
  - [x] Keep event state in `PipeVfxLayer.rotation_event_state`.
  - [x] Clear runtime event on reset.
  - [x] Cover data contract with `test_pipe_vfx_rotation_spark.gd`.
- [x] Add win burst.
  - [x] Store color, duration, radius, ring width, and max cells in `ThemeConfig`.
  - [x] Trigger when `solver.check_connection(grid)` becomes solved.
  - [x] Sort burst cells by `FlowVisualState.order`.
  - [x] Cap burst records by `vfx_win_burst_max_cells`.
  - [x] Cover data contract with `test_pipe_vfx_win_burst.gd`.
- [x] Add GameScene polish hook test: `test_game_scene_vfx_polish_hooks.gd`.
- [x] Extend 10x10 VFX performance test to include path wave and win burst caps.
- [x] Add reusable VFX parameter catalog: `docs/vfx_effect_parameters.md`.
- [x] Cover catalog with `test_vfx_effect_parameter_catalog.gd`.
- [x] Add final VFX polish capture: `capture_vfx_final_polish.gd`.

## 20. VFX Route Alignment

- [x] Separate visual glow center from pipe route junction.
- [x] Add `AssetGeometryConfig.route_junction` as geometry SSOT.
- [x] Expose `route_junction` through `VfxAnchor.get_anchor_points(...)`.
- [x] Add `Scripts/vfx_route.gd` as canonical route helper.
- [x] Route straight I/T/X opposite-port flow directly from input port to output port.
- [x] Route L turns and T/X branches through `route_junction`.
- [x] Switch `directional_trail`, `path_wave`, and debug route overlay to use `VfxRoute`.
- [x] Keep `energy_center` for glow/hum/burst/spark only.
- [x] Cover route behavior with `test_vfx_route_points.gd`.
- [x] Capture route alignment with `capture_vfx_alignment_debug.gd`.

## 21. Static Energy Overlay Visibility

- [x] Keep canonical route data methods for tests/debug/library reuse.
- [x] Correct wrong route-line hiding attempt: `directional_trail` and `path_wave` are gameplay flow VFX, not static route lines.
- [x] Add `energy_overlay_draw_enabled` SSOT toggle for sprite-sheet energy overlay drawing.
- [x] Set cyber gameplay `energy_overlay_draw_enabled` to `false` to hide static green routing/fill overlay.
- [x] Set cyber gameplay `vfx_trail_draw_enabled` to `false` because it reads as a static route line.
- [x] Keep cyber gameplay `vfx_path_wave_draw_enabled` set to `true` for moving flow feedback.
- [x] Render `path_wave` as a moving pulse instead of a route-length line segment.
- [x] Gate `GameScene._draw()` energy overlay rendering through `_is_energy_overlay_draw_enabled(theme)`.
- [x] Keep debug overlay controlled by `vfx_debug_visible`.
- [x] Cover overlay hidden state and flow VFX visible state with `test_vfx_route_line_visibility.gd`.

## 22. Target Visual State

- [x] Root cause: target draw path always used `base_texture`, so `target_texture_watered` never appeared.
- [x] Root cause: dry target inherited pipe dry modulate `Color(0.08, 0.08, 0.08)`, making it read as black.
- [x] Add `target_dry_modulate` SSOT for visible-but-unpowered target brightness.
- [x] Add `target_powered_modulate` SSOT for reached target brightness boost.
- [x] Add `target_energy_overlay_draw_enabled` SSOT so target can keep green core energy while pipe route overlays stay hidden.
- [x] Replace target energy sheet with 8-frame 4096x512 core-fill animation: whole core brightens gradually, no incoming line-only frame.
- [x] Add target geometry `core_center` SSOT at `Vector2(256, 288)`.
- [x] Add target core blink SSOT params for idle weak blink and powered bright blink.
- [x] Add `_get_pipe_draw_texture_for_state(...)` so powered target can draw `target_texture_watered` without re-enabling static pipe route-line slices.
- [x] Add `_get_pipe_modulate_for_state(...)` so target brightness is canonical, not hardcoded in `GameScene._draw()`.
- [x] Add `_should_draw_energy_overlay_for_asset(...)` so target overlay policy stays per-asset and theme-driven.
- [x] Add `_draw_target_core_overlay(...)` so target core state is visible even if Godot import cache has stale sheet pixels.
- [x] Cover target dry/powered draw contract with `test_target_visual_state.gd`.

## 23. Flow Particle Density

- [x] Keep particle density SSOT in `ThemeConfig`: `vfx_path_wave_min_particles_per_output`, `vfx_path_wave_max_particles_per_output`, `vfx_path_wave_density_curve`, `vfx_path_wave_order_phase_offset`.
- [x] Derive per-output particle count from `FlowVisualState.order / max_order`, not board size, level id, or hardcoded positions.
- [x] Increase particle count toward target while respecting `vfx_path_wave_max_effects`.
- [x] Store `particle_index`, `particle_count`, `order`, and `density_progress` in path-wave records for tests/debug/future library reuse.
- [x] Cover density behavior with `test_pipe_vfx_path_wave.gd`.

## 24. Idle Pipe Aura

- [x] Replace radar-like idle hum circles with route-following pipe aura.
- [x] Keep aura SSOT in `ThemeConfig`: `vfx_idle_hum_glow_width_ratio`, `vfx_idle_hum_core_width_ratio`, plus existing idle hum color/alpha/period/pulse params.
- [x] Derive aura route from canonical `VfxRoute.get_route_points(...)`, not from raw center circles.
- [x] Keep `get_idle_hums(...)` data contract but change records to include `points`, `input_dir`, `output_dir`, `core_width`, and `glow_width`.
- [x] Cover no-circle aura behavior with `test_pipe_vfx_idle_hum.gd`.

## 25. Lightning Arc Accent

- [x] Use external lightning spritesheet as a project asset: `Assets/VFX/lightning_boltarc_01_spritesheet.png`.
- [x] Keep lightning SSOT in `ThemeConfig`: texture, frame size, columns, rows, period, alpha, scale, max arcs, cell stride, minimum order progress, and contact bias.
- [x] Draw lightning as sparse pipe/contact accent, not as a full tile overlay.
- [x] Prevent adjacent-tile duplication with canonical contact key (`min_cell>max_cell`).
- [x] Keep effect data in `PipeVfxLayer.get_lightning_arcs(now)`, not in `GameScene._draw()`.
- [x] Include lightning in active motion and 10x10 VFX performance budget.
- [x] Cover contract with `test_pipe_vfx_lightning_arcs.gd`.
- [x] Add visual capture script `capture_vfx_lightning_arcs.gd`.

## 26. VFX Usage Library And 60 FPS Contract

- [x] Choose lightning tone for black/green cyber theme: electric cyan with icy-white core, not green, so it separates from gameplay flow.
- [x] Add `vfx_lightning_color` to `ThemeConfig`, `cyberpunk_theme.tres`, `get_lightning_arcs(...)`, and renderer modulation.
- [x] Keep lightning color as SSOT theme data, not renderer hardcode.
- [x] Add `docs/vfx_usage_library.md` with Trigger, Data source, Renderer, SSOT, Budget, and Integration for every current VFX type.
- [x] Lock runtime FPS in `project.godot`: `application/run/max_fps=60` and `physics/common/physics_ticks_per_second=60`.
- [x] Lock 60 FPS data-build budget with `test_vfx_performance_10x10.gd` at `16666` usec.
- [x] Cover runtime FPS contract with `test_runtime_60fps_contract.gd`.
- [x] Extend VFX catalog checks for `vfx_lightning_color` and `60 FPS`.

## 27. Godot Debug Runbook And Lightning Cadence

- [x] Add `docs/godot_debug_runbook.md` so future agents open visible debug without confusing GoPeak `run-project` headless mode.
- [x] Document live debug ports: legacy `9090`, GoPeak runtime `7777`, editor bridge `6505`.
- [x] Keep GoPeak installed/configured, but use direct visible debug command when the user needs to see the window.
- [x] Add headless guard to `addons/godot_mcp_runtime/mcp_runtime_autoload.gd` so tests do not fight visible debug port `7777`.
- [x] Fix lightning spritesheet cadence: `vfx_lightning_period` is full cycle duration, not seconds per frame.
- [x] Keep sparse contact selection stable per cycle while sprite frames advance inside that cycle.
- [x] Cover cadence with `test_pipe_vfx_lightning_arcs.gd`.
- [x] Cover runbook with `test_godot_debug_runbook.gd`.

## 28. Source-Matched Lightning 60 FPS

- [x] Inspect original VFX media: MP4 is 2048x2048, 250 frames, 60 FPS, 4.166667s; OGV is 256x256, 60 FPS, 4.166667s.
- [x] Identify mismatch: old project atlas had only 24 frames, so it could not match source motion.
- [x] Add `vfx_lightning_frame_count = 250` so the renderer never samples unused atlas cells.
- [x] Add `vfx_lightning_contact_period` so contact sparsity does not depend on the full 4.166667s sheet cycle.
- [x] Set cyber lightning atlas layout to 16x16 with 250 active frames.
- [x] Set `vfx_lightning_period = 4.1666667` to match 250 frames at 60 FPS.

## 29. Continuous Energy Stream

- [x] Keep continuous stream SSOT in `ThemeConfig`: `vfx_energy_stream_enabled`, color, period, alpha, width ratios, shimmer segment, pulse alpha, order phase offset, and max effects.
- [x] Add cyber theme values so the stream reads cyan-green plasma under existing green flow particles and cyan lightning.
- [x] Add `PipeVfxLayer.get_energy_streams(now)` data hook using canonical `VfxRoute.get_route_points(...)`.
- [x] Draw full-route glow/core plus a moving shimmer window so current reads as connected instead of dotted.
- [x] Keep `path_wave` as particle density layer and `lightning_arc` as sparse accent; no fallback assets.
- [x] Include stream records in 10x10 60 FPS performance budget.
- [x] Cover contract with `test_pipe_vfx_energy_stream.gd`.
- [x] Document usage in `docs/vfx_effect_parameters.md` and `docs/vfx_usage_library.md`.

## 30. Owner Question Gate

Before any future VFX pass, stop and ask owner until these answers are explicit:

- [x] Confirm visual intent: what should player feel/read first, and what must not be visible.
- [x] Confirm effect role: core gameplay readability, feedback, ambience, reward, or debug-only.
- [x] Confirm trigger rules: when effect starts, loops, intensifies, fades, and stops.
- [x] Confirm target cells: source, target, powered pipes, broken contacts, empty tile, board-wide, or UI.
- [x] Confirm layering order: base sprite, static energy overlay, aura, continuous stream, particles, lightning, sparks, debug overlay.
- [x] Confirm color/tone: gameplay color versus accent color, with contrast against theme background.
- [x] Confirm motion feel: continuous, sparse, flicker, pulse, burst, fill-up, decay, or idle blink.
- [x] Confirm asset source: procedural draw, existing spritesheet, generated sprite sheet, external video atlas, or shader.
- [x] Confirm performance budget: 60 FPS target, max records, max atlas frames, board size stress case.
- [x] Confirm SSOT location: every size, color, duration, cap, atlas layout, and toggle belongs in `ThemeConfig` plus theme resource.
- [x] Confirm no fallback: missing asset or param fails test; do not silently use alternate roots/assets.
- [x] Confirm acceptance evidence: exact tests, screenshots, visible Godot debug, and owner visual approval.

## 31. A-Z VFX Workflow

- [x] Checkpoint A: write owner-approved intent in this checklist before coding.
- [x] Checkpoint B: map gameplay state source (`ConnectionSolver`, `FlowVisualState`, transition events, win events).
- [x] Checkpoint C: choose renderer ownership; live VFX belongs in `PipeVfxLayer`, legacy static overlays stay documented separately.
- [x] Checkpoint D: choose canonical anchors (`energy_center`, `route_junction`, ports) from geometry SSOT.
- [x] Checkpoint E: add RED contract test for effect data, SSOT params, caps, and motion.
- [x] Checkpoint F: add or extend `ThemeConfig` exports; do not hardcode renderer literals.
- [x] Checkpoint G: add concrete theme values in `cyberpunk_theme.tres`.
- [x] Checkpoint H: add effect data method returning dictionaries for tests and future VFX library reuse.
- [x] Checkpoint I: draw effect in `PipeVfxLayer` with deterministic order and without gameplay mutation.
- [x] Checkpoint J: add active-motion participation through `has_active_motion(...)` only when effect animates.
- [x] Checkpoint K: cap board-scale records and include them in `test_vfx_performance_10x10.gd`.
- [x] Checkpoint L: document effect in `docs/vfx_effect_parameters.md`.
- [x] Checkpoint M: document trigger/data/renderer/SSOT/budget/integration in `docs/vfx_usage_library.md`.
- [x] Checkpoint N: add capture script or runtime screenshot for visual proof.
- [x] Checkpoint O: open visible Godot debug with `docs/godot_debug_runbook.md` command.
- [x] Checkpoint P: inspect screenshot for route alignment, duplicate effects, layer order, text/UI overlap, and theme contrast.
- [x] Checkpoint Q: tune only SSOT theme params unless geometry or source asset is wrong.
- [x] Checkpoint R: run focused effect tests and adjacent regression tests.
- [x] Checkpoint S: run performance budget test on 10x10 connected board.
- [x] Checkpoint T: verify no fallback paths/assets with `test_no_runtime_fallback_contract.gd`.
- [x] Checkpoint U: update checklist with every completed step and new known caveat.
- [x] Checkpoint V: record final VFX parameter meanings for future shared library migration.
- [x] Checkpoint W: keep old debug artifacts only when useful; name final captures clearly.
- [x] Checkpoint X: get owner visual approval in visible debug, not only headless tests.
- [x] Checkpoint Y: close any running Godot session only if owner no longer needs it.
- [x] Checkpoint Z: final response must list changed files, tests, screenshots, and unresolved warnings.

Current closed VFX stack:

- [x] `static_energy_overlay`: legacy sprite-sheet fill; cyber pipe body disabled, target core allowed.
- [x] `contact_spark`: short entry spark at input port.
- [x] `directional_trail`: short leading fill; cyber hidden in final visuals.
- [x] `source_emission`: source-local pulse.
- [x] `target_pulse`: arrival pulse.
- [x] `target_core_blink`: weak idle target, bright connected target.
- [x] `idle_hum`: route-following settled aura.
- [x] `energy_stream`: continuous connected current.
- [x] `path_wave`: density-scaled moving particles.
- [x] `lightning_arc`: sparse external 60 FPS lightning accent.
- [x] `rotation_spark`: input feedback.
- [x] `disconnect_decay`: lost powered cells fade.
- [x] `error_spark`: broken contact spark.
- [x] `win_burst`: solved-path celebration.
