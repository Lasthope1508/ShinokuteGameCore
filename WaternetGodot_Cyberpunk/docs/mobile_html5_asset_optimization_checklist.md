# Mobile And HTML5 Asset Optimization Checklist

Purpose: make package size, first load, and runtime memory predictable for mobile and HTML5. This document is required reading before any release export, Firebase deploy, Play Store upload, or "package-ready" claim.

## Required Reading For Packaging Agents

- Read this document before touching `export_presets.cfg`, `Export/`, Firebase deploy files, audio files, texture files, import settings, or generated UI assets.
- Read `docs/release_packaging_checklist.md` after this document and run both checklists together.
- Read `docs/audio_pipeline.md` before changing BGM or SFX compression.
- Read `docs/ui_gameplay_layout_checklist.md` before deleting, resizing, or replacing generated UI art.
- Read `docs/ui_cyber_component_generation_manifest.json` before deciding whether a generated file is runtime, reference, raw, or audit-only.

## Hard Rule: No Fallback, No Guessing

- No fallback asset path is allowed in this project.
- No broad export include such as `*.png`, `*.ogg`, or `Assets/**` is allowed.
- No optimization may change visual coordinates, owner-approved regions, or theme paths without updating SSOT.
- No generated reference, raw, preview, or debug file may ship because it "might be useful later".
- No asset may be downscaled, converted, recompressed, or removed until its runtime role is known from SSOT or manifest.
- If role is unclear, package-ready is blocked until role is documented.

## Current Heavy Payload Snapshot

Measured on 2026-07-03 from this workspace:

| Payload | Current Size | First Action |
| --- | ---: | --- |
| `Export/glyphflow_arrays.pck` | 13.51 MB after import recompression | Under 30.0 MB Web PCK budget. |
| `Export/glyphflow_arrays.wasm` | 33.74 MB | Keep as engine/runtime budget baseline; do not chase art fixes here first. |
| `Export/glyphflow_arrays.aab` | 57.39 MB after import recompression | Under 80.0 MB Android AAB budget. |
| `Audio/Music/cyberpunk_theme/Gameplay.ogg` | 2.58 MB | Publish profile is Vorbis q0, 44.1kHz mono; keep under `AssetBudgetConfig.bgm_mb`. |
| `Assets/VFX/lightning_boltarc_01_spritesheet.png` | 3.89 MB | Verify frame dimensions, frame count, import compression, and whether all frames ship. |
| `Assets/Themes/cyberpunk_theme/cell_tiles/dark_floorplate_b.png` | 2.58 MB | Create runtime-size derivative only after visual audit. |
| `Assets/Themes/cyberpunk_theme/cell_tiles/light_floorplate_a.png` | 2.08 MB | Create runtime-size derivative only after visual audit. |
| generated UI `*_raw.png`, `component_refs`, `style_trial_*` | many 1.5-2.5 MB files | Must not ship in runtime exports. |

## Runtime Asset Manifest

Create or update a canonical runtime manifest before export optimization. It may live in `docs/runtime_asset_manifest.json` or a future resource file if code needs to consume it.

Each runtime asset entry must include:

- `path`: exact `res://` path.
- `role`: one of `runtime`, `reference_only`, `raw_generation`, `debug_only`, `source_only`, `audit_only`.
- `theme`: `cyberpunk_theme` unless global.
- `mode`: `dark`, `light`, `shared`, or `orientation`.
- `orientation`: `portrait`, `landscape`, or `shared`.
- `owner_approved`: boolean.
- `runtime_required`: boolean.
- `source_dimensions`: pixel size.
- `runtime_draw_rect`: if cropped or atlas-sliced by SSOT.
- `compression_policy`: import/compression decision.
- `export_policy`: `include` or `exclude`.

Package-ready requires every file under these roots to have an explicit role:

- `Assets/UI/cyberpunk_theme/generated/`
- `Assets/UI/cyberpunk_theme/component_refs/`
- `Assets/Themes/cyberpunk_theme/`
- `Assets/VFX/`
- `Audio/Music/cyberpunk_theme/`
- `Audio/Sfx/cyberpunk_theme/`

## Forbidden Runtime Payload

These must not appear in Web `.pck`, Android `.aab`, or any production deploy:

- `debug/`
- `Tests/`
- `docs/`
- `component_refs/`
- `style_trial_`
- `preview_sheet`
- `*_raw.png`
- `raw.png`
- `backup_cyberpunk_assets_before`
- `energy_sheets_ai`
- old themes such as `fruit_theme`, `garden_theme`, `wood_theme`, `chaos`
- default fallback audio such as `Audio/Music/Gameplay` or `Audio/Sfx/default`
- MCP/debug tooling, generated captures, local scratch files, and owner review HTML editors.

## Export Exclusion Gate

Before export:

1. Inspect `export_presets.cfg`.
2. Remove broad include filters.
3. Use explicit include paths only for runtime assets.
4. Add explicit exclude paths for raw/reference/debug/doc/test folders.
5. Clear `.godot/editor/filesystem_cache8` and `.godot/exported`.
6. Re-export Web and Android.
7. Search exported payloads for forbidden runtime payload names.

The export preset is invalid if a path ships only because a broad wildcard included it.

## Import Compression Gate

Every runtime texture must have an import decision based on role:

| Asset Type | Policy |
| --- | --- |
| Full-screen background | Use one portrait and one landscape source per mode; max runtime dimensions must match actual display need, not generated source size. |
| Top tray and bottom tray objects | Keep alpha clean; use atlas/crop only from SSOT; avoid shipping raw generation files. |
| Floating buttons | Prefer one shell per active state only; unused states must be excluded or lazy-loaded after modal/state logic needs them. |
| Board backplate | Runtime-size derivative allowed after owner visual check; preserve owner-approved placement rect. |
| Cell tile | Runtime-size derivative required if source exceeds draw need by more than 2x. |
| Pipe sprites and energy sheets | Keep pixel-perfect frame geometry; downscale only by regenerating full canonical sheet and updating asset geometry SSOT. |
| Lightning/VFX atlas | Cap frame count, frame dimensions, and arc count through ThemeConfig; avoid shipping unused frames. |
| Icons/logo | Trim transparent padding physically; SSOT bbox must match final file. |

Compression checks:

- Verify source pixel dimensions and runtime draw dimensions.
- If source dimension is more than 2x runtime draw dimension, create an optimized runtime derivative instead of shipping full source.
- If alpha edge quality matters, test on dark, light, and checkerboard backgrounds before accepting compression.
- If an import mode changes visual output, capture screenshots before and after.
- Canonical publish import policy for heavy runtime UI, board, cell tile, VFX atlas, and energy-sheet PNGs is `compress/mode=1` with `compress/lossy_quality=0.55`.
- The canonical import numbers live in `AssetBudgetConfig.texture_import_compress_mode` and `AssetBudgetConfig.texture_import_lossy_quality`; do not tune `.import` files without changing that SSOT and its test.

## Texture Budget

Default budget until owner changes it in a canonical asset budget file:

| Category | Target |
| --- | ---: |
| Single runtime PNG/WebP source | <= 1.2 MB |
| Full-screen portrait background | <= 2.0 MB |
| Full-screen landscape background | <= 2.0 MB |
| VFX atlas | <= 1.5 MB |
| Cell tile source | <= 0.8 MB |
| Total runtime generated UI textures per mode | <= 10 MB |
| Total packed runtime textures | <= 25 MB |

Budget violations are allowed only with an explicit owner-approved reason written next to the manifest entry.

## Audio Budget

Follow `docs/audio_pipeline.md` first.

Default budget:

| Asset | Target |
| --- | ---: |
| `Audio/Music/cyberpunk_theme/Gameplay.ogg` | <= 3.0 MB unless owner approves longer loop. |
| Each SFX OGG | <= 150 KB |
| Total SFX folder | <= 2.0 MB |

Audio optimization order:

1. Trim silence.
2. Confirm loop length is intentional.
3. Lower Vorbis quality in small steps and listen on phone speakers.
4. Keep sample rate and channels in `ThemeConfig`.
5. Update `Audio/Music/cyberpunk_theme/manifest.json`.
6. Run audio SSOT tests.

Current publish profile for Cyber BGM:

- `ThemeConfig.bgm_mobile_sample_rate = 44100`
- `ThemeConfig.bgm_mobile_channels = 1`
- `ThemeConfig.bgm_vorbis_quality = 0`
- `AssetBudgetConfig.bgm_publish_vorbis_quality = 0.0`
- Current `Gameplay.ogg` size is 2.58 MB for 479.78 seconds.

Do not create alternate BGM fallbacks.

## HTML5 Initial Download Budget

HTML5 load is dominated by:

- engine `.wasm`
- game `.pck`
- server compression and cache headers
- first-scene eager loads

Default target before wider release:

| File | Target |
| --- | ---: |
| `Export/glyphflow_arrays.wasm` | report-only unless engine export changes |
| `Export/glyphflow_arrays.pck` | <= 30 MB |
| first load over network | <= 10 seconds on typical 4G after cache miss |

HTML5 checklist:

- Ensure `.wasm`, `.pck`, `.js`, and `.html` are served compressed by Firebase Hosting.
- Ensure immutable cache headers for versioned export files.
- Do not deploy Android artifacts, logs, `.import`, pack audit files, or screenshots to Firebase public root.
- Test first load in a fresh browser profile or cache-disabled browser.
- Record load time, total transferred bytes, and console errors.

## Android Bundle Budget

Default target before Play upload:

| File | Target |
| --- | ---: |
| `Export/glyphflow_arrays.aab` | <= 80 MB |
| installed runtime memory on mid device | no visible stutter during first gameplay board |

Android checklist:

- Export release AAB only after Web pack audit passes.
- Inspect AAB entries for forbidden payload names.
- Install or run on a real device if available.
- Watch first level load, theme switch, settings modal, VFX-heavy solved board, and audio loop.

## Lazy Loading Gate

Use lazy loading when audit shows runtime loads assets not needed for the current screen.

Candidates:

- inactive light/dark mode assets
- unused button states
- modal frames before modal opens
- leaderboard/profile assets before popup opens
- solved/win assets before solve
- large VFX atlases if VFX can start after first frame

Rules:

- ThemeConfig stores paths, not preloaded textures for every optional asset.
- Runtime cache must be keyed by mode, orientation, and asset key.
- Missing path is an error, not fallback.
- Switching mode must clear stale generated texture caches.

## Cache And CDN Gate

Firebase deploy must not become a random file dump.

Checklist:

- Deploy only Web runtime files.
- Use explicit `firebase.json` ignore rules for AAB, ZIP, logs, `.import`, debug captures, and audit files.
- Confirm browser receives compression.
- Confirm repeated load uses cache.
- Add a version query or filename change when replacing export files.

## SSOT Fields To Add Before Optimization

Before changing real assets, add a canonical budget source. Use a separate `AssetBudgetConfig`; runtime theme resources must not embed packaging metadata or forbidden scan markers.

- `web_pck_mb`
- `android_aab_mb`
- `texture_total_mb`
- `generated_ui_mode_mb`
- `single_texture_mb`
- `vfx_atlas_mb`
- `bgm_mb`
- `sfx_total_mb`
- `forbidden_export_markers`
- `runtime_manifest_path`
- `texture_import_compress_mode`
- `texture_import_lossy_quality`
- `bgm_publish_vorbis_quality`

Until these are implemented, this document is the packaging gate. Do not bury budget numbers in export scripts only.

## Verification Commands

List largest runtime candidates:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
Get-ChildItem "$project\Assets","$project\Audio" -Recurse -File |
  Sort-Object Length -Descending |
  Select-Object -First 60 @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}, FullName |
  Format-Table -AutoSize
```

Check export sizes:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
Get-ChildItem "$project\Export" -File |
  Sort-Object Length -Descending |
  Select-Object @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}, FullName |
  Format-Table -AutoSize
```

Audit forbidden strings in Web pack:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
$bad = Select-String -Path "$project\Export\glyphflow_arrays.pck" -Pattern `
  'debug/','Tests/','docs/','component_refs/','style_trial_','preview_sheet','_raw.png','raw.png',`
  'backup_cyberpunk_assets_before','energy_sheets_ai','Audio/Music/Gameplay','Audio/Sfx/default',`
  'fruit_theme','garden_theme','wood_theme','chaos' -SimpleMatch
if ($bad.Count -gt 0) { $bad | Select-Object -First 40; exit 1 }
```

Audit forbidden strings in Android bundle:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
$bad = Select-String -Path "$project\Export\glyphflow_arrays.aab" -Pattern `
  'debug/','Tests/','docs/','component_refs/','style_trial_','preview_sheet','_raw.png','raw.png',`
  'backup_cyberpunk_assets_before','energy_sheets_ai','Audio/Music/Gameplay','Audio/Sfx/default',`
  'fruit_theme','garden_theme','wood_theme','chaos' -SimpleMatch
if ($bad.Count -gt 0) { $bad | Select-Object -First 40; exit 1 }
```

Run contract test:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_asset_optimization_checklist_contract.gd'
```

Run mobile publish import policy test:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_mobile_publish_asset_import_policy.gd'
```

Clear stale Godot import/export cache before final export:

```powershell
$project='C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
Remove-Item "$project\.godot\imported" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\exported" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\uid_cache.bin" -Force -ErrorAction SilentlyContinue
Remove-Item "$project\.godot\global_script_class_cache.cfg" -Force -ErrorAction SilentlyContinue
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path $project --import
```

## Owner Approval Gate

Owner must approve:

- any visible texture downscale
- any alpha/compression change that affects UI edge quality
- any BGM quality or loop length change
- any VFX atlas frame count reduction
- any removal of a runtime asset path from `ThemeConfig`

Owner does not need to approve:

- excluding raw/reference/debug/doc/test files from export
- excluding old themes and fallback audio from export
- cache cleanup before export
- adding manifest metadata that records existing asset roles

## Package-Ready Definition

Package-ready means all are true:

- Runtime asset manifest exists and every asset role is known.
- Export filters include only runtime payload and explicit engine files.
- Forbidden runtime payload scan passes for Web and Android.
- Texture and audio budget report is attached to release notes or checklist output.
- Any budget violation has owner-approved reason.
- Web export loads with no missing asset errors.
- Android AAB contains manifest and native libraries.
- Full Godot test sweep passes.
- `docs/release_packaging_checklist.md` and this document were both followed in the same packaging pass.

## Closed Checklist For Current Session

- [x] Asset optimization checklist created.
- [x] Release packaging checklist links to this document.
- [x] Contract test added: `Tests/test_asset_optimization_checklist_contract.gd`.
- [x] Runtime asset manifest created: `docs/runtime_asset_manifest.json`.
- [x] Budget SSOT moved into `Resources/Data/AssetBudgets/cyberpunk_asset_budget.tres`; runtime `ThemeConfig` does not embed packaging scan markers.
- [x] Export filters tightened against runtime manifest for raw/reference/debug files and unused generated button state PNGs.
- [x] Source/reference UI assets moved into `Assets/UI/cyberpunk_theme/source_archive/` with `.gdignore`.
- [x] Web export rebuilt with selected runtime resources: `Export/glyphflow_arrays.pck` = 43.61 MB, forbidden scan clean.
- [x] Android export rebuilt with selected runtime resources: `Export/glyphflow_arrays.aab` = 87.63 MB, forbidden scan clean.
- [x] Mobile publish import policy added: runtime heavy PNGs and energy sheets use lossy import q0.55 from `AssetBudgetConfig`.
- [x] BGM publish profile optimized: 479.78s nonstop loop, Vorbis q0, 44.1kHz mono, 2.58 MB.
- [x] Web and Android exports rebuilt after import recompression: `Export/glyphflow_arrays.pck` = 13.51 MB, `Export/glyphflow_arrays.aab` = 57.39 MB.
- [x] Owner budget gate passed: Web PCK budget is 30.0 MB and Android AAB budget is 80.0 MB.
- [x] Runtime texture derivative gate evaluated; no derivative pass required because import recompression brought exports under budget without changing owner-approved coordinates.
- [x] Web and Android exports rebuilt and size-audited after export strategy cleanup and import recompression.
- [x] Full Godot test sweep passed: `TOTAL:71 ALL_OK:True`.
