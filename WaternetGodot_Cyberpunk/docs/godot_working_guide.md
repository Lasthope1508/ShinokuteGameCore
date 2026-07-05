# Godot Working Guide

Purpose: mandatory working notes for agents touching this Godot project. Read this before editing GDScript, scenes, exports, tests, debug windows, or packaging. Do not guess Godot behavior when this document names a command or rule.

## Canonical Project

- Project path: `C:\w\water\WaternetGodot_Cyberpunk`.
- Project name: `Glyphflow Arrays`.
- Engine: Godot `4.3.stable.official.77dcf97d8`.
- Visible game scene for owner testing: `res://Scenes/Gameplay/GameScene.tscn`.
- Main scene: `res://Scenes/Common/Splash.tscn`.
- Debug details live in `res://docs/godot_debug_runbook.md`.
- Release details live in `res://docs/release_packaging_checklist.md`.

## Read Order

Before any Godot task:

1. Read this file.
2. Read `res://docs/godot_debug_runbook.md` if opening Godot or using MCP/debug.
3. Read `res://docs/release_packaging_checklist.md` if exporting, deploying, or touching `export_presets.cfg`.
4. Read the feature-specific doc: UI, VFX, audio, asset optimization, or skin contract.
5. Inspect existing source patterns before editing.

## No Guessing Rules

- Do not invent Godot enum names, constants, method names, export flags, or import settings.
- If unsure, verify with existing source, Godot docs inside project, or a tiny compile test.
- This project treats many GDScript warnings as errors. A warning in a changed file can break runtime.
- No fallback assets, fallback paths, fallback API behavior, or invented default data unless owner approves the exact fallback.
- Do not say Godot debug is open unless the window is visible and `MainWindowHandle != 0`.
- Do not say a build works unless it reaches real gameplay and a real interaction passes.

## GDScript Compile Gate

Before running feature tests after adding or changing GDScript:

1. Save the file.
2. Run the smallest Godot test that loads the changed script.
3. Read the full output, including parse errors and warnings.
4. Fix all warnings from changed files. Warning-as-error is real in this repo.
5. Only then run broader tests.

Common failures:

- Variant inference with `:=` from `Dictionary.get()`, `max()`, `min()`, or untyped `load()` return. Use explicit types.
- Local variable names shadowing base properties such as `name`, `position`, `rotation`, `scale`, `tr`, or `draw_rect`.
- Godot enum constants remembered from another version. Verify names for Godot 4.3.
- `class_name` conflicts with existing global classes or autoload names.
- Headless viewport captures can return null. Visual captures must be windowed when current docs say so.

Minimal compile check pattern:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\w\water\WaternetGodot_Cyberpunk'
& $godot --headless --path $project --script 'C:\w\water\WaternetGodot_Cyberpunk\Tests\test_name_here.gd' 2>&1
```

If the output includes `SCRIPT ERROR`, `Parse Error`, or changed-file warnings, stop and fix those before continuing.

## Test Gate

- Add or update a focused test before changing behavior.
- Run the focused test and confirm it fails for the expected reason.
- After implementation, run the focused test again.
- For shared UI/layout/gameplay changes, run relevant adjacent tests.
- Before claiming completion, run `git diff --check`.
- Do not use screenshot/capture scripts as proof if docs say that script is unreliable in headless mode.

Full sweep pattern when needed:

```powershell
$ErrorActionPreference='Continue'
$PSNativeCommandUseErrorActionPreference=$false
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\w\water\WaternetGodot_Cyberpunk'
$tests=Get-ChildItem -Path "$project\Tests" -Filter 'test_*.gd' | Sort-Object Name
$failed=0
foreach ($test in $tests) {
  $output=& $godot --headless --path $project --script $test.FullName 2>&1
  $text=($output | Out-String)
  if ($LASTEXITCODE -ne 0 -or $text -match ': FAIL|GLYPH_TEST_FAILED=[1-9]|Result: SOME TESTS FAILED') {
    $failed++
    Write-Host "GLYPH_TEST_FAIL=$($test.Name)"
    Write-Host $text
  } else {
    Write-Host "GLYPH_TEST_PASS=$($test.Name)"
  }
}
Write-Host "GLYPH_TEST_FAILED=$failed"
if ($failed -gt 0) { exit 1 }
```

## Visible Debug

For owner-visible testing, use the GUI binary, not MCP `run_project` as the final step.

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64.exe'
$project = 'C:\w\water\WaternetGodot_Cyberpunk'
Start-Process -FilePath $godot -ArgumentList @('--path', $project, 'res://Scenes/Gameplay/GameScene.tscn') -WorkingDirectory $project -WindowStyle Normal
Start-Sleep -Seconds 4
Get-Process | Where-Object { $_.ProcessName -like 'Godot*' } | Select-Object ProcessName,Id,MainWindowTitle,MainWindowHandle,Responding
```

Passing visible state:

- `MainWindowTitle` contains `Glyphflow Arrays (DEBUG)`.
- `MainWindowHandle` is not `0`.
- `Responding` is `True`.
- Owner can see the window.

If `MainWindowHandle = 0`, stop that process and relaunch with the GUI binary.

## MCP Usage

- Godot MCP is useful for `get_project_info`, `run_project`, `get_debug_output`, and `stop_project`.
- MCP `run_project` may produce logs without a visible game window on this machine.
- Use MCP output as log evidence only, not as owner-visible UI evidence.
- If the user says "open Godot debug so I can test", use the visible debug command above and verify window handle.

## Process Hygiene

- Before starting a new visible debug, stop stale no-window Godot processes:

```powershell
Get-Process | Where-Object { $_.ProcessName -like 'Godot*' -and $_.MainWindowHandle -eq 0 } | Stop-Process -Force
```

- Do not kill a visible debug window the owner is testing unless owner asks or you need to restart after a fix.
- Keep console/headless Godot for automated tests only.

## Export And Packaging

- Use Godot export, not hand-built HTML/runtime files.
- `export_presets.cfg` must stay UTF-8 without BOM.
- If using selected resources, add every new runtime script/resource to both Web and Android selected resource lists.
- Clear import/export caches before final release when docs say stale cache can affect result.
- Web verification must reach gameplay and perform one tile interaction. Menu load is not enough.

## UI Text Gate

- UI text must have an owner rect, role, alignment, font limits, overflow policy, and test.
- Use `res://Scripts/ui_text_layout.gd` for general text roles.
- Specialized fitters are allowed only when documented and tested.
- Empty states, long usernames, long score rows, and translated-length strings must be tested.
- Fix text drift through SSOT role or owner rect, not node offsets.

## Final Response Gate

When reporting Godot work:

- Name changed files.
- Name exact tests run and pass/fail counts.
- Mention visible debug status if owner needs to test.
- Mention unresolved warnings only if they remain and are relevant.
- Never claim "done", "fixed", "ready", or "published" without fresh verification output from this turn.

## Legacy Debug Runbook Notes

The old debug runbook content is merged here so there is one Godot document to read.

# Godot Debug Runbook

Purpose: exact local workflow for opening and inspecting this Godot project without repeating MCP/debug setup mistakes.

## Tools Installed

- GoPeak MCP is installed globally as `gopeak@2.3.8`.
- Codex config points `[mcp_servers.godot]` to `C:\Users\Admin\AppData\Roaming\npm\node_modules\gopeak\build\cli.js`.
- Project addons are installed in `addons/auto_reload`, `addons/godot_mcp_editor`, and `addons/godot_mcp_runtime`.
- Runtime ports:
  - `9090`: legacy `McpInteractionServer` from `Scripts/mcp_interaction_server.gd`.
  - `7777`: GoPeak runtime addon from `addons/godot_mcp_runtime/mcp_runtime_autoload.gd`.
  - `6505`: GoPeak editor bridge.

## Visible Debug

Use visible debug when the human needs to see and test the game window.

Canonical local project path for this checkout:

```text
C:\w\water\WaternetGodot_Cyberpunk
```

Command:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64.exe'
$project = 'C:\w\water\WaternetGodot_Cyberpunk'
Start-Process -FilePath $godot -ArgumentList @('--path', $project, 'res://Scenes/Gameplay/GameScene.tscn') -WorkingDirectory $project -WindowStyle Normal
Start-Sleep -Seconds 4
Get-Process | Where-Object { $_.ProcessName -like 'Godot*' } | Select-Object ProcessName,Id,MainWindowTitle,MainWindowHandle,Responding
```

Expected:

- Window title: `Glyphflow Arrays (DEBUG)`.
- `MainWindowHandle` is not `0`.
- `Responding` is `True`.
- The human can see the gameplay window.

Do not use `Godot_v4.3-stable_win64_console.exe` for owner-visible debug on this machine. It can start a process with `MainWindowHandle = 0`, which gives logs but no testable game window.

Bring the window forward if needed:

```powershell
$p = Get-Process *Godot* | Where-Object { $_.MainWindowTitle -like '*DEBUG*' } | Select-Object -First 1
Add-Type 'using System; using System.Runtime.InteropServices; public class Win32Focus { [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd); }'
[Win32Focus]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[Win32Focus]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
```

## GoPeak Caveat

GoPeak/MCP `run_project` is useful for logs and non-visual validation, but on this machine it can launch a Godot process with no visible window handle. Do not use `run_project` as the final answer when the user asks to see the Godot window.

Older notes may call the same action `run-project`; the same caveat applies.

Use `run_project` only for non-visual MCP checks:

```json
{
  "name": "run_project",
  "arguments": {
    "projectPath": "C:/w/water/WaternetGodot_Cyberpunk",
    "scene": "res://Scenes/Gameplay/GameScene.tscn"
  }
}
```

If the task says visible debug, use the visible debug command above.
After launching, always run the `Get-Process` check and confirm `MainWindowHandle` is not `0`. If it is `0`, stop that process and relaunch with `Godot_v4.3-stable_win64.exe`.

## Health Checks

```powershell
Get-Process *Godot* | Select-Object Id,ProcessName,MainWindowTitle,MainWindowHandle
Test-NetConnection 127.0.0.1 -Port 9090
Test-NetConnection 127.0.0.1 -Port 7777
```

Passing state:

- `MainWindowTitle` contains `Glyphflow Arrays (DEBUG)`.
- `MainWindowHandle` is not `0`.
- Both ports return `TcpTestSucceeded = True`.

## Headless Tests

Headless tests must not bind runtime debug ports. Both runtime servers guard against headless mode:

- `Scripts/mcp_interaction_server.gd`
- `addons/godot_mcp_runtime/mcp_runtime_autoload.gd`

Use headless only for automated tests:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_pipe_vfx_lightning_arcs.gd
```
