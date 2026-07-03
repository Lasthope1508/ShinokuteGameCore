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
- Asset optimization checklist must pass before any package-ready claim.
- Runtime theme registration must stay cyber-only.
- Production export must exclude tests, docs, MCP/debug addons, raw/reference assets, style trials, old theme assets, and old branding assets.
- MCP runtime/autoload must return early under `OS.has_feature("production")`.
- No runtime fallback theme/audio path is allowed in this project.
- Root BGM fallback files such as `Audio/Music/Gameplay*` and default SFX fallback files such as `Audio/Sfx/default/*` must stay outside the production project or be explicitly excluded.
- Scratch/reference workbench folders must stay outside the production project, not just export-excluded, because Godot import scans them before export.
- Root test artifacts such as `test_out*`, `Tests/*` generated screenshots, and `Scenes/Gameplay/DebugGameplay*` must not ship.
- Web `include_filter` must not use broad wildcards such as `*.png`; broad includes can pack debug/old texture assets and poison UID resolution.
- Before release export, clear generated Godot import/export caches so stale deleted resources or old `.import` settings cannot be packed.
- Before Firebase deploy, clean `Export/` or ensure Firebase ignores non-Web artifacts such as AAB, ZIP, log, `.import`, and pack audit files.

## Required Verification Before Claiming Package-Ready

Current verified export evidence from 2026-07-03:

- Web PCK: `Export/glyphflow_arrays.pck` = 13.51 MB, forbidden scan clean.
- Web WASM: `Export/glyphflow_arrays.wasm` = 33.74 MB, engine/runtime baseline.
- Android AAB: `Export/glyphflow_arrays.aab` = 57.39 MB, forbidden scan clean.
- Full Godot test sweep: `TOTAL:71 ALL_OK:True`.
- Required audit script: `godot_publish_audit.ps1` returned `GODOT_PUBLISH_AUDIT_OK`.

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
