# Shinokute Game Core

Shared Godot addon for modules every Shinokute casual game needs: player profile, first-run username prompt, local save keys, geolocation cache, leaderboard payloads, game session flow, UX routing, theme services, ads, analytics, localization, remote config, audio, and haptics.

This repo is the canonical home for reusable cross-game code. Individual games should configure the addon through `GameCoreConfig.tres` and should not copy/paste leaderboard or profile logic into gameplay scenes.

## Required Reskin Reading

Every agent must read `AGENTS.md` before touching game code for a new reskin.

Every agent must read `docs/reskin_core_skin_boundary.md` before reskinning any Shinokute game. Core owns behavior; each game owns game skin and function skin.

Every agent must read `docs/godot_web_publish_runbook.md` before giving the owner a web test link or publishing an official Godot Web build.

## Architecture

`addons/shinokute_game_core/` is split into three layers:

- `core/`: game-facing facade, config, save/profile/geo/leaderboard, run lifecycle, and rules adapter contract.
- `services/`: theme, audio/haptics, ads, analytics, localization, and remote config.
- `ux/`: scene routing and overlay routing.
- `ui/`: reusable UI scenes such as username prompt.

## Modules

- `GameCoreConfig`: SSOT for game id, Firebase endpoint, score sort, collection names, username policy, and leaderboard display labels.
- `GameCore`: single entrypoint that wires every core/service/UX module.
- `GameSession`: start/pause/resume/end run lifecycle, score deltas, and result signal.
- `GameRulesAdapter`: per-game rules API. New games subclass or wrap this instead of rewriting core flow.
- `LocalSaveStore`: ConfigFile-backed profile/progress storage compatible with HTML5 `user://`.
- `PlayerProfile`: first-run username policy, validation, default username generation, and profile-ready signals.
- `LeaderboardClient`: Firestore REST URL/payload/query builder and score submission/fetch orchestration.
- `GeoService`: geolocation request/cache handling without hardcoded country fallback.
- `ShinokuteThemeConfig` and `ShinokuteThemeManager`: skin colors, fonts, asset paths, audio event paths, and UI metrics.
- `ShinokuteAudioHapticsManager`: event-based SFX lookup and mobile vibration toggles.
- `ShinokuteAdsManager`: placement registry, cooldown checks, and provider-neutral ad request signals.
- `ShinokuteAnalyticsTracker`: provider-neutral event tracking signal and event cache.
- `ShinokuteLocalizationService`: locale table lookup with fallback and parameter replacement.
- `ShinokuteRemoteConfigService`: local defaults plus runtime override layer.
- `ShinokuteSceneRouter`: scene key to scene path routing.
- `ShinokuteOverlayManager`: overlay key registry and provider-neutral show/hide signals.
- `UsernamePromptOverlay`: reusable first-run prompt scene.

## New Game Contract

Each new mobile game should create these game-owned files:

- `Resources/Data/<game>_game_core_config.tres`: id, Firebase, leaderboard modes, routes, overlays, ad placements, translations, remote defaults.
- `Resources/Data/<game>_theme_config.tres`: colors, fonts, art paths, SFX paths, UI metrics.
- `Scripts/<GameName>Rules.gd`: rules adapter implementing `start_run`, `can_make_move`, `apply_move`, `is_game_over`, and `get_result`.
- Gameplay scenes call `GameCore.start_run`, `GameCore.session.apply_move`, `GameCore.submit_score`, and route/overlay services. They must not copy save, ads, leaderboard, profile, or settings code.

## Migration Roadmap

Next shared candidates live in `docs/shared_core_migration_candidates.md`.

Priority order:
- `AudioCore`: canonical buses, SFX pool, BGM player, saved toggles, HTML5 unlock/debug.
- `PublishCore`: export/package gates, runtime manifest schema, mobile/HTML5 checks.
- `SceneTransitionCore`: fade transition scene and scene router helper.
- `OverlayCore`: elastic modal lifecycle and shared popup behavior.
- `AdCore`: platform bridge signal contract.
- `ThemeTokenCore` and `VfxCatalogCore`: only after at least two games share the same resource schema.

## Tests

Run all contracts:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\Users\Admin\Desktop\ShinokuteGameCore'
Get-ChildItem "$project\Tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```
