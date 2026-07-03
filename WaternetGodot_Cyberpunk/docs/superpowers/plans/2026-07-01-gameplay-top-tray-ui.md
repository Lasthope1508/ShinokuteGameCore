# Gameplay Top Tray UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the premium fake3D cyber gameplay top tray with real logo, settings, and leaderboard entry points.

**Architecture:** Keep gameplay state in `GameScene.gd`. Keep visual constants in `ThemeConfig` plus `cyberpunk_theme.tres`. `GameScene.tscn` owns the HUD node tree: `TopTrayRoot`, utility pods, real `LogoCore`, stat readouts, settings overlay, and leaderboard overlay mount.

**Tech Stack:** Godot 4.3 scenes, GDScript, existing `AudioManager`, `ThemeManager`, `ProfilePopup`, and source-scanned contract tests.

---

### Task 1: Top Tray Contract

**Files:**
- Create: `Tests/test_gameplay_top_tray_ui_contract.gd`
- Modify: `Scenes/Gameplay/GameScene.tscn`
- Modify: `Scenes/Gameplay/GameScene.gd`

- [x] Write a failing test that requires `TopTrayRoot`, `TrayShell`, `LogoCore`, utility pods, stats, settings overlay, leaderboard button, and no placeholder `WATERNET` tray text.
- [x] Run the test and verify it fails before implementation.
- [ ] Add the scene nodes and code hooks.
- [ ] Run the test and verify it passes.

### Task 2: Theme SSOT

**Files:**
- Modify: `Resources/Classes/ThemeConfig.gd`
- Modify: `Resources/Data/Themes/cyberpunk_theme.tres`
- Extend: `Tests/test_gameplay_top_tray_ui_contract.gd`

- [ ] Add top-tray dimensions, colors, icon button size, stat height, and board gap to `ThemeConfig`.
- [ ] Set cyber theme values in `cyberpunk_theme.tres`.
- [ ] Use those values in `GameScene.gd`, including board top margin calculation.
- [ ] Verify the test passes.

### Task 3: Settings And Leaderboard

**Files:**
- Modify: `Scenes/Gameplay/GameScene.tscn`
- Modify: `Scenes/Gameplay/GameScene.gd`
- Extend: `Tests/test_gameplay_top_tray_ui_contract.gd`

- [ ] Add settings overlay with music, SFX, restart, level select, and close controls.
- [ ] Add leaderboard overlay mount using existing `ProfilePopup`.
- [ ] Block board rotation while settings, leaderboard, or solved popup is visible.
- [ ] Route all button feedback through canonical SFX names.
- [ ] Run focused gameplay and UI tests.
