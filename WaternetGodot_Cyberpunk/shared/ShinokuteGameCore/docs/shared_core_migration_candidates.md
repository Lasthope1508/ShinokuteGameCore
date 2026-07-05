# Shared Core Migration Candidates

Date: 2026-07-04

Compared sources:
- Bloxchain: `C:/Users/Admin/Desktop/Game`
- Glyphflow Arrays: `C:/w/water/WaternetGodot_Cyberpunk`

Current core already covers profile, local save primitives, leaderboard REST payloads, geolocation, and first-run username prompt.

## P0 Candidates

### AudioCore

Evidence:
- `C:/Users/Admin/Desktop/Game/Resources/Globals/AudioManager.gd`
- `C:/w/water/WaternetGodot_Cyberpunk/Resources/Globals/AudioManager.gd`

Shared contract:
- canonical `Master`, `Music`, `SFX` buses
- saved volume/toggle flow
- pooled SFX playback
- BGM playback/crossfade
- theme-aware audio lookup
- HTML5 first-gesture unlock and debug state

Core should own the playback contract and expose adapters for game-specific stream lookup.

### PublishCore

Evidence:
- `C:/Users/Admin/Desktop/Game/docs/mobile_html5_asset_optimization_checklist.md`
- `C:/w/water/WaternetGodot_Cyberpunk/docs/mobile_html5_asset_optimization_checklist.md`
- `C:/w/water/WaternetGodot_Cyberpunk/docs/release_packaging_checklist.md`
- `runtime_asset_manifest.json` in both games

Shared contract:
- export preset audit
- runtime asset manifest schema
- PCK/AAB forbidden marker scan
- mobile and HTML5 compression checklist
- Firebase Hosting header checklist
- HTML5 audio packaging rule: export with Godot, do not custom-shell away imports

## P1 Candidates

### SceneTransitionCore

Evidence:
- `SceneRouter.gd` in both games
- `Scenes/Common/FadeTransition.gd` in both games

Core should own fade transitions, busy guards, and common scene change helpers.

### OverlayCore

Evidence:
- `Scenes/Common/ElasticOverlay.gd` in both games
- Bloxchain settings/leaderboard/username overlays
- Glyphflow profile popup

Core should own modal lifecycle, open/close animation, and reusable popup sizing hooks.

### AdCore

Evidence:
- `Resources/Globals/AdManager.gd` in both games

Core should own platform bridge wrappers and ad signals. Games keep unit ids and reward policy in config.

## P2 Candidates

### ThemeTokenCore

Evidence:
- `Resources/Globals/ThemeManager.gd` in both games

Core can own theme registry, save key, change signal, and generic UI token application. Game-specific `ThemeConfig` fields stay local.

### VfxCatalogCore

Evidence:
- Glyphflow has VFX layer, route, anchor, transition state, usage docs, parameter docs.
- Bloxchain has VFX config catalogs embedded in `ThemeManager.gd`.

Core can own effect catalog schema and documentation pattern. Game-specific routes and trigger rules stay local.

## Migration Rule

Do not copy whole game singletons into core. Extract the stable contract first, add tests in `ShinokuteGameCore/Tests`, then adapt each game through config/resources.
