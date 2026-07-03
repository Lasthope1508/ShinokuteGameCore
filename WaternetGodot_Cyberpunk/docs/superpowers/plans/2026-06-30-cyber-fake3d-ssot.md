# Cyber Fake3D SSOT Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move cyber visual constants into theme SSOT, centralize canonical pipe helpers, then add a controlled fake3D render pass.

**Architecture:** `ThemeConfig` owns visual parameters. `PipeVisualMapping` owns canonical port/rotation/flow-mask helpers. `GameScene` only asks theme/helper for values and draws, with no gameplay logic changes.

**Tech Stack:** Godot 4.3, GDScript resources, existing cyber theme `.tres`, headless Godot tests.

---

### Task 1: SSOT Tests

**Files:**
- Create: `Tests/test_fake3d_visual_config.gd`
- Modify: none

- [ ] Write a failing test that loads `ThemeConfig`, checks fake3D properties exist, validates cyber theme values, and checks `PipeVisualMapping` exposes canonical helpers.
- [ ] Run the test and expect failure before implementation.

### Task 2: Theme SSOT

**Files:**
- Modify: `Resources/Classes/ThemeConfig.gd`
- Modify: `Resources/Data/Themes/cyberpunk_theme.tres`

- [ ] Add exported fake3D visual properties to `ThemeConfig`.
- [ ] Configure cyber theme values in `.tres`.
- [ ] Keep defaults neutral so wood/garden remain stable.

### Task 3: Canonical Mapping Helpers

**Files:**
- Modify: `Scripts/pipe_visual_mapping.gd`
- Modify: `Scenes/Gameplay/GameScene.gd`

- [ ] Add generic `get_local_flow_mask()`, `get_rotation_index_for_ports()`, and `get_tile_offset()` helpers.
- [ ] Replace duplicated I/T/X/L local-mask logic in `GameScene`.
- [ ] Remove scene-owned `TILE_OFFSETS`.

### Task 4: Fake3D Render Pass

**Files:**
- Modify: `Scenes/Gameplay/GameScene.gd`

- [ ] Draw textured cell backgrounds with theme-controlled inset, bevel, and border overlay.
- [ ] Draw pipe contact shadow from theme-controlled offset/alpha.
- [ ] Keep gameplay grid, solver, and texture selection unchanged.

### Task 5: Verification

**Files:**
- Test: `Tests/test_fake3d_visual_config.gd`
- Test: `Tests/test_l_pipe_visual_mapping.gd`
- Test: `Tests/test_level_randomization.gd`

- [ ] Run each headless test and expect `exit=0`.
- [ ] Run headless scene load and expect `exit=0`.
- [ ] Capture/inspect a debug screenshot if MCP/browser route is available.
