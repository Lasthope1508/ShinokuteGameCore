# Android Packaging Runbook

This file is the Android packaging SSOT for Candy Sky Islands and future
Shinokute Godot game branches. Read it before Android export, AAB signing,
Google Play upload, internal testing, or any Android-ready claim.

Do not copy this runbook into other docs. Other docs may link here and keep
only their own gate summary. If a future Android rule changes, update this file
first, then update tests that point to it.

## Read Order

For a contextless Android packaging agent, read in this order:

1. `AGENTS.md`
2. `docs/packaging_handoff.md`
3. `docs/android_packaging_runbook.md`
4. `docs/validation_runbook.md` Gate 4C
5. `export_presets.cfg`
6. `tools/patch_android_template_for_play.ps1`
7. `tests/test_packaging_handoff_contract.gd`
8. `tests/test_android_export_preset_contract.gd`
9. Current game branch Android evidence in `docs/reskin_checklist.md`, if any.

First report must include branch, commit, upstream count, Android scope,
package id, version code/name, target SDK, keystore path existence, AAB path,
and exact blockers.

## Android Packaging Reset Rule

Before touching Android export, AAB, signing, Gradle, Java/JDK, Android SDK,
keystore, Play Console, or Android-ready claims, reset to this file as SSOT.
Do not use memory, prior chat, or old terminal output.

## Duplication Rule

Android details live here.

| File | Allowed Android content |
|---|---|
| `docs/android_packaging_runbook.md` | Full Android export, signing, Play, scan, smoke, failure handling |
| `docs/packaging_handoff.md` | Project identity, Web/Firebase handoff, short Android pointer and current Candy values |
| `docs/validation_runbook.md` | Gate name and pointer to this runbook |
| `AGENTS.md` | Mandatory read rule only |
| Contract tests | Needles that prove docs point to this runbook and source values are stable |

If another doc repeats a full Android command block from this file, treat that
as duplication and collapse it back to a link.

## Ownership Split

Source owner owns:

- `export_presets.cfg` Android preset.
- Package id, app label, version code/name, target SDK field.
- Selected runtime resources and forbidden payload markers.
- Keystore path, alias, and password-source documentation.
- Contract tests and docs that let another agent package without chat history.

Packaging/release owner owns:

- Local JDK, Android SDK, Gradle/template availability.
- Temporary password injection for export.
- Fresh signed AAB export.
- Manifest, signing, size, and payload scans.
- Play Console upload, declarations, tester rollout, and device smoke.

Never let either side invent the other side's truth. If source is missing a
package id or signing handoff, stop and update source docs/tests first. If a
local release tool or secret is missing, report the exact blocker; do not make
a replacement keystore, package id, debug build, or Play app unless the owner
explicitly approves that release operation.

## Shipped Pattern To Compare

Before packaging a new game branch, compare existing shipped branches instead
of guessing:

- BloxChain branch: `shinokute-core/game/bloxchain`
- Glyph Arrows branch: `shinokute-core/game/glyph-arrows`

Expected shared pattern:

- Dedicated preset named `Android`.
- `export_filter="resources"`, never `all_resources`.
- Canonical AAB in `Export/<game>.aab`.
- Package id under `com.shinokutestudio.<game>`.
- Per-game release keystore under `C:/Users/Admin/.gemini/antigravity/secrets/`.
- No committed passwords.
- No broad include filters such as `*.png`, `*.ogg`, `*.tres`, `Assets/**`, or
  `assets/**`.

## Candy Sky Islands Values

Use these exact Candy values unless owner approves a source change:

| Field | Value |
|---|---|
| Android preset | `Android` |
| App label | `Candy Sky Islands` |
| Package id | `com.shinokutestudio.candyskyislands` |
| AAB path | `Export/candy_sky_islands.aab` |
| Current version code | `4` |
| Current version name | `1.0.3` |
| Target SDK | `35` |
| Release keystore | `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands.keystore` |
| Release alias | `candy_sky_islands` |
| Password source | `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json` |
| Orientation | Landscape, `graphics/screen_orientation=1` |
| Architectures | `armeabi-v7a=true`, `arm64-v8a=true`, `x86=false`, `x86_64=false` |

Current Play evidence recorded for this branch:

- Play app: `Candy Sky Islands`
- Package: `com.shinokutestudio.candyskyislands`
- Internal testing release: `4 (1.0.3)`
- Tester list: `Shinokute testers`
- Tester join link: `https://play.google.com/apps/internaltest/4701018407986590939`
- Last known signed AAB size: `58,719,395` bytes
- Last known AAB deep scan: `entry_count=315`, `content_path_count=112`

Old size/evidence is reference only. A new package-ready claim requires fresh
evidence from the current pass.

## Version Policy

For a new Play package:

- Start at `version/code=1`.
- Start at `version/name="1.0.0"`.
- Bump `version/code` by one for every upload attempt that reaches Google Play,
  even if Play rejects the upload.
- Bump `version/name` when owner wants a visible release label change or when
  repeated failed uploads would confuse release tracking.

For Candy, version codes `1`, `2`, and `3` were consumed by rejected Play
uploads. Current source must stay at `version/code=4`,
`version/name="1.0.3"` until a new upload attempt needs another bump.

## Target SDK Policy

Candy currently targets Android 15 / API 35. Before each Play upload, verify
the current target API requirement in Play Console or official Android
Developers docs. Do not rely on chat history for this.

Official policy page to check:
`https://developer.android.com/google/play/requirements/target-sdk`

For Godot 4.3 custom Gradle builds, setting only `version/target_sdk=35` in
`export_presets.cfg` is not enough. Candy previously exported an AAB that Play
reported as API 34. Patch the local Android template before export:

- `android/build/config.gradle` uses `compileSdk: 35`
- `android/build/config.gradle` uses `targetSdk: 35`
- `android/build/config.gradle` uses `buildTools: '35.0.0'`
- `getExportTargetSdkVersion()` returns the max of Godot's exported property
  and `versions.targetSdk`

Use `tools/patch_android_template_for_play.ps1` after installing or expanding
Android build templates and before every Android export.

## Local Tooling

Expected local paths on this machine:

```text
Godot console:
C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe

Android SDK:
C:\Users\Admin\.bubblewrap\android_sdk

JDK:
C:\Users\Admin\.gemini\antigravity\bin\JDK64\jdk-17.0.19+10

Secrets directory:
C:\Users\Admin\.gemini\antigravity\secrets
```

Do not install a second JDK/SDK just because a command fails. First verify these
paths, then report the exact missing path or error.

## Android Template Reset

Godot custom Android build needs a local template workspace.

Required local files:

- `android/build/` contains Gradle project files from the matching
  `android_source.zip`.
- `android/.build_version` exists and contains `4.3.stable` for Godot 4.3.
- `android/build/.gdignore` exists.
- `android/build/assetPacks/.gdignore` exists when `assetPacks` exists or is
  created by the patch script.

Why:

- Missing `.build_version` causes Godot export error:
  `Trying to build from a gradle built template, but no version info for it exists.`
- Missing `android/build/.gdignore` lets Godot import Android template icons and
  create `.import` sidecars under `android/build/res/mipmap*`; Gradle then fails
  with file-name/resource errors.

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Set-Location $project
& .\tools\patch_android_template_for_play.ps1
```

Expected patch output must confirm SDK 35 patch and `.gdignore` markers. If the
script reports missing template files, install or expand the official matching
Godot Android template, then rerun the script.

## Preflight Checklist

Run from project root:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
Set-Location $project

git status -sb
git status --short -uall
git fetch shinokute-core game/candy-sky-islands
git rev-list --left-right --count '@{u}...HEAD'

& $godot --headless --path $project --script "$project\tests\test_packaging_handoff_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_android_export_preset_contract.gd"
& .\tools\patch_android_template_for_play.ps1
& $godot --headless --path $project --import
```

Stop if any command fails. Do not export Android from a failing source contract.

## Password Handling

Never print passwords. Never commit passwords. Never commit keystore files.

`export_presets.cfg` must end with:

```ini
keystore/release_password=""
```

Packaging may temporarily inject the release password into `export_presets.cfg`
only for the export command, then restore it immediately. Use a try/finally
style script. If a script fails before restore, restore manually before commit.

Password source is local-only:

```text
C:\Users\Admin\.gemini\antigravity\secrets\candy_sky_islands_keystore_secrets.json
```

Agent may inspect JSON property names locally, but must not echo secret values.

## Fresh Android Export

After preflight and temporary password injection:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
Set-Location $project

& $godot --headless --path $project --export-release "Android" "$project\Export\candy_sky_islands.aab"
```

Immediately verify password restoration:

```powershell
rg -n 'keystore/release_password=""' export_presets.cfg
rg -n 'keystore/release_password="[^"]+"' export_presets.cfg
```

Second command must return no matches.

## Manifest Verification

After export, verify the AAB manifest. Use any available local Android tooling
or an AAB unzip/manifest parser. Evidence must prove:

- `package=com.shinokutestudio.candyskyislands`
- `versionCode=4`
- `versionName=1.0.3`
- `targetSdkVersion=35`
- signed release entries exist under `META-INF/`

Known Candy signing entries:

- `META-INF/CANDY_SK.RSA`
- `META-INF/CANDY_SK.SF`
- `META-INF/MANIFEST.MF`

Do not upload if target SDK, package id, or signing evidence is missing.

## Gate 4C: Android Payload Hygiene

Run after every fresh Android export and before Play handoff:

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

If `path_count=0`, the outer scan is not enough. Run the deep scan:

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

## Size Evidence

Record fresh values:

```powershell
$items = @(
  'Export\candy_sky_islands.aab',
  'sounds\candy_sky_islands\bgm_candy_island_main.ogg'
)
foreach ($item in $items) {
  $file = Get-Item -LiteralPath $item
  [pscustomobject]@{ Path = $item; Bytes = $file.Length }
}

$sfx = Get-ChildItem -LiteralPath 'sounds\candy_sky_islands' -Filter 'sfx_*.ogg' -File
[pscustomobject]@{ Path = 'sounds\candy_sky_islands\sfx_*.ogg'; Bytes = ($sfx | Measure-Object Length -Sum).Sum; Count = $sfx.Count }
```

## Google Play Upload

Use the user's logged-in Chrome remote debugging session first. Do not use the
in-app browser for Play Console.

Check ports before opening another browser:

```powershell
netstat -ano | Select-String ':9222|:9223'
```

Preferred Play Console Chrome port: `9222`.

If Chrome debug is unavailable, ask owner to open it. Do not silently fall back
to in-app browser.

Upload notes:

- Use existing Play app for the package id.
- Do not create another app unless owner explicitly says this is a new package.
- New Play apps can ask for Developer Program Policies and US export law
  declarations; existing BloxChain/Glyph apps skipped this because they already
  existed.
- If browser automation cannot upload files larger than 50 MB through normal
  `setInputFiles`, use Chrome DevTools Protocol `DOM.setFileInputFiles`.
- If Play reports version code already used, bump `version/code` in source,
  rerun source contracts, rebuild AAB, rescan, then upload again.
- If Play reports target API lower than expected, rerun
  `tools/patch_android_template_for_play.ps1`, rebuild, and verify manifest
  before retry.
- If Play warns no testers are selected, select `Shinokute testers` before
  rollout.
- Debug symbols warning is not a blocker unless owner requires native symbol
  upload for that release.

## Native Device Smoke

Before Android-ready or Play-ready claim:

1. Install from Play internal testing or an equivalent release-signed path.
2. Launch fresh app.
3. Confirm splash and username prompt.
4. Enter username; Settings and Leaderboard open one at a time.
5. Move, jump, double-jump, rotate/look, and zoom.
6. Toggle BGM, SFX, and Shift Lock settings.
7. Complete one level.
8. Fall/retry once and confirm in-place reset.
9. Confirm landscape lock or approved orientation behavior.
10. Confirm audio loops without going silent after intro.
11. Confirm no crash, missing resource, or obvious UI misalignment.

If device smoke was not run in the current pass, say that. Do not say Android
is ready.

## Common Failures

| Symptom | Cause | Fix |
|---|---|---|
| No version info for Gradle template | Missing `android/.build_version` | Create marker with `4.3.stable` for Godot 4.3 template |
| Gradle rejects `.import` under mipmap | Godot imported Android template resources | Keep `android/build/.gdignore`, rerun patch script, remove stale `.import` |
| Play says target API 34 | Godot 4.3 passed old `export_version_target_sdk` into Gradle | Patch `config.gradle`, force SDK 35, rebuild |
| Version code already used | Play consumed a previous upload attempt | Bump `version/code`, rebuild, rescan |
| Unsigned/debug build | Password or keystore missing | Stop and report exact blocker; do not upload debug |
| Wrong package id | Preset changed or wrong branch | Stop; fix source before export |
| Play app asks declarations | New app flow | Complete owner-approved declarations; existing apps may not show this |
| Upload automation fails on AAB | Large file/input limitation | Use Chrome CDP `DOM.setFileInputFiles` |
| Testers warning | Tester list not selected | Select `Shinokute testers` |
| Old AAB uploaded | Stale `Export/` | Delete/rebuild AAB and verify timestamp/size |

## Final Android Report

Report these fields:

- Branch and commit.
- `git status --short -uall`.
- Upstream count.
- Tests run and pass/fail.
- Patch script result.
- Import/export command and exit status.
- AAB path, timestamp, and size.
- Package id, version code/name, target SDK.
- Signing evidence.
- AAB marker scan and deep scan result.
- Play app/release track/upload status, if uploaded.
- Tester list and join link, if rollout changed.
- Native device smoke result.
- Exact blockers, if any.
