# Shinokute Game Core

Shared Godot addon for modules every Shinokute casual game needs: player profile, first-run username prompt, local save keys, geolocation cache, leaderboard payloads, and game-specific score metric contracts.

This repo is the canonical home for reusable cross-game code. Individual games should configure the addon through `GameCoreConfig.tres` and should not copy/paste leaderboard or profile logic into gameplay scenes.

## Required Reskin Reading

Every agent must read `docs/reskin_core_skin_boundary.md` before reskinning any Shinokute game. Core owns behavior; each game owns game skin and function skin.

## Modules

- `GameCoreConfig`: SSOT for game id, Firebase endpoint, score sort, collection names, username policy, and leaderboard display labels.
- `LocalSaveStore`: ConfigFile-backed profile/progress storage compatible with HTML5 `user://`.
- `PlayerProfile`: first-run username policy, validation, default username generation, and profile-ready signals.
- `LeaderboardClient`: Firestore REST URL/payload/query builder and score submission/fetch orchestration.
- `GeoService`: geolocation request/cache handling without hardcoded country fallback.
- `UsernamePromptOverlay`: reusable first-run prompt scene.

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
