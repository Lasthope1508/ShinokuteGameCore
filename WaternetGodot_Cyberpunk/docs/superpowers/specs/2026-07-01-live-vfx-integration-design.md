# Live VFX Integration Design

Date: 2026-07-01
Project: WaternetGodot_Cyberpunk

## Goal

Integrate cyber electric VFX into live gameplay without moving gameplay authority out of the solver. VFX must make energy direction readable, respond to rotation changes, and stay separate from base pipe rendering.

## Approved Direction

- Style: electric energy running through pipes.
- Timing: hybrid rhythm. The source fires quickly, then each active tile shows short trail/fill motion.
- Disconnect: old powered path decays quickly, with a tiny error spark at the broken contact.
- Visibility: only truly powered flow gets VFX. No solution-path ghosting and no hint-like spoil.
- Intensity: medium. Trails, contact sparks, source emission, target pulse, and idle hum must be visible without covering pipe shape.
- Branching: T and X tiles emit along every connected powered output in `FlowVisualState.output_dirs`.
- Layering: base pipe below, energy fill as persistent state, VFX above energy fill.
- Debug: production toggle on/off plus dev/capture overlay for anchors, port directions, and flow order.
- Trigger: hybrid event plus solver SSOT. Solver state decides truth; rotate/reset events create transition data for animation only.

## Architecture

### Gameplay Authority

`ConnectionSolver` and `FlowVisualState` remain the source of truth for what is powered. VFX never mutates `PipeGrid`, solver result, moves, level data, or win state.

### Transition Data

`GameScene.try_rotate_cell(...)` will capture old and new flow state around a rotation:

1. Read previous `flow_visual_state`.
2. Rotate tile through canonical `PipeGrid.rotate_tile(...)`.
3. Reset/rebuild energy timing as needed.
4. Recompute solver and new `flow_visual_state`.
5. Send a transition package to `PipeVfxLayer`.

Transition package fields must be canonical and data-only:

- `previous_flow_state`
- `current_flow_state`
- `changed_cell`
- `lost_cells`
- `entered_cells`
- `lost_contacts`
- `entered_contacts`
- `event_time`

### VFX Layer

`PipeVfxLayer` consumes:

- current `flow_visual_state`
- transition package
- geometry anchors from `AssetGeometryConfig`
- theme VFX SSOT fields
- elapsed time

It draws:

- source emission pulse
- directional trail
- contact spark
- target receive pulse
- disconnect decay
- tiny error spark
- idle hum
- optional debug overlay

### Theme SSOT

All VFX sizes, colors, durations, alpha, widths, debug colors, and decay timing must live in `ThemeConfig` and the active theme resource. No hardcoded effect constants in `GameScene`.

Required new or confirmed fields:

- `vfx_disconnect_decay_duration`
- `vfx_disconnect_decay_alpha`
- `vfx_error_spark_color`
- `vfx_error_spark_duration`
- `vfx_error_spark_radius_ratio`
- `vfx_debug_anchor_color`
- `vfx_debug_input_color`
- `vfx_debug_output_color`
- `vfx_debug_order_color`

Existing VFX fields for source emission, target pulse, contact spark, directional trail, and idle hum must be reused.

## Data Flow

Normal rotation:

1. User clicks or taps a cell.
2. `_unhandled_input(...)` maps screen point through `get_cell_at_screen_position(...)`.
3. `try_rotate_cell(...)` rotates source, target, or pipe.
4. Solver rebuilds powered state.
5. `GameScene` syncs flow visual state and VFX layer.
6. `PipeVfxLayer` derives transient effects from transition data and current state.
7. Energy fill remains visible as persistent powered state.
8. VFX fades or idles based on configured timing.

Reset:

1. `reset_current_level(...)` clears moves, energy starts, flow visual state, and transition state.
2. VFX layer clears active transient effects.
3. No stale spark/trail remains after reset.

## Effect Rules

### Enter Trail

New powered cells receive a short directional trail from input port to energy center and then to every output port. Source cells use source emission before trail when they have active outputs.

### Contact Spark

A small spark appears at the contact where energy newly enters a non-source tile.

### Target Pulse

The target emits a receive pulse when it becomes powered.

### Disconnect Decay

Cells that were powered and are no longer powered fade for a short duration. The fade must be clearly weaker than live energy fill.

### Error Spark

When a rotation breaks an active contact, show a tiny warm spark at the lost contact. This must be small enough to read as feedback, not as powered energy.

### Idle Hum

Stable powered cells show a light idle hum after entry/trail/pulse windows finish. Idle hum excludes any effect that could look like a new path hint.

## Debug Overlay

Debug overlay must be optional and separate from normal VFX:

- anchor points
- input direction
- output directions
- flow order labels or small marks
- contact points for entered/lost contacts

The overlay is for capture/dev only and must not change gameplay or production visual defaults.

## Tests

Add contracts before implementation:

- `test_vfx_transition_state.gd`: diff old/new flow into entered/lost cells and contacts.
- `test_pipe_vfx_disconnect_decay.gd`: lost cells produce decay data within theme timing.
- `test_pipe_vfx_error_spark.gd`: broken contacts produce tiny error spark at geometry anchor.
- `test_game_scene_vfx_transition_hooks.gd`: `try_rotate_cell(...)` sends transition data to `PipeVfxLayer`.
- `test_vfx_debug_overlay_contract.gd`: debug overlay is toggleable and data-only.

Update or add captures:

- `capture_live_vfx_integration.gd`: before rotation, after connection, after disconnect.
- `capture_vfx_debug_overlay.gd`: anchor/direction/order overlay.

## Non-Goals

- No solution ghost path.
- No hint system.
- No VFX-driven gameplay state.
- No runtime AI/fallback asset generation.
- No new sprite generation for this step unless existing assets cannot support the contract.

## Acceptance

- Full `test_*.gd` suite passes.
- Full `capture_*.gd` suite passes.
- Live gameplay capture shows electric VFX only on powered path.
- Disconnect capture shows quick decay and tiny error spark.
- Debug capture shows anchors/directions/order without affecting normal capture.
- Checklist step 17 documents all completed contracts.
