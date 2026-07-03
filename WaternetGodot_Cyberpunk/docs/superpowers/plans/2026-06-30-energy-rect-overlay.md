# Energy Rect Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Draw cyber energy animation as a clipped overlay inside each asset geometry `energy_rect`, so later VFX reads the same SSOT and does not fight base sprite sizing.

**Architecture:** `AssetGeometryConfig` remains the source of frame, draw, and energy rectangles. `GameScene` draws the base texture first, then draws an energy atlas sub-region only for watered cells. Energy sheet lookup stays deterministic; no fallback pipeline.

**Tech Stack:** Godot 4.3, GDScript, existing cyber energy sheets, headless and windowed Godot tests.

---

### Task 1: Energy Overlay Contract

**Files:**
- Create: `Tests/test_energy_overlay_clip_contract.gd`
- Modify: `Scenes/Gameplay/GameScene.gd`

- [ ] Write a failing test for `GameScene._get_energy_frame_region_for_geometry(geometry, frame_index)`.
- [ ] Write a failing test for `GameScene._get_energy_draw_rect_for_geometry(geometry)`.
- [ ] Implement helpers using `AssetGeometryConfig.energy_rect` and `draw_origin`.
- [ ] Run the test and expect pass.

### Task 2: Runtime Draw Split

**Files:**
- Modify: `Scenes/Gameplay/GameScene.gd`
- Test: `Tests/capture_fake3d_screenshot.gd`
- Test: `Tests/capture_fake3d_size_sweep.gd`

- [ ] Draw shadows and base pipe with the unmodified base texture.
- [ ] Draw energy overlay only when watered and only inside `energy_rect`.
- [ ] Keep existing frame timing and sheet path lookup unchanged.
- [ ] Capture runtime screenshot and size sweep.

### Task 3: Regression

**Files:**
- Test: `Tests/test_energy_overlay_clip_contract.gd`
- Test: `Tests/test_asset_geometry_contract.gd`
- Test: `Tests/test_asset_port_alignment.gd`
- Test: `Tests/test_theme_geometry_ssot.gd`
- Test: `Tests/test_fake3d_visual_config.gd`
- Test: `Tests/test_l_pipe_visual_mapping.gd`
- Test: `Tests/test_level_randomization.gd`

- [ ] Run all listed tests.
- [ ] Restart Godot debug on `127.0.0.1:9090`.
