# Candy Sky Islands Packaging Handoff

This is the first file to read before packaging, Web export, Android export,
Firebase deploy, Play Store handoff, payload-size audit, or any package-ready
claim for Candy Sky Islands.

## Contextless Agent Bootstrap

Assume no chat history. A packaging agent must be able to package from this
repository alone.

Required first reads:

1. `AGENTS.md`
2. `docs/packaging_handoff.md`
3. `docs/validation_runbook.md` Gate 4B and Gate 4C
4. `export_presets.cfg`
5. `firebase.json`
6. `.firebaserc`
7. `tests/test_packaging_handoff_contract.gd`
8. `tests/test_web_export_preset_contract.gd`
9. `tests/test_android_export_preset_contract.gd`

Do not use memory, prior chat, old Firebase links, stale terminal output, or
old `Export_web_test/` contents as source of truth.

Required first report:

- branch and commit
- local vs upstream count
- current packaging scope
- Web preview target
- production target
- Android status
- Play Store handoff status
- exact blocker list, if any

## Source Completion Handoff Gate

Every source-completion pass must leave this handoff usable by a different
agent with no context. Before committing source changes, the source owner must
check this table:

| Source change | Handoff action required |
|---|---|
| `export_presets.cfg` changed | Update Web/Android preset names, output paths, selected resource rules, and tests |
| `firebase.json` or `.firebaserc` changed | Update preview/production targets, site/project mapping, cache policy, deploy commands, and tests |
| Runtime asset, UI, audio, or scene path changed | Update runtime whitelist, size evidence expectations, PCK marker rules, and export preset contract |
| Public output folder policy changed | Update whitelist sync command; never copy all files from `Export/` |
| Android/Play Store added or changed | Add Android preset/signing/package/version/AAB scan/device smoke details before allowing AAB claims |
| `play.shinokute.com` or preview channel changed | Update DNS/site verification commands and deploy commands |
| Bug fix affects mobile/input/Web shell | Update smoke checklist and contract tests that prove the handoff still covers the path |

If none of these apply, still run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_packaging_handoff_contract.gd"
```

The source owner must not push a source-completion commit if this contract
fails. The packaging agent must stop if this contract fails after pulling.

## Canonical Source

- Project root: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`
- Git branch: `game/candy-sky-islands`
- Git remote for this game branch: `shinokute-core`
- Remote branch: `shinokute-core/game/candy-sky-islands`
- Godot console on this machine: `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`
- Web preset name: `Web`
- Android preset name: `Android`
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

Current source handoff covers Web/HTML5 and Android AAB.

Do not claim Android, Play Store, or full package-ready status until the current
pass has a fresh Android export, AAB forbidden-marker scan, Android size table,
signing evidence, and device smoke. The source has an Android preset and
signing handoff; packaging/release agents must use them instead of inventing
package ids, keystores, or Play Store settings.

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
  Web and Android `export_files`, then update
  `tests/test_web_export_preset_contract.gd` and
  `tests/test_android_export_preset_contract.gd`.
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
firebase hosting:channel:deploy candy-sky-islands-test --only candy-preview --project foodapp-7ff6b --expires 7d
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

## Android Packaging Reset Rule

Every Android packaging agent must read this section before touching Android
export, keystore, Java/JDK, Gradle, SDK, AAB, or Play Store work.

- First compare the existing shipped patterns, not memory or guesses:
  `shinokute-core/game/bloxchain` and `shinokute-core/game/glyph-arrows`
  Android presets both use a dedicated `Android` preset, selected
  `export_filter="resources"`, `Export/<game>.aab`, package id
  `com.shinokutestudio.<game>`, per-game release keystore under
  `C:/Users/Admin/.gemini/antigravity/secrets/`, and no committed passwords.
- Source handoff work must not install Java/JDK, Android SDK, Gradle, create a
  keystore, change machine release tooling, or invent Play Console settings.
  Source handoff only owns `export_presets.cfg`, package id/version policy,
  signing path/alias/password-source documentation, docs, and contract tests.
- Packaging/release work may build the AAB only after source handoff contracts
  pass. If Java/JDK, SDK, Gradle, Godot templates, keystore, or password source
  are missing, report the exact missing item as a packaging blocker.
  Do not create a replacement keystore. Do not change package id, switch to
  debug signing, or upload a different app unless the owner explicitly approves
  that release operation.
- If Godot Android build templates must be expanded manually, use the official
  `android_source.zip` from the matching Godot export template version, expand
  Gradle project files into `android/build/`, and keep `android/.build_version`
  beside the `build` folder. For Godot 4.3 stable the marker content is
  `4.3.stable`. Missing this marker causes the export error:
  "Trying to build from a gradle built template, but no version info for it
  exists."
- Google Play upload is packaging/release-owned after source contracts pass.
  Source owner remains responsible for keeping the Android preset, signing
  handoff, version policy, runtime asset list, and Gate 4C scan rules current.
- Any future game branch must copy this split: source branch defines Android
  truth, packaging agent builds from docs, and neither side relies on chat
  history.

Android is configured in source. The packaging/release agent must use these
values exactly.

- Android preset name: `Android`
- Package id: `com.shinokutestudio.candyskyislands`
- Android app label: `Candy Sky Islands`
- Version policy: start at `version/code=1`, `version/name="1.0.0"`; bump
  `version/code` by one for every Play upload attempt that reaches Google.
- AAB export path: `Export/candy_sky_islands.aab`
- Release keystore: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands.keystore`
- Release key alias: `candy_sky_islands`
- Password source: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json`
- Do not commit keystore files, passwords, or Play Console credentials.
- Target architectures: `armeabi-v7a=true`, `arm64-v8a=true`, `x86=false`,
  `x86_64=false`.
- Screen orientation: landscape, `graphics/screen_orientation=1`, until owner
  approves portrait or sensor rotation for native Android.
- Android icon policy: root `res://icon.png` is the current source icon;
  launcher/adaptive icon fields stay empty until dedicated Android launcher
  assets are produced and recorded in `docs/asset_manifest.md`.

Fresh Android export command:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
Set-Location $project

& $godot --headless --path $project --script "$project\tests\test_packaging_handoff_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_android_export_preset_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_web_export_preset_contract.gd"
& $godot --headless --path $project --import
& $godot --headless --path $project --export-release "Android" "$project\Export\candy_sky_islands.aab"
```

If the Android export fails because Godot export templates, Android SDK,
Gradle, Java/JDK, or local keystore tooling are missing, report the exact
missing tool from the command output. Do not replace the signed release preset
with an unsigned/debug build and do not create a new package id.

## Gate 4C: Android Payload Hygiene

Run after every fresh Android export and before Play Store handoff:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$aab = Join-Path $project 'Export\candy_sky_islands.aab'
if (-not (Test-Path -LiteralPath $aab)) {
  Write-Error "Missing Android AAB: $aab"
  exit 1
}

$paths = & rg -a -o 'res://[A-Za-z0-9_./:@-]+' $aab | Sort-Object -Unique
$bad = $paths | Where-Object {
  $_ -match 'docs/|debug/|tests/|tools/|source/|_raw\.png|candidate|models/Textures/colormap\.png|meshes/dust\.res|meshes/brick\.res|Assets/3D|C:/Users/Admin'
}
if ($bad) {
  $bad | ForEach-Object { Write-Error "AAB_FORBIDDEN $_" }
  exit 1
}
Write-Host "AAB_PATH_MARKER_SCAN_PASS path_count=$($paths.Count)"
```

If `path_count=0`, do not treat the outer scan as enough proof. AAB files can
compress Godot resources under `installTime/assets/`. Run the deep scan too:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$aab = Join-Path $project 'Export\candy_sky_islands.aab'
$temp = Join-Path $env:TEMP ('candy_aab_scan_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($aab, $temp)
  $entryNames = Get-ChildItem -LiteralPath $temp -Recurse -Force -File |
    ForEach-Object { $_.FullName.Substring($temp.Length + 1).Replace('\','/') }
  $entryBad = $entryNames | Where-Object {
    $_ -match 'docs/|debug/|tests/|tools/|source/|_raw\.png|candidate|models/Textures/colormap\.png|meshes/dust\.res|meshes/brick\.res|Assets/3D|C:/Users/Admin'
  }
  if ($entryBad) {
    $entryBad | ForEach-Object { Write-Error "AAB_ENTRY_FORBIDDEN $_" }
    exit 1
  }
  $contentPaths = & rg -a -o 'res://[A-Za-z0-9_./:@-]+' $temp | Sort-Object -Unique
  $contentBad = $contentPaths | Where-Object {
    $_ -match 'docs/|debug/|tests/|tools/|source/|_raw\.png|candidate|models/Textures/colormap\.png|meshes/dust\.res|meshes/brick\.res|Assets/3D|C:/Users/Admin'
  }
  if ($contentBad) {
    $contentBad | ForEach-Object { Write-Error "AAB_CONTENT_FORBIDDEN $_" }
    exit 1
  }
  Write-Host "AAB_DEEP_SCAN_PASS entry_count=$($entryNames.Count) content_path_count=$($contentPaths.Count)"
} finally {
  if (Test-Path -LiteralPath $temp) {
    Remove-Item -LiteralPath $temp -Recurse -Force
  }
}
```

Native Android device smoke checklist:

1. Install the signed release AAB through the Play/internal-test path or a
   release-equivalent local extraction path documented by the packaging agent.
2. Launch fresh app, confirm splash and username prompt.
3. Enter username; Settings and Leaderboard must open one at a time.
4. Move, jump, double-jump, rotate camera/look, pinch or equivalent zoom.
5. Toggle BGM/SFX and Shift Lock settings.
6. Complete one level, fall/retry once, then confirm progression continues.
7. Rotate device or verify landscape lock policy; no stretched/misaligned UI.
8. Audio loops without silence after the intro loop point.
9. No crash, missing resource, or forbidden marker evidence.

Google Play handoff status: source-owned Android preset and signing handoff
exist. Release/upload remains packaging-owned and blocked until fresh AAB
export, AAB scan, size table, and device smoke pass in the current release pass.

## Gate 4B: Web Payload Hygiene Scan

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
- `Export\candy_sky_islands.aab` after Android export

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
  result.
- Web smoke path and result.
- Explicit blockers: Android export tooling missing, Play upload not approved,
  smoke not run, Firebase auth missing, or any payload marker/size failure.
