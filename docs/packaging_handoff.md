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
- Firebase preview project: `foodapp-7ff6b`
- Firebase preview hosting target: `candy-preview`
- Firebase preview site: `foodapp-7ff6b`
- Firebase preview channel for owner device testing: `candy-sky-islands-test`
- Firebase production project for `play.shinokute.com`: `shinokute-studio`
- Firebase production hosting target: `shinokute-play`
- Firebase production site: `shinokute-play`
- Production domain: `play.shinokute.com`
- Production DNS verified on 2026-07-12: `play.shinokute.com` CNAMEs to
  `shinokute-play.web.app`.

Do not use `origin` for pushing this game branch. `origin` points at the
upstream Kenney starter kit. Use `shinokute-core` for Candy Sky Islands.

## Current Packaging Scope

Current supported package target is Web/HTML5 only.

Do not claim Android, Play Store, or full package-ready status. Android is
blocked until an Android export preset, signing profile, fresh AAB export, AAB
forbidden-marker scan, and Android size table exist.

Production Web deploy to `play.shinokute.com` is allowed only after the owner
approves production deploy for the current build. Preview deploy remains the
default for owner device testing.

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

## Sync For Firebase Preview And Production

After a fresh export succeeds, sync the export folder used by Firebase. Both
preview and production targets publish from `Export_web_test/`, so this sync is
mandatory before either deploy.

Important: Godot export folders may contain `.import` sidecars or `.gdignore`
files. Do not copy the entire `Export/` folder into the public folder. Public
hosting must be rebuilt from a runtime whitelist only. `.import`, `.gdignore`,
logs, docs, tests, and any authoring artifacts must never be deployed.

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Set-Location $project

$source = Join-Path $project 'Export'
$public = Join-Path $project 'Export_web_test'
$projectFull = [System.IO.Path]::GetFullPath($project)
$publicFull = [System.IO.Path]::GetFullPath($public)
if (-not $publicFull.StartsWith($projectFull, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to clean public folder outside project: $publicFull"
}

New-Item -ItemType Directory -Force -Path $public | Out-Null
Get-ChildItem -LiteralPath $public -Force | Remove-Item -Recurse -Force

$runtimeFiles = @(
  'candy_sky_islands.html',
  'candy_sky_islands.js',
  'candy_sky_islands.wasm',
  'candy_sky_islands.pck',
  'candy_sky_islands.audio.worklet.js',
  'candy_sky_islands.icon.png',
  'candy_sky_islands.apple-touch-icon.png',
  'candy_sky_islands.png'
)

foreach ($file in $runtimeFiles) {
  $src = Join-Path $source $file
  if (-not (Test-Path -LiteralPath $src)) {
    throw "Missing runtime export file: $src"
  }
  Copy-Item -LiteralPath $src -Destination $public -Force
}

$badPublic = Get-ChildItem -LiteralPath $public -Recurse -Force -File | Where-Object {
  $_.Name -match '\.import$|^\.gdignore$|\.log$'
}
if ($badPublic) {
  $badPublic.FullName | ForEach-Object { Write-Error "PUBLIC_FORBIDDEN $_" }
  exit 1
}

Write-Host "PUBLIC_WHITELIST_SYNC_PASS count=$($runtimeFiles.Count)"
```

Then deploy preview for owner device testing:

```powershell
firebase hosting:channel:deploy candy-sky-islands-test --only hosting:candy-preview --project foodapp-7ff6b --expires 7d
```

Production deploy to `play.shinokute.com`, owner approval required:

```powershell
firebase deploy --only hosting:shinokute-play --project shinokute-studio
```

Before production deploy, verify the target still points at the production site:

```powershell
firebase hosting:sites:list --project shinokute-studio
nslookup play.shinokute.com
```

Expected:

- `shinokute-studio` lists site `shinokute-play`.
- `play.shinokute.com` resolves through `shinokute-play.web.app`.

If either check fails, stop. Do not deploy production by guessing another site.

## Android / Play Store Handoff

Android is not configured in this source yet. Current `export_presets.cfg` has
only one preset:

```text
name="Web"
platform="Web"
```

The packaging agent must not create an AAB by guessing package id, signing, or
Play Store settings. Android remains blocked until source receives all of these:

- Android export preset in `export_presets.cfg`, preferably named `Android`.
- Package id / unique name approved by owner.
- Version name and version code policy.
- Release keystore path, alias, and password-source policy.
- Target architecture policy.
- Min/target SDK policy.
- Android icon/splash/adaptive icon policy.
- AAB export path, expected `Export_android/` or equivalent output folder.
- AAB forbidden-marker scan command and expected marker list.
- Android size table and budget.
- Device smoke checklist for touch controls, rotation, audio, settings,
  leaderboard/username, win/death retry, and level progression.

When those inputs exist, update this handoff, `export_presets.cfg`, and
`tests/test_packaging_handoff_contract.gd` in the same source commit. Until
then, the correct Android report is:
`Android blocked: no Android preset or signing handoff in source`.

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
- Production command used and `https://play.shinokute.com` result, if production
  was owner-approved.
- Android AAB command, signing status, AAB scan, size table, and device smoke
  result, if Android has been configured. Otherwise report the Android blocker.
- Web smoke path and result.
- Explicit blockers: Android unsupported, smoke not run, Firebase auth missing,
  or any payload marker/size failure.
