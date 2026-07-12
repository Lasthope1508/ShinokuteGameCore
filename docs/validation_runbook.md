# Quantum Starter Reskin Validation Runbook

Run this before claiming the reskin works. A failed gate blocks completion.

## Variables

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
Set-Location $project
```

Engine note:
- The source README says Godot 4.6.
- The current machine only exposed Godot 4.3 in `C:\Users\Admin\.gemini\antigravity\bin\Godot`.
- If import or launch fails due to engine version, stop and use an owner-approved Godot 4.6 console binary. Do not mark validation passed with a mismatched engine.

## Mandatory Bug-Fix Research Gate

Before changing code for any bug, reproduce or define the failing contract first, then search and read current docs or real use cases for the exact failure class. Do not patch from guesses.

Required evidence before the fix:
- Search query or source path used for the failure class.
- Docs/use-case takeaway that explains the suspected mechanism.
- Failing local contract, smoke, or manual reproduction note.
- Fix scope and owner module, especially whether behavior belongs in Shinokute core or the Candy wrapper.

For Web, mobile, camera, pointer, audio, Firebase/export, Godot engine, Blender/MCP, 9Router, Photoroom, or platform-specific issues, the research source must include the relevant official docs or a concrete implementation/use-case source. Record the takeaway in `docs/reskin_state.md` or the relevant SSOT before claiming the bug is fixed.

## Gate 0: Required Files

```powershell
$required = @(
  'README.md',
  'LICENSE.md',
  'project.godot',
  'scenes/main.tscn',
  'docs/reskin_checklist.md',
  'docs/asset_manifest.md',
  'docs/validation_runbook.md'
)
$missing = $required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $project $_)) }
if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Error "Missing required file: $_" }
  exit 1
}
Write-Host 'Gate 0 PASS: required files exist'
```

Expected:
- Exit code `0`.
- Output contains `Gate 0 PASS`.

## Gate Core: Boundary Audit

Run before moving reusable behavior into `addons/shinokute_game_core`, after core edits, and before cloning this reskin pattern into another game.

```powershell
& $godot --headless --path $project --script "$project\tests\test_shinokute_reskin_core_audit_contract.gd"
if ($LASTEXITCODE -ne 0) {
  Write-Error "ShinokuteReskinBoundaryAudit contract failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}

& $godot --headless --path $project --script "$project\tests\test_shinokute_3d_controller_core_contract.gd"
if ($LASTEXITCODE -ne 0) {
  Write-Error "Core/controller boundary contract failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}
Write-Host 'Gate Core PASS: Shinokute core boundary audit clean'
```

Expected:
- `ShinokuteReskinBoundaryAudit` exists in core.
- Core scripts do not contain game names, skin paths, JS globals, DOM ids, or duplicate game-local schema names.
- Game scenes/wrappers may wire their own `GameCore`, theme config, UI skin, progression data, and platform adapters.
- Reusable infinite progression behavior lives in Shinokute core
  (`ShinokuteDynamicProgressionResolver`, `ShinokuteObbyRouteGenerator3D`, and
  catalog API), while Candy owns only `dynamic_progression_profile` curve data
  and game-specific environment/decor adapters. Run
  `tests/test_shinokute_3d_obby_progression_core_contract.gd`,
  `tests/test_dynamic_obby_progression_contract.gd` and
  `tests/test_obby_route_solvability_contract.gd` after progression core edits
  to prove deterministic fair levels and jump-envelope safety.

## Gate 1: Approval And Fallback Scan

Run after Checkpoint 1 is recorded in `docs/reskin_checklist.md`.

```powershell
$checklist = Get-Content -LiteralPath 'docs/reskin_checklist.md' -Raw
if ($checklist -notmatch '- \[x\] Owner approved theme name\.') { Write-Error 'Checkpoint 1 missing: theme name'; exit 1 }
if ($checklist -notmatch '- \[x\] Owner approved art style\.') { Write-Error 'Checkpoint 1 missing: art style'; exit 1 }
if ($checklist -notmatch '- \[x\] Owner approved 5-color palette\.') { Write-Error 'Checkpoint 1 missing: palette'; exit 1 }

$scanRoots = @('scenes', 'objects', 'scripts', 'Resources', 'assets', 'models', 'sprites', 'sounds', 'fonts')
$existingScanRoots = $scanRoots | Where-Object { Test-Path -LiteralPath $_ }
$bad = $null
if ($existingScanRoots.Count -gt 0) {
  $bad = rg -n 'fallback|TODO|TBD|placeholder asset|random generated' @existingScanRoots
}
if ($LASTEXITCODE -eq 0) {
  Write-Error "Forbidden or unresolved marker found:`n$bad"
  exit 1
}
Write-Host 'Gate 1 PASS: owner approval recorded and forbidden markers clean'
```

Expected:
- Exit code `0`.
- No fallback or unresolved marker in changed production files.

## Gate 2: Asset Manifest Coverage

Run after any asset, scene visual, material, HUD, audio, or skybox change.

```powershell
$manifest = Get-Content -LiteralPath 'docs/asset_manifest.md' -Raw
$changedAssetRoots = @(
  'res://assets/themes/',
  'res://models/',
  'res://sprites/',
  'res://sounds/',
  'res://fonts/'
)

foreach ($root in $changedAssetRoots) {
  if ($manifest -match [regex]::Escape($root)) {
    continue
  }
}

$requiredAcceptedFields = @('Asset Key', 'Path', 'Source', 'Status', 'Owner Rect', 'Padding', 'In-game Size')
foreach ($field in $requiredAcceptedFields) {
  if ($manifest -notmatch [regex]::Escape($field)) {
    Write-Error "Asset manifest missing field: $field"
    exit 1
  }
}

Write-Host 'Gate 2 PASS: asset manifest schema present'
```

Expected:
- Exit code `0`.
- Any new accepted asset has a row with role, key, path, source, status, owner rect, padding, in-game size, and proof screenshot.

Manual blocker:
- If a changed asset row says `not approved`, `blocked`, or `none` for proof after integration, do not continue to completion.

## Gate 3: SSOT Coverage

Run after SSOT files are created.

```powershell
$ssotCandidates = @(
  'Resources/QuantumThemeConfig.gd',
  'Resources/Data/Themes'
)
$exists = $ssotCandidates | Where-Object { Test-Path -LiteralPath $_ }
if ($exists.Count -eq 0) {
  Write-Error 'No Quantum theme SSOT found. Create Resources/QuantumThemeConfig.gd or Resources/Data/Themes before visual scene edits.'
  exit 1
}

$skinFiles = @(
  'scenes/main.tscn',
  'objects/player.tscn',
  'objects/coin.tscn',
  'scenes/main-environment.tres'
)
foreach ($file in $skinFiles) {
  if (Test-Path -LiteralPath $file) {
    Write-Host "Review skin file for SSOT-backed changes: $file"
  }
}
Write-Host 'Gate 3 PASS: SSOT location exists; manual scene review still required'
```

Expected:
- Exit code `0`.
- SSOT exists before final scene visual integration.

Manual blocker:
- No changed color, font, asset path, material override, particle color, HUD rect, or audio event may exist only as a scattered scene/script constant.

## Gate 4: Godot Import

```powershell
& $godot --headless --path $project --import
if ($LASTEXITCODE -ne 0) {
  Write-Error "Godot import failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}
Write-Host 'Gate 4 PASS: Godot import succeeded'
```

Expected:
- Exit code `0`.
- No parse errors.
- No missing resource errors for changed assets.

## Gate 4B: Web Payload Hygiene

Before running this gate for Candy Sky Islands packaging or Firebase deploy,
read `docs/packaging_handoff.md`. That file owns the current Web packaging
scope, the `Export/` versus `Export_web_test/` folder split, Firebase project,
preview channel, required sync step, and final report fields. If the handoff
and the command being run disagree, stop and fix the handoff or command first.

Run after any export preset, `.import`, audio, asset, `.gdignore`, or selected-resource change.

```powershell
$pck = Join-Path $project 'Export\candy_sky_islands.pck'
if (-not (Test-Path -LiteralPath $pck)) {
  Write-Error "Missing Web PCK: $pck"
  exit 1
}

$paths = & rg -a -o 'res://[A-Za-z0-9_./:@-]+' $pck | Sort-Object -Unique
$bad = $paths | Where-Object {
  $_ -match 'docs/|debug/|tests/|tools/|source/|_raw\.png|candidate|models/Textures/colormap\.png|meshes/dust\.res|meshes/brick\.res|Assets/3D|C:/Users/Admin'
}
if ($bad) {
  Write-Error "PCK forbidden marker scan failed:`n$($bad -join "`n")"
  exit 1
}
Write-Host "Gate 4B PASS: PCK forbidden marker scan clean; path_count=$($paths.Count)"
```

Expected:
- Exit code `0`.
- No `docs`, `debug`, `tests`, `tools`, `source`, raw, candidate, local absolute path, legacy root mesh, or old colormap markers in Web PCK.
- `models/.gdignore`, `meshes/.gdignore`, `assets/themes/candy_sky_islands/source/.gdignore`, and `assets/themes/candy_sky_islands/source/branding_raw/.gdignore` exist when legacy/source evidence remains on disk.

## Gate 4C: Android Payload Hygiene

Before running this gate for Candy Sky Islands Android export, Play Store
handoff, or package-ready claims, read `docs/android_packaging_runbook.md`.
That file owns the Android preset, package id, version policy, signing handoff,
template patch rule, AAB scan/deep scan commands, Play upload notes, device
smoke checklist, and final report fields.

Run Gate 4C from `docs/android_packaging_runbook.md` after every fresh Android
export. If this runbook and the command being run disagree, stop and fix the
Android packaging runbook or command first. Do not copy the Android scan script
back into this file.

Expected:
- Exit code `0`.
- No `docs`, `debug`, `tests`, `tools`, `source`, raw, candidate, local absolute path, legacy root mesh, or old colormap markers in Android AAB.
- Report Android package id, version code/name, signing status, AAB size, and device smoke result before any Play Store handoff.

## Gate 5: Gameplay Smoke

Launch the project:

```powershell
& $godot --path $project
```

Manual smoke path:
- Main scene loads.
- Player moves with keyboard/gamepad input.
- Player jumps and double-jumps.
- Camera rotates and zooms.
- Coin pickup increments HUD.
- Falling platform behavior remains intact.
- Player falling below world retries the current level in-place without SceneTree reload.
- New/changed visuals render, with no blank materials or missing textures.
- Console output reviewed.

Expected:
- No new runtime errors.
- No missing resource spam.
- Gameplay behavior unchanged unless owner approved behavior changes.

## Gate 6: Screenshot Evidence

Capture and record paths in `docs/reskin_checklist.md`:
- Desktop gameplay before first pickup.
- Desktop gameplay after coin pickup.
- Close-up HUD text/icon.
- Mobile or narrow viewport only if mobile scope is approved.

Manual blockers:
- Text overlaps icon or gameplay.
- HUD text escapes owner rect.
- Scene reads as generic UI rather than game screen.
- Any approved asset appears cropped, stretched, or off-theme.

## Gate 7: Completion Report

Final report must include:
- Changed files.
- Changed SSOT files.
- Changed asset manifest rows.
- Tests and gates run, with pass/fail.
- Screenshot paths.
- Known warnings, including Godot version if 4.3 was used for a 4.6 source.
- Any unapproved scope left untouched.
