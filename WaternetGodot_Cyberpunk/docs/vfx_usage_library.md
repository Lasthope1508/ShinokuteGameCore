# VFX Usage Library

Purpose: reusable usage contract for pipe-connection puzzle VFX. Keep effects SSOT-driven through `ThemeConfig`, data-driven through `PipeVfxLayer` or explicit scene state, and capped for 60 FPS. No fallback assets or fallback behavior.

## Shared Rules

- 60 FPS: project runtime locks `application/run/max_fps=60` and `physics/common/physics_ticks_per_second=60`; VFX data build on a connected 10x10 board must stay under `16666` usec.
- Data ownership: gameplay grid and solver state never mutate from VFX.
- Renderer ownership: live VFX draw in `PipeVfxLayer`; legacy sprite overlay remains documented separately.
- SSOT: theme values live in `ThemeConfig` and theme resources, not renderer literals.
- Budget: board-scale effects need count caps from theme data.
- Integration: new skins must match canonical asset geometry and anchors before tuning effect values.
- Owner question gate: design owner approval is required before new effect work. Confirm visual intent, effect role, trigger rules, layering, asset source, SSOT params, performance budget, no fallback rule, and acceptance evidence.
- Capture evidence: every visual change needs focused tests plus screenshot or visible Godot debug review.

## A-Z Integration Checkpoints

- Checkpoint A: record owner-approved visual intent.
- Checkpoint B: identify gameplay data source and effect trigger.
- Checkpoint C: choose renderer owner; prefer `PipeVfxLayer` for live effects.
- Checkpoint D: choose canonical geometry anchors and route helper.
- Checkpoint E: add RED contract test for data, params, caps, and motion.
- Checkpoint F: add `ThemeConfig` SSOT fields and theme resource values.
- Checkpoint G: add data method returning reusable effect dictionaries.
- Checkpoint H: draw in deterministic layer order without gameplay mutation.
- Checkpoint I: join `has_active_motion(...)` only when effect animates.
- Checkpoint J: cap records and include board-scale effects in 60 FPS budget.
- Checkpoint K: document Trigger, Data source, Renderer, SSOT, Budget, and Integration here.
- Checkpoint L: document parameter meanings in `docs/vfx_effect_parameters.md`.
- Checkpoint M: add capture evidence or visible debug screenshot.
- Checkpoint N: run focused tests plus adjacent regression tests.
- Checkpoint O: tune by SSOT params first.
- Checkpoint P: verify no fallback paths or hidden alternate assets.
- Checkpoint Q: inspect route alignment and duplicate effects.
- Checkpoint R: inspect contrast and layer readability against active theme.
- Checkpoint S: inspect source/target fixed endpoint behavior.
- Checkpoint T: inspect solved and unsolved state differences.
- Checkpoint U: update `docs/fake3d_vfx_checklist.md`.
- Checkpoint V: list final parameter values useful for shared VFX library.
- Checkpoint W: keep capture/debug artifacts named by purpose.
- Checkpoint X: get owner visual approval in visible Godot debug.
- Checkpoint Y: note warnings that remain external/pre-existing.
- Checkpoint Z: final report includes changed files, tests, screenshot paths, and remaining risks.

## static_energy_overlay

- Trigger: watered sprite overlay draw request.
- Data source: `GameScene` watered/target draw state and energy sheet manifest.
- Renderer: `GameScene._draw()`.
- SSOT: energy sheet manifest and theme overlay toggles.
- Budget: disabled for cyber pipe bodies by default; target overlay only when needed.
- Integration: use for static fill sheets, not live flow motion.

## contact_spark

- Trigger: energy enters a tile.
- Data source: transition/flow entry time and `VfxAnchor` input port.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_contact_spark_color`, `vfx_contact_spark_duration`, `vfx_contact_spark_radius_ratio`.
- Budget: one short spark per entered tile event.
- Integration: use as entry feedback, not persistent route glow.

## directional_trail

- Trigger: powered tile output during entry/fill.
- Data source: `FlowVisualState` and canonical route points.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_trail_color`, `vfx_trail_draw_enabled`, `vfx_trail_duration`, `vfx_trail_width_ratio`, `vfx_trail_min_alpha`.
- Budget: bounded by connected output edges.
- Integration: use for short leading fill, then let `idle_hum` and `path_wave` carry settled motion.

## source_emission

- Trigger: source tile has active output.
- Data source: source flow state and source geometry center.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_source_emission_color`, `vfx_source_emission_duration`, `vfx_source_emission_radius_ratio`, `vfx_source_emission_ring_width_ratio`.
- Budget: source-local effect only.
- Integration: use as source power feedback.

## target_pulse

- Trigger: target receives energy.
- Data source: target flow state and target geometry center.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_target_pulse_color`, `vfx_target_pulse_duration`, `vfx_target_pulse_radius_ratio`, `vfx_target_pulse_ring_width_ratio`.
- Budget: target-local effect only.
- Integration: use as arrival feedback.

## target_core_blink

- Trigger: target exists; idle before connection, powered after connection.
- Data source: target state and target `core_center`.
- Renderer: `GameScene` target draw path.
- SSOT: `target_core_idle_color`, `target_core_powered_color`, alpha bounds, radius values, `target_core_blink_period`.
- Budget: one target core draw.
- Integration: idle blink stays weak but visible; connected state brightens whole core over 8-frame intent.

## idle_hum

- Trigger: powered non-endpoint pipe after entry/fill delay.
- Data source: `FlowVisualState` and canonical route points.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_idle_hum_color`, delay, alpha, width ratios, radius ratio, period, pulse ratios.
- Budget: bounded by powered non-endpoint cells.
- Integration: use pipe-following aura, not tile-center circles.

## energy_stream

- Trigger: powered tile has active output.
- Data source: `FlowVisualState` order and canonical route points.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_energy_stream_enabled`, color, period, alpha, width ratios, shimmer segment ratio, pulse alpha ratio, order phase offset, max effects.
- Budget: capped by `vfx_energy_stream_max_effects`; one stream record per active powered output until cap.
- Integration: use as the continuous connected current under particles and lightning. It should make the pipe read as filled even when `path_wave` particles are between positions.

## path_wave

- Trigger: powered tile has active output.
- Data source: `FlowVisualState` order, max order, and canonical route points.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_path_wave_color`, draw toggle, period, segment ratio, width ratio, alpha, min/max particles, density curve, order phase offset, max effects.
- Budget: capped by `vfx_path_wave_max_effects`; particles scale from source-to-target progress.
- Integration: use as main moving energy; route line debug must stay hidden in final visuals.

## lightning_arc

- Trigger: powered output contact selected by sparse phase selector.
- Data source: `FlowVisualState`, output direction, canonical contact key, lightning sprite sheet.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_lightning_enabled`, texture, frame size, columns, rows, frame count, period, contact period, `vfx_lightning_color`, alpha, scale, max arcs, cell stride, minimum order progress, contact bias.
- Budget: capped by `vfx_lightning_max_arcs`; adjacent tiles share one canonical contact key.
- Integration: place near pipe contact as accent. Use electric cyan with icy-white core on black/green cyber theme; avoid green so it does not blend with path energy. Treat `vfx_lightning_period` as one full sheet cycle; current cyber atlas uses all 250 original 60 FPS frames.

## rotation_spark

- Trigger: valid player rotation.
- Data source: rotation event cell and geometry energy center.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_rotation_spark_color`, duration, radius ratio, ray count, width ratio.
- Budget: one short event per valid rotation.
- Integration: use input feedback only.

## disconnect_decay

- Trigger: powered cells lose connection after rotation.
- Data source: transition lost-cell state.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_disconnect_decay_color`, `vfx_disconnect_decay_duration`, `vfx_disconnect_decay_alpha`.
- Budget: bounded by lost powered cells.
- Integration: use as fade-out feedback after broken route.

## error_spark

- Trigger: powered contacts break after rotation.
- Data source: transition lost-contact state and geometry port anchors.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_error_spark_color`, `vfx_error_spark_duration`, `vfx_error_spark_radius_ratio`.
- Budget: bounded by lost contacts.
- Integration: use as short failure accent, not persistent warning.

## win_burst

- Trigger: solver state becomes solved.
- Data source: win event time, powered path cells sorted by `FlowVisualState.order`.
- Renderer: `PipeVfxLayer`.
- SSOT: `vfx_win_burst_color`, duration, radius ratio, ring width ratio, max cells.
- Budget: capped by `vfx_win_burst_max_cells`.
- Integration: use as solved-path celebration after target connection.
