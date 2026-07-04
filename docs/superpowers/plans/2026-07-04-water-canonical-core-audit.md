# Water Canonical Names And Shared Core Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit Bloxchain and Glyphflow Arrays for shared Shinokute core candidates, then remove stale Waternet/Water labels from active Glyphflow code paths.

**Architecture:** Keep reusable cross-game systems in `Shared/ShinokuteGameCore` and game-specific rendering, pipe routing, skins, assets, VFX routes, and UI coordinates inside each game. Do not rename Godot project folders during this pass because `res://` imports and release docs still reference the current folder layout.

**Tech Stack:** Godot 4.3, GDScript, Git submodule, PowerShell, Firebase Hosting docs.

---

### Task 1: Audit Common Modules

**Files:**
- Create: `C:/w/water/docs/shared_core_migration_audit.md`
- Modify: `C:/Users/Admin/Desktop/ShinokuteGameCore/docs/shared_core_migration_candidates.md`
- Modify: `C:/Users/Admin/Desktop/ShinokuteGameCore/README.md`

- [ ] **Step 1: List matching module names**

Run:
```powershell
rg --files 'C:\Users\Admin\Desktop\Game' | rg "(AudioManager|SaveManager|ThemeManager|SceneRouter|AdManager|Leaderboard|Username|Settings|Overlay|Transition|firebase|audio_pipeline|asset_optimization|runtime_asset_manifest|export_presets|project.godot)"
rg --files 'C:\w\water\WaternetGodot_Cyberpunk' | rg "(AudioManager|SaveManager|ThemeManager|SceneRouter|AdManager|Leaderboard|Username|Settings|Overlay|Transition|ProfilePopup|pipe_vfx|vfx_|audio_pipeline|asset_optimization|runtime_asset_manifest|firebase|export_presets|project.godot)"
```
Expected: both games contain overlapping audio, save, scene routing, theme, ads, leaderboard, overlay, publish, and docs patterns.

- [ ] **Step 2: Record migration candidates**

Write an audit that ranks candidates:
```text
P0: AudioCore, PublishCore
P1: SceneTransitionCore, OverlayCore, AdCore
P2: ThemeTokenCore, VfxCatalogCore
Keep game-local: grid rules, pipe geometry, generated UI coordinates, concrete skin assets
```

- [ ] **Step 3: Update core repo roadmap**

Add the same candidate list to ShinokuteGameCore docs, marking which files in Bloxchain and Glyphflow prove overlap.

### Task 2: Canonical Name Cleanup

**Files:**
- Modify: `C:/w/water/WaternetGodot_Cyberpunk/Tests/test_energy_animation_timing.gd`
- Modify: `C:/w/water/WaternetGodot_Cyberpunk/Scenes/Gameplay/GameScene.gd`
- Modify: `C:/w/water/WaternetGodot/Tests/test_energy_animation_timing.gd`
- Modify: `C:/w/water/WaternetGodot/Scenes/Gameplay/GameScene.gd`

- [ ] **Step 1: Replace stale semantic labels**

Change stale water-themed assertion text to:
```gdscript
"Energized tile frame should read FlowVisualState age"
"Energized tile should advance by FlowVisualState age"
```

- [ ] **Step 2: Replace stale render comment**

Change stale endpoint render comments to:
```gdscript
# PASS 2 & 3: Draw conduits and energy endpoints
```

### Task 3: Verify

**Files:**
- Test: `C:/w/water/WaternetGodot_Cyberpunk/Tests/test_energy_animation_timing.gd`
- Test: `C:/w/water/WaternetGodot/Tests/test_energy_animation_timing.gd`

- [ ] **Step 1: Run active project test**

Run:
```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\w\water\WaternetGodot_Cyberpunk' --script 'C:\w\water\WaternetGodot_Cyberpunk\Tests\test_energy_animation_timing.gd'
```
Expected: `test_energy_animation_timing: PASS`.

- [ ] **Step 2: Run legacy project test if present**

Run:
```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\w\water\WaternetGodot' --script 'C:\w\water\WaternetGodot\Tests\test_energy_animation_timing.gd'
```
Expected: pass if legacy test exists, otherwise skip with note.

- [ ] **Step 3: Scan remaining stale names**

Run:
```powershell
rg -n "Waternet|waternet|Watered|Water Pumps|Water Flow" C:\w\water -g '!**/Export/**' -g '!**/debug/**'
```
Expected: no runtime code hits except legacy path docs/manifests that intentionally mention current folder names.

### Task 4: Commit

**Files:**
- Stage only files changed in this plan.

- [ ] **Step 1: Commit core repo doc update**

Run:
```powershell
git -C 'C:\Users\Admin\Desktop\ShinokuteGameCore' add README.md docs/shared_core_migration_candidates.md
git -C 'C:\Users\Admin\Desktop\ShinokuteGameCore' commit -m "docs: document next shared core candidates"
git -C 'C:\Users\Admin\Desktop\ShinokuteGameCore' push origin main
```

- [ ] **Step 2: Commit water branch update**

Run:
```powershell
git -C 'C:\w\water' add docs/superpowers/plans/2026-07-04-water-canonical-core-audit.md docs/shared_core_migration_audit.md WaternetGodot_Cyberpunk/Tests/test_energy_animation_timing.gd WaternetGodot_Cyberpunk/Scenes/Gameplay/GameScene.gd WaternetGodot/Tests/test_energy_animation_timing.gd WaternetGodot/Scenes/Gameplay/GameScene.gd Shared/ShinokuteGameCore
git -C 'C:\w\water' commit -m "docs: audit shared core and canonical water naming"
git -C 'C:\w\water' push origin codex/water-canonical-names
```
