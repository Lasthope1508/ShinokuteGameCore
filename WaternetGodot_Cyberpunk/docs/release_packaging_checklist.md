# Release Packaging Checklist

## Canonical Release Identity

- Game name: `Glyphflow Arrays`
- Android package: `com.shinokutestudio.glyphflowarrays`
- Web export: `Export/glyphflow_arrays.html`
- Android export: `Export/glyphflow_arrays.aab`
- Production feature flag: `production`

## Android Signing

- Release keystore: `C:/Users/Admin/.gemini/antigravity/secrets/glyphflow_arrays.keystore`
- Release alias: `glyphflow_arrays`
- Secret metadata: `C:/Users/Admin/.gemini/antigravity/secrets/glyphflow_arrays_keystore_secrets.json`
- Do not use old `bloxchain.keystore` or alias `bloxchain`.
- Do not rotate this key after store upload unless owner explicitly approves store key upgrade/replacement.

## Source Packaging Contract

- Required reading before packaging: `docs/mobile_html5_asset_optimization_checklist.md`.
- Required reading before any Web audio rebuild: `docs/audio_pipeline.md`, section `Web Audio Incident 2026-07-03`.
- Asset optimization checklist must pass before any package-ready claim.
- Runtime theme registration must stay cyber-only.
- Production export must exclude tests, docs, MCP/debug addons, raw/reference assets, style trials, old theme assets, and old branding assets.
- MCP runtime/autoload must return early under `OS.has_feature("production")`.
- No runtime fallback theme/audio path is allowed in this project.
- Root BGM fallback files such as `Audio/Music/Gameplay*` and default SFX fallback files such as `Audio/Sfx/default/*` must stay outside the production project or be explicitly excluded.
- Scratch/reference workbench folders must stay outside the production project, not just export-excluded, because Godot import scans them before export.
- Root test artifacts such as `test_out*`, `Tests/*` generated screenshots, and `Scenes/Gameplay/DebugGameplay*` must not ship.
- Web `include_filter` must not use broad wildcards such as `*.png`; broad includes can pack debug/old texture assets and poison UID resolution.
- Resource-filter exports must explicitly include every runtime preload script used by exported scenes, including gameplay model/solver/VFX scripts. Missing `.gd` preloads can pass menu load and fail only when entering gameplay.
- `export_presets.cfg` must be UTF-8 without BOM. A BOM at byte 0 (`EF BB BF`) makes Godot 4.3 ignore presets and report `Invalid export preset name: Web`.
- Web verification must use a no-cache or cache-busted local server, click through `MainMenu -> Play -> Level 1`, confirm the gameplay board renders, perform one tile interaction, and confirm no browser console errors. Loading the HTML shell, splash, title screen, menu, or level select alone is not a valid playability check.
- Cache-busting only the `.html` URL is not enough for Godot Web. The HTML loads a fixed `.pck` filename unless the export basename changes. For owner test links after gameplay/audio changes, either export a versioned basename such as `glyphflow_arrays_audiofix.html` or ensure Firebase sends `Cache-Control: no-cache, no-store, must-revalidate` for `.html`, `.pck`, `.js`, and `.wasm`.
- Web audio publish gate: after opening the deployed game and making one real input, `glyphflowAudioDebug.web_audio_unlock_attempted` must become `true` and `web_audio_unlock_input_count` must be at least `1`. If owner still hears no sound after that, stop and investigate output/browser/device state instead of converting audio again.
- Before release export, clear generated Godot import/export caches so stale deleted resources or old `.import` settings cannot be packed.
- Before Firebase deploy, clean `Export/` or ensure Firebase ignores non-Web artifacts such as AAB, ZIP, log, `.import`, and pack audit files.

## Required Verification Before Claiming Package-Ready

Current verified export evidence from 2026-07-04:

- Godot MCP evidence: `get_project_info` confirmed project `Glyphflow Arrays`, path `C:\w\water\WaternetGodot_Cyberpunk`, Godot `4.3.stable.official.77dcf97d8`.
- Full Godot test sweep: `79/79 pass`.
- Import/export note: Godot import may remove the `[audio]` project setting; restore `buses/default_bus_layout="res://default_bus_layout.tres"` before testing/exporting. Do not commit release keystore passwords in `export_presets.cfg`.
- Web export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\w\water\WaternetGodot_Cyberpunk" --export-release Web "Export\glyphflow_arrays.html"`; exit `0`.
- Android export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\w\water\WaternetGodot_Cyberpunk" --install-android-build-template --export-release Android "Export\glyphflow_arrays.aab"`; exit `0`. Gradle daemon may keep the wrapper alive after `export: end`; stop it with `android\build\gradlew.bat --stop` under the configured JDK.
- Generated artifacts:
  - `Export/glyphflow_arrays.html`: 4,929 bytes.
  - `Export/glyphflow_arrays.js`: 331,495 bytes.
  - `Export/glyphflow_arrays.wasm`: 35,376,909 bytes.
  - `Export/glyphflow_arrays.pck`: 15,207,584 bytes (14.50 MB).
  - `Export/glyphflow_arrays.aab`: 61,207,533 bytes (58.37 MB).
- Forbidden scan: `godot_publish_audit.ps1` returned `GODOT_PUBLISH_AUDIT_OK` for `Export\glyphflow_arrays.pck` and `Export\glyphflow_arrays.aab`.
- Android signing/package check: `jarsigner.exe -verify -certs Export\glyphflow_arrays.aab` exit `0`.
- Web no-cache smoke: served `Export/` from `http://127.0.0.1:49410`, opened `glyphflow_arrays.html?v=build-20260704`, gameplay board rendered, clicked one tile, `MOVES` changed to `2`, browser console errors/warnings `[]`.
- Budget comparison:
  - Web PCK: 14.50 MB / 30 MB: pass.
  - Android AAB: 58.37 MB / 80 MB: pass.
- Blockers: none for current generated Web/AAB artifacts.

Clear generated export cache:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
Remove-Item "$project\.godot\editor\filesystem_cache8" -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\imported" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\exported" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\uid_cache.bin" -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\global_script_class_cache.cfg" -Force -ErrorAction SilentlyContinue
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path $project --import
```

Run full test sweep:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$tests = Get-ChildItem Tests -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object { 'res://Tests/' + $_.Name }
foreach ($test in $tests) {
  & $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s $test *> godot_verify_all.log
  $pass = Select-String -Path godot_verify_all.log -Pattern ': PASS' -SimpleMatch
  $green = Select-String -Path godot_verify_all.log -Pattern 'ALL TESTS PASSED' -SimpleMatch
  $fail = Select-String -Path godot_verify_all.log -Pattern ': FAIL','SOME TESTS FAILED' -SimpleMatch
  if ($LASTEXITCODE -ne 0 -or $fail.Count -gt 0 -or ($pass.Count -eq 0 -and $green.Count -eq 0)) {
    Get-Content godot_verify_all.log -Tail 160
    exit 1
  }
}
Remove-Item godot_verify_all.log -ErrorAction SilentlyContinue
```

Run mobile publish import policy test:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_mobile_publish_asset_import_policy.gd'
```

Run Web export:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --export-release 'Web' 'Export/glyphflow_arrays.html'
```

Run Web playability smoke on a no-cache local server:

```powershell
# Required manual/browser check after export:
# 1. Serve Export/ from a new no-cache port or use a fresh cache-busting query.
# 2. Open glyphflow_arrays.html.
# 3. Click Play.
# 4. Click Level 1.
# 5. Confirm gameplay board renders.
# 6. Click one tile and confirm MOVES changes.
# 7. Confirm browser console has no errors or warnings.
```

Audit exported Web pack:

```powershell
$bad = Select-String -Path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\Export\glyphflow_arrays.pck' -Pattern 'res://debug/','backup_cyberpunk_assets_before','Assets/Themes/fruit_theme','Assets/Themes/garden_theme','Assets/Themes/wood_theme','Assets/Themes/chaos','energy_sheets_ai','Audio/Music/Gameplay','Audio/Sfx/default','res://Tests/','test_out.ogg','DebugGameplay','scratch/' -SimpleMatch
if ($bad.Count -gt 0) { $bad | Select-Object -First 20; exit 1 }
```

Run Android export:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --export-release 'Android' 'Export/glyphflow_arrays.aab'
```

Confirm Android bundle:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[System.IO.Compression.ZipFile]::OpenRead('C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\Export\glyphflow_arrays.aab')
$zip.Entries | Where-Object { $_.FullName -eq 'base/manifest/AndroidManifest.xml' }
$zip.Entries | Where-Object { $_.FullName -like 'base/lib/*/libgodot_android.so' }
$zip.Dispose()
```

Audit Android bundle for forbidden resource paths:

```powershell
$bad = Select-String -Path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\Export\glyphflow_arrays.aab' -Pattern 'res://debug/','backup_cyberpunk_assets_before','Assets/Themes/fruit_theme','Assets/Themes/garden_theme','Assets/Themes/wood_theme','Assets/Themes/chaos','energy_sheets_ai','Audio/Music/Gameplay','Audio/Sfx/default','res://Tests/','test_out.ogg','DebugGameplay','scratch/' -SimpleMatch
if ($bad.Count -gt 0) { $bad | Select-Object -First 20; exit 1 }
```
