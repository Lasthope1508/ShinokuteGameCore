# Shared Core Migration Audit

Date: 2026-07-04

Scope:
- Bloxchain source: `C:/Users/Admin/Desktop/Game`
- Glyphflow Arrays source: `C:/w/water/WaternetGodot_Cyberpunk`
- Shared core repo: `C:/Users/Admin/Desktop/ShinokuteGameCore`

## Current Shared Core

`ShinokuteGameCore` already owns:
- `GameCoreConfig`
- `LocalSaveStore`
- `PlayerProfile`
- `LeaderboardClient`
- `GeoService`
- `GameCore`
- `UsernamePromptOverlay`

Games should configure those systems through resources and adapters, not copy profile, geolocation, save-profile, or leaderboard HTTP logic into gameplay scenes.

## More Core Candidates

### P0: AudioCore

Evidence:
- Bloxchain: `C:/Users/Admin/Desktop/Game/Resources/Globals/AudioManager.gd`
- Glyphflow Arrays: `C:/w/water/WaternetGodot_Cyberpunk/Resources/Globals/AudioManager.gd`
- Both use canonical `Master`, `Music`, and `SFX` buses, pooled SFX players, BGM player, saved volume, and theme-aware asset lookup.
- Glyphflow adds required HTML5 audio unlock/debug state. This should become core because every Godot Web export needs the same no-guesswork audio contract.

Move to core:
- bus creation and lookup
- master/music/sfx toggle contract
- SFX pool
- BGM stream player
- HTML5 unlock on first user gesture
- debug state for browser probes

Keep game-local:
- concrete BGM/SFX paths
- theme-specific SFX pitch and volume offsets
- game event names such as rotate, win, invalid, combo

### P0: PublishCore

Evidence:
- Bloxchain: `docs/mobile_html5_asset_optimization_checklist.md`, `docs/runtime_asset_manifest.json`, `export_presets.cfg`, `firebase.json`
- Glyphflow Arrays: `docs/mobile_html5_asset_optimization_checklist.md`, `docs/runtime_asset_manifest.json`, `docs/release_packaging_checklist.md`, `firebase.json`

Move to core:
- publish checklist template
- runtime asset manifest schema
- forbidden export marker scan
- Android/Web packaging gates
- HTML5 audio packaging rule: do not hand-edit shell and do not omit audio imports

Keep game-local:
- actual export preset values
- Firebase site target
- package id
- asset allowlist

### P1: SceneTransitionCore

Evidence:
- Bloxchain: `Resources/Globals/SceneRouter.gd`, `Scenes/Common/FadeTransition.tscn`, `Scenes/Common/FadeTransition.gd`
- Glyphflow Arrays: `Resources/Globals/SceneRouter.gd`, `Scenes/Common/FadeTransition.tscn`, `Scenes/Common/FadeTransition.gd`

Move to core:
- fade overlay scene
- `change_scene`, `fade_in`, `fade_out`
- busy guard

Keep game-local:
- splash/main/game scene paths
- transition duration resource override

### P1: OverlayCore

Evidence:
- Bloxchain: `Scenes/Common/ElasticOverlay.gd`, `SettingsOverlay`, `LeaderboardOverlay`, `UsernamePromptOverlay`
- Glyphflow Arrays: `Scenes/Common/ElasticOverlay.gd`, `ProfilePopup`

Move to core:
- elastic popup enter/exit animation
- modal lifecycle signals
- common close/cancel contract
- settings row layout helper

Keep game-local:
- concrete art frames
- text labels
- game-specific settings options

### P1: AdCore

Evidence:
- Bloxchain: `Resources/Globals/AdManager.gd`
- Glyphflow Arrays: `Resources/Globals/AdManager.gd`

Move to core:
- platform enum
- banner/interstitial/rewarded signal contract
- mock mode
- Android/Web bridge wrappers

Keep game-local:
- ad unit ids
- ad pacing policy
- reward meaning

### P2: ThemeTokenCore

Evidence:
- Bloxchain: `Resources/Globals/ThemeManager.gd`
- Glyphflow Arrays: `Resources/Globals/ThemeManager.gd`

Move to core:
- theme registry/resource loader shape
- active theme save key
- theme changed signal
- common button/panel token injection helper

Keep game-local:
- `ThemeConfig` fields tied to board geometry, pipe assets, fake3D, or skin-specific UI coordinates
- actual textures, colors, and generated assets

### P2: VfxCatalogCore

Evidence:
- Glyphflow Arrays: `Scripts/pipe_vfx_layer.gd`, `Scripts/vfx_route.gd`, `Scripts/vfx_anchor.gd`, `Scripts/vfx_transition_state.gd`, `docs/vfx_usage_library.md`, `docs/vfx_effect_parameters.md`
- Bloxchain has VFX configs inside `ThemeManager.gd`.

Move to core:
- effect parameter catalog schema
- named effect registry
- performance budget fields
- docs template for VFX usage

Keep game-local:
- pipe route solver
- board anchor derivation
- concrete lightning/energy visuals
- gameplay-specific trigger rules

## Do Not Move

Keep these inside each game:
- puzzle solver and level generation
- grid coordinate math
- pipe geometry SSOT
- fake3D board layout
- generated UI region coordinates
- 9router/Photoroom source manifests tied to a specific art direction
- concrete Firebase collections until `GameCoreConfig` owns collection naming per game

## Naming Rule For Glyphflow Arrays

Canonical product name: `Glyphflow Arrays`.

Allowed legacy folder names:
- `WaternetGodot_Cyberpunk`
- `WaternetGodot`

Reason: current Git/Godot folder layout still uses those names. Folder rename is a separate migration because import metadata, docs, release scripts, debug tools, and external bookmarks reference the path.

Runtime and docs should not use `Waternet` as a brand. Use:
- `Glyphflow Arrays` for product
- `energy`, `energized`, `flow`, or `conduit` for gameplay
- `source` and `target` for endpoints

## Next Migration Order

1. Move `AudioCore` into `ShinokuteGameCore` with tests for buses, toggles, saved volume, SFX pool, BGM path adapter, and HTML5 unlock debug.
2. Move `PublishCore` docs/scripts into `ShinokuteGameCore` so every game has one package gate.
3. Move `SceneTransitionCore` and `OverlayCore`.
4. Move `AdCore` after ad unit ids are config-only.
5. Move `ThemeTokenCore` and `VfxCatalogCore` only after at least two games use the same resource schema.
