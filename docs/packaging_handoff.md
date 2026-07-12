# Candy Sky Islands Packaging Handoff

This is the first file to read before packaging, Web export, Firebase deploy,
payload-size audit, or any package-ready claim for Candy Sky Islands.

## Canonical Source

- Project root: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`
- Git branch: `game/candy-sky-islands`
- Git remote for this game branch: `shinokute-core`
- Remote branch: `shinokute-core/game/candy-sky-islands`
- Godot console on this machine: `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`
- Web preset name: `Web`
- Main scene: `res://scenes/main.tscn`
- Firebase project: `foodapp-7ff6b`
- Firebase preview channel for owner device testing: `candy-sky-islands-test`

Do not use `origin` for pushing this game branch. `origin` points at the
upstream Kenney starter kit. Use `shinokute-core` for Candy Sky Islands.

## Current Packaging Scope

Current supported package target is Web/HTML5 only.

Do not claim Android, Play Store, or full package-ready status. Android is
blocked until an Android export preset, signing profile, fresh AAB export, AAB
forbidden-marker scan, and Android size table exist.

## Runtime Source Of Truth

Packaging must use selected runtime resources from `export_presets.cfg`.

Rules:

- Keep `export_filter="resources"`.
- Do not switch to `export_filter="all_resources"`.
- Do not add broad `include_filter` patterns such as `*.png`, `*.ogg`,
  `*.tres`, `Assets/**`, or `assets/**`.
- If a runtime script preloads a new `res://...` helper, add it explicitly to
  `export_files` and update `tests/test_web_export_preset_contract.gd`.
- Keep raw/reference/candidate/debug docs out of runtime payload:
  `docs/`, `debug/`, `tests/`, `tools/`, `output/`, `assets/themes/candy_sky_islands/source/`,
  root `models/`, root `meshes/`, `_raw.png`, and `candidate`.
- Active Candy runtime assets live under selected runtime paths such as
  `assets/themes/candy_sky_islands/models/`, `assets/themes/candy_sky_islands/ui/`,
  `sounds/candy_sky_islands/`, `Resources/Data/...`, `scenes/`, `objects/`,
  and `addons/shinokute_game_core/`.
- Rejected candidates and raw references are archive evidence only under
  `assets/themes/candy_sky_islands/source/` and must not enter the exported PCK.

## Output Folders

There are two Web output folders. Do not guess their roles.

- `Export/`: canonical local Godot Web export output.
- `Export_web_test/`: Firebase Hosting public folder from `firebase.json`.

The Web preset exports to:

```text
Export/candy_sky_islands.html
```

Firebase deploy reads:

```text
Export_web_test/
```

Therefore a Firebase test deploy must rebuild `Export/`, then sync the rebuilt
files into `Export_web_test/` before running Firebase deploy. Do not deploy old
`Export_web_test/` files.

## Fresh Web Export Command

Use these commands from PowerShell:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
Set-Location $project

git status --short -uall
git fetch shinokute-core game/candy-sky-islands
git rev-list --left-right --count '@{u}...HEAD'

& $godot --headless --path $project --script "$project\tests\test_web_export_preset_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_audio_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_obby_route_solvability_contract.gd"
& $godot --headless --path $project --import
& $godot --headless --path $project --export-release "Web" "$project\Export\candy_sky_islands.html"
```

For final evidence, run the full contract sweep, not only focused tests:

```powershell
$tests = Get-ChildItem -LiteralPath "$project\tests" -Filter 'test_*.gd' | Sort-Object Name
$failures = @()
foreach ($test in $tests) {
  & $godot --headless --path $project --script $test.FullName
  if ($LASTEXITCODE -ne 0) { $failures += $test.Name }
}
if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error "FAIL $_" }
  exit 1
}
Write-Host "CANDY_FULL_TEST_SWEEP_PASS count=$($tests.Count)"
```

## Sync For Firebase Preview

After a fresh export succeeds, sync the export folder used by Firebase:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Set-Location $project

New-Item -ItemType Directory -Force -Path "$project\Export_web_test" | Out-Null
Copy-Item -LiteralPath (Get-ChildItem -LiteralPath "$project\Export" -File).FullName -Destination "$project\Export_web_test" -Force
```

Then deploy preview only, unless the owner explicitly asks for production:

```powershell
firebase hosting:channel:deploy candy-sky-islands-test --project foodapp-7ff6b --expires 7d
```

Production deploy command, owner approval required:

```powershell
firebase deploy --only hosting --project foodapp-7ff6b
```

## Payload Hygiene Scan

Run after every fresh export and before every deploy:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$pck = Join-Path $project 'Export\candy_sky_islands.pck'
$paths = & rg -a -o 'res://[A-Za-z0-9_./:@-]+' $pck | Sort-Object -Unique
$bad = $paths | Where-Object {
  $_ -match 'docs/|debug/|tests/|tools/|source/|_raw\.png|candidate|models/Textures/colormap\.png|meshes/dust\.res|meshes/brick\.res|Assets/3D|C:/Users/Admin'
}
if ($bad) {
  $bad | ForEach-Object { Write-Error "PCK_FORBIDDEN $_" }
  exit 1
}
Write-Host "PCK_PATH_MARKER_SCAN_PASS path_count=$($paths.Count)"
```

## Size Evidence

After export, record at least:

- `Export\candy_sky_islands.html`
- `Export\candy_sky_islands.js`
- `Export\candy_sky_islands.pck`
- `Export\candy_sky_islands.wasm`
- `sounds\candy_sky_islands\bgm_candy_island_main.ogg`
- SFX total in `sounds\candy_sky_islands\sfx_*.ogg`

Latest known clean reference from this branch:

- HTML: `6,036 B`
- JS: `331,495 B`
- PCK: `12,887,392 B` (`12.290 MB`)
- WASM: `35,376,909 B` (`33.738 MB`)
- BGM: `1,136,942 B` (`1.084 MB`)
- SFX total: `45,882 B`

If fresh numbers differ, report the fresh numbers. Do not reuse old size data.

## Web Smoke Required Before Claim

Loading the HTML is not enough.

Required smoke:

1. Serve the fresh export with a cache-busted URL.
2. Open Candy Sky Islands Web export.
3. Enter or skip username prompt.
4. Reach gameplay Level 1.
5. Move, jump, double jump, collect one star candy, and fall/retry once.
6. On mobile/iOS, test left thumbstick, right jump, right-side look, pinch zoom,
   portrait to landscape rotation, and landscape to portrait rotation.
7. Console must have no errors.

If this smoke was not run in the current pass, say "Web export built, gameplay
smoke not completed" instead of "ready".

## Final Report Required Fields

A packaging agent must report:

- Branch and commit.
- `git status --short -uall` result.
- Full test sweep count and failures, if any.
- Godot import/export command and exit status.
- PCK marker scan result.
- Size table with fresh values.
- Firebase command used and preview URL, if deployed.
- Web smoke path and result.
- Explicit blockers: Android unsupported, smoke not run, Firebase auth missing,
  or any payload marker/size failure.
