# VFX Effect Parameters

Purpose: canonical parameter list for pipe-connection puzzle VFX. Current implementation uses `ThemeConfig` as SSOT and `PipeVfxLayer` as renderer. Future shared VFX library should keep these effect names, triggers, anchors, and parameter meanings.

## Geometry Anchors

- `energy_center`: glow, hum, burst, pulse, and spark center. It may be visually biased to match the illuminated sprite region.
- `route_junction`: path routing junction for pipe interior flow. It must not be inferred from `energy_center`.
- Direction ports: `north`, `east`, `south`, `west`, derived from geometry port points.

## static_energy_overlay

- Trigger: watered tile sprite-sheet overlay draw inside `GameScene._draw()`.
- Purpose: legacy/static fill image, separate from live VFX flow.
- Parameters: `energy_overlay_draw_enabled`, `target_energy_overlay_draw_enabled`, `energy_sheet_frame_count`, `energy_sheet_frame_size`, `energy_default_frame_duration`, `energy_frame_duration_by_asset_key`, `energy_sheet_root`, `energy_texture_prefix`, `energy_sheet_manifest_path`.
- Cyber gameplay default: `energy_overlay_draw_enabled = false` for pipes, `target_energy_overlay_draw_enabled = true` for reached target core glow; live flow remains owned by `directional_trail` and `path_wave`.

## contact_spark

- Trigger: energy enters a tile.
- Anchor: input port from `VfxAnchor.get_anchor_points(...)`.
- Parameters: `vfx_contact_spark_color`, `vfx_contact_spark_duration`, `vfx_contact_spark_radius_ratio`.

## directional_trail

- Trigger: powered tile has at least one output direction during entry/fill.
- Route path: input port -> output port for straight I/T/X routes; input port -> `route_junction` -> output port for turns/branches.
- Parameters: `vfx_trail_color`, `vfx_trail_draw_enabled`, `vfx_trail_duration`, `vfx_trail_width_ratio`, `vfx_trail_min_alpha`.

## source_emission

- Trigger: source tile is powered by definition. It pulses once on entry and keeps a weak local idle pulse if the source is blocked and has no active output directions, so first launch never looks like VFX is missing just because random rotation starts disconnected.
- Anchor: source energy center.
- Parameters: `vfx_source_emission_color`, `vfx_source_emission_duration`, `vfx_source_emission_radius_ratio`, `vfx_source_emission_ring_width_ratio`, `vfx_source_idle_enabled`, `vfx_source_idle_period`, `vfx_source_idle_alpha_min_ratio`, `vfx_source_idle_alpha_pulse_ratio`, `vfx_source_idle_radius_pulse_ratio`.

## target_pulse

- Trigger: target receives energy.
- Anchor: target energy center.
- Parameters: `vfx_target_pulse_color`, `vfx_target_pulse_duration`, `vfx_target_pulse_radius_ratio`, `vfx_target_pulse_ring_width_ratio`.

## target_core_blink

- Trigger: target tile exists; idle state blinks weakly before connection, powered state blinks brightly after connection.
- Anchor: target geometry `core_center`.
- Behavior: draw procedural green core glow over target socket so it stays visible even when pipe route overlays are hidden.
- Parameters: `target_core_idle_color`, `target_core_powered_color`, `target_core_idle_alpha_min`, `target_core_idle_alpha_max`, `target_core_powered_alpha_min`, `target_core_powered_alpha_max`, `target_core_idle_radius_px`, `target_core_powered_radius_px`, `target_core_blink_period`.
- Asset backup: `energy_sheets/target/target_sheet.png` remains an 8-frame 4096x512 core-fill sheet; frames brighten the whole core, not a route line.

## idle_hum

- Trigger: powered non-endpoint pipe remains powered after entry/fill window.
- Route path: same canonical path helper as `directional_trail`, so the hum/aura follows the powered pipe interior instead of drawing a radar-like circle.
- Behavior: soft pipe aura/glow pulses around the active route after the pipe has settled.
- Parameters: `vfx_idle_hum_color`, `vfx_idle_hum_delay`, `vfx_idle_hum_alpha`, `vfx_idle_hum_width_ratio`, `vfx_idle_hum_glow_width_ratio`, `vfx_idle_hum_core_width_ratio`, `vfx_idle_hum_radius_ratio`, `vfx_idle_hum_period`, `vfx_idle_hum_radius_pulse_ratio`, `vfx_idle_hum_alpha_pulse_ratio`.

## energy_stream

- Trigger: powered tile has at least one active output direction.
- Route path: same canonical path helper as `directional_trail`, never raw `energy_center`.
- Behavior: continuous plasma ribbon across the active pipe interior. It draws full-route glow/core first, then a moving shimmer window, so energy reads as one connected current instead of separated dots.
- Relationship: `energy_stream` is the main continuous current; `path_wave` adds brighter moving particles; `lightning_arc` remains sparse high-voltage accent.
- Parameters: `vfx_energy_stream_enabled`, `vfx_energy_stream_color`, `vfx_energy_stream_period`, `vfx_energy_stream_alpha`, `vfx_energy_stream_width_ratio`, `vfx_energy_stream_glow_width_ratio`, `vfx_energy_stream_shimmer_width_ratio`, `vfx_energy_stream_shimmer_segment_ratio`, `vfx_energy_stream_pulse_alpha_ratio`, `vfx_energy_stream_order_phase_offset`, `vfx_energy_stream_max_effects`.

## path_wave

- Trigger: powered tile has at least one active output direction.
- Route path: same canonical path helper as `directional_trail`, never raw `energy_center`.
- Behavior: bright pulse moves continuously along active powered outputs without drawing a persistent route line.
- Density: particle count per output is derived from `FlowVisualState.order / max_order`, so cells closer to the target emit more particles. Counts are clamped by theme min/max and global cap.
- Parameters: `vfx_path_wave_color`, `vfx_path_wave_draw_enabled`, `vfx_path_wave_period`, `vfx_path_wave_segment_ratio`, `vfx_path_wave_width_ratio`, `vfx_path_wave_alpha`, `vfx_path_wave_min_particles_per_output`, `vfx_path_wave_max_particles_per_output`, `vfx_path_wave_density_curve`, `vfx_path_wave_order_phase_offset`, `vfx_path_wave_max_effects`.

## lightning_arc

- Trigger: powered tile has at least one active output direction and the sparse phase selector chooses that contact.
- Anchor: contact-side accent near the output direction, biased toward the pipe port instead of the tile background.
- Behavior: short sprite-sheet lightning arcs around powered pipe contacts. Adjacent tiles use a canonical contact key (`min_cell>max_cell`) so a shared edge can draw at most one lightning arc.
- Timing: `vfx_lightning_period` is one full sprite-sheet cycle. Cyber uses a 16x16 atlas with `vfx_lightning_frame_count = 250` source frames and `vfx_lightning_period = 4.1666667`, matching the original 60 FPS MP4. Sparse contact selection uses `vfx_lightning_contact_period` so arcs can change contacts without shortening the source animation cycle.
- Color rule: black/green cyber theme uses electric cyan with icy-white core (`vfx_lightning_color`), not green, so lightning reads as high-voltage accent instead of gameplay flow.
- Parameters: `vfx_lightning_enabled`, `vfx_lightning_texture`, `vfx_lightning_frame_size`, `vfx_lightning_columns`, `vfx_lightning_rows`, `vfx_lightning_frame_count`, `vfx_lightning_period`, `vfx_lightning_contact_period`, `vfx_lightning_color`, `vfx_lightning_alpha`, `vfx_lightning_scale_ratio`, `vfx_lightning_max_arcs`, `vfx_lightning_cell_stride`, `vfx_lightning_min_order_progress`, `vfx_lightning_contact_bias`.

## rotation_spark

- Trigger: valid `GameScene.try_rotate_cell(...)`.
- Anchor: changed cell energy center, or cell center if geometry is unavailable.
- Behavior: short radial burst confirming input.
- Parameters: `vfx_rotation_spark_color`, `vfx_rotation_spark_duration`, `vfx_rotation_spark_radius_ratio`, `vfx_rotation_spark_ray_count`, `vfx_rotation_spark_width_ratio`.

## disconnect_decay

- Trigger: transition loses powered cells.
- Anchor: lost cell energy center.
- Parameters: `vfx_disconnect_decay_color`, `vfx_disconnect_decay_duration`, `vfx_disconnect_decay_alpha`.

## error_spark

- Trigger: transition loses powered contacts.
- Anchor: lost contact port.
- Parameters: `vfx_error_spark_color`, `vfx_error_spark_duration`, `vfx_error_spark_radius_ratio`.

## win_burst

- Trigger: solver state becomes solved.
- Anchor: powered path energy centers, sorted by `FlowVisualState.order`.
- Behavior: expanding rings over powered path, capped for large boards.
- Parameters: `vfx_win_burst_color`, `vfx_win_burst_duration`, `vfx_win_burst_radius_ratio`, `vfx_win_burst_ring_width_ratio`, `vfx_win_burst_max_cells`.

## Performance Rules

- Effect data must be derived from `FlowVisualState`, transition state, and explicit runtime event state.
- VFX must not mutate gameplay grid or solver state.
- Continuous effects must advertise active motion through `PipeVfxLayer.has_active_motion()`.
- Board-scale effects must use count caps, currently `vfx_energy_stream_max_effects`, `vfx_path_wave_max_effects`, `vfx_lightning_max_arcs`, and `vfx_win_burst_max_cells`.
- 60 FPS budget: project runtime locks `application/run/max_fps=60` and `physics/common/physics_ticks_per_second=60`; data generation for a connected 10x10 board must stay under `16666` usec; sprite-sheet effects must remain sparse, capped, and theme-driven.
