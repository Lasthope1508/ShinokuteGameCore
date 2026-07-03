# VFX Final Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish cyber gameplay VFX with solve, rotate, continuous path motion, performance caps, captures, checklist, and reusable parameter docs.

**Architecture:** Keep `PipeVfxLayer` as the only VFX renderer. `GameScene` sends small event dictionaries only. `ThemeConfig` and theme `.tres` own every visual parameter and cap.

**Tech Stack:** Godot 4.3, GDScript, existing headless test scripts under `Tests`.

---

### Task 1: Path Wave

**Files:**
- Modify: `Resources/Classes/ThemeConfig.gd`
- Modify: `Resources/Data/Themes/cyberpunk_theme.tres`
- Modify: `Scripts/pipe_vfx_layer.gd`
- Test: `Tests/test_pipe_vfx_path_wave.gd`

- [ ] Write RED test requiring `get_path_waves(now)` and theme fields.
- [ ] Add theme params: color, period, segment ratio, width ratio, alpha, max effects.
- [ ] Implement data and draw methods in `PipeVfxLayer`.
- [ ] Include path wave in `has_active_motion()`.
- [ ] Run focused test.

### Task 2: Rotate Spark

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`
- Modify: `Scenes/Gameplay/GameScene.gd`
- Test: `Tests/test_pipe_vfx_rotation_spark.gd`
- Test: `Tests/test_game_scene_vfx_polish_hooks.gd`

- [ ] Write RED tests for `set_rotation_event(...)`, `get_rotation_sparks(...)`, and GameScene hook.
- [ ] Add theme params: color, duration, radius ratio, rays, width ratio.
- [ ] Trigger event after valid `try_rotate_cell(...)`.
- [ ] Clear event on reset.
- [ ] Run focused tests.

### Task 3: Win Burst

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`
- Modify: `Scenes/Gameplay/GameScene.gd`
- Test: `Tests/test_pipe_vfx_win_burst.gd`
- Test: `Tests/test_game_scene_vfx_polish_hooks.gd`

- [ ] Write RED tests for `set_win_state(...)`, `get_win_bursts(...)`, and solve hook.
- [ ] Add theme params: color, duration, radius ratio, ring width ratio, max cells.
- [ ] Trigger win event exactly when solved.
- [ ] Clear event on reset.
- [ ] Run focused tests.

### Task 4: Performance And Library Docs

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`
- Modify: `docs/fake3d_vfx_checklist.md`
- Create: `docs/vfx_effect_parameters.md`
- Test: `Tests/test_vfx_performance_10x10.gd`
- Test: `Tests/test_vfx_effect_parameter_catalog.gd`

- [ ] Write RED catalog test requiring all current VFX params documented.
- [ ] Cap path wave and win burst counts by theme SSOT.
- [ ] Document each effect, trigger, required anchors, and parameters.
- [ ] Update fake3D checklist with completed steps.
- [ ] Run full test and capture suites.
