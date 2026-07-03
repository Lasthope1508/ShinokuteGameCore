# Cyber Energy Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate 8-frame cyberpunk energy progression sprite sheets from the standardized 512x512 pipe assets.

**Architecture:** A PowerShell/System.Drawing generator reads each existing pipe slice PNG, builds horizontal 8-frame sheets, and writes a manifest JSON for future Godot animation import. The generator does not create new style art; it uses existing base and energized assets only.

**Tech Stack:** PowerShell 5, .NET System.Drawing, Godot 4.3 PNG imports.

---

### Task 1: Generator And Assets

**Files:**
- Create: `Tools/generate_cyber_energy_sheets.ps1`
- Create: `Assets/Themes/cyberpunk_theme/energy_sheets/**`
- Create: `Assets/Themes/cyberpunk_theme/energy_sheets/manifest.json`

- [ ] **Step 1: Add generator**

Create `Tools/generate_cyber_energy_sheets.ps1` with constants `FrameCount = 8`, `CellSize = 512`, and output root `Assets/Themes/cyberpunk_theme/energy_sheets`.

- [ ] **Step 2: Generate sheets**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\generate_cyber_energy_sheets.ps1
```

Expected output includes generated sheet count and manifest path.

- [ ] **Step 3: Verify sheet dimensions**

Each generated sheet must be `4096x512` pixels. Frame 0 must match the base unenergized asset, and frame 7 must match the energized target asset for that slice.

- [ ] **Step 4: Build preview**

Create `debug/cyber_energy_sheet_preview.png` using representative generated sheets: `i_slice_1`, `l_slice_1`, `t_slice_7`, `cross_slice_11`, `source`, and `target_slice_1`.

- [ ] **Step 5: Godot import check**

Run:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --import
```

Expected: exit code `0`. Existing UID warning may remain.
