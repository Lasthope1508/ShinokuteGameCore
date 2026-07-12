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
- Current selected-resource runtime core includes
  `res://addons/shinokute_game_core/core/dynamic_progression_resolver.gd` and
  `res://addons/shinokute_game_core/core/obby_route_generator_3d.gd` because
  Candy uses core-owned infinite 3D obby progression and route generation. Do
  not remove them from Web or Android selected resources.
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
& $godot --headless --path $project --script "$project\tests\test_shinokute_3d_obby_progression_core_contract.gd"
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

Android packaging is owned by `docs/android_packaging_runbook.md`. This file
keeps only Candy identity values so Web/Firebase and Android docs do not drift.

Android Packaging Reset Rule: before Android export, AAB, signing, Gradle,
Java/JDK, Android SDK, keystore, Play Console, or Android-ready claims, read
`docs/android_packaging_runbook.md`. Do not use memory, prior chat, or old
terminal output. First compare the existing shipped patterns: BloxChain and
Glyph Arrows shipped branch patterns, then use Candy's documented source
values. Source handoff work must not install Java/JDK, Android SDK, Gradle,
create a keystore, change package id, or invent Play settings.
Do not create a replacement keystore. Packaging work must use
`tools/patch_android_template_for_play.ps1`, keep
`android/build/.gdignore`, preserve `keystore/release_password=""` after export,
and run Gate 4C from the Android runbook before Play handoff.

Candy Android source values:

- Android preset name: `Android`
- Package id: `com.shinokutestudio.candyskyislands`
- Android app label: `Candy Sky Islands`
- Current version: `version/code=6`, `version/name="1.0.5"`
- Target SDK: `version/target_sdk=35`
- AAB export path: `Export/candy_sky_islands.aab`
- Release keystore: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands.keystore`
- Release key alias: `candy_sky_islands`
- Password source: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json`
- Gate 4C: Android Payload Hygiene lives in `docs/android_packaging_runbook.md`

Google Play handoff status: source-owned Android preset and signing handoff
exist. Release/upload remains packaging-owned and blocked until fresh AAB
export, AAB scan/deep scan, size table, signing evidence, and device smoke pass
in the current release pass.

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
6. On desktop Web, confirm the mobile thumbstick/jump overlay is not visible on
   load; desktop Web uses keyboard/mouse/gamepad only.
7. On mobile/iOS, test left thumbstick, right jump, right-side look, pinch zoom,
   portrait to landscape rotation, and landscape to portrait rotation.
8. Console must have no errors.

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
