# VFX Final Polish Design

## Goal

Finish gameplay VFX for the cyber pipe puzzle while keeping solver and `FlowVisualState` as SSOT. Add solve celebration, continuous powered-path motion, rotate feedback, performance guardrails, and a reusable VFX parameter catalog.

## Scope

- Continuous path wave on powered pipe outputs after the initial fill.
- Rotate spark on the tile touched by `GameScene.try_rotate_cell(...)`.
- Win burst when `solver.check_connection(grid)` becomes true.
- VFX performance guardrails in `ThemeConfig`, enforced by `PipeVfxLayer`.
- Cyber polish through theme-controlled glow/scan style data, no runtime fallback.
- Checklist and separate parameter catalog for future shared VFX library work.

## Architecture

`PipeVfxLayer` remains the only VFX renderer. It reads `flow_state`, geometry anchors, theme parameters, and event dictionaries. `GameScene` only calls small event hooks after rotate, solve, or reset. All sizes, colors, durations, caps, and periods live in `ThemeConfig` and concrete theme resources.

## Data Flow

1. `GameScene.try_rotate_cell(...)` rotates grid and refreshes `flow_visual_state`.
2. `GameScene` sends transition event, rotation event, and solved event to `PipeVfxLayer`.
3. `PipeVfxLayer` derives draw data through `get_path_waves()`, `get_rotation_sparks()`, and `get_win_bursts()`.
4. `PipeVfxLayer.has_active_motion()` drives redraw while any timed or continuous effect is active.

## Effects

- Path wave: a short bright segment travels along each active output from input port to output port. It is continuous while powered path exists.
- Rotate spark: a brief radial spark centered on the changed tile energy center.
- Win burst: expanding rings over the powered path, capped for large boards.
- Performance guard: data methods trim generated effect arrays using theme caps.

## Testing

Add RED contract tests for each new effect and the GameScene hook. Add capture for final VFX polish. Run full `test_*.gd` and `capture_*.gd` suites.
