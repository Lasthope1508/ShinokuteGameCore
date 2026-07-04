# Shinokute Game Core

Shared Godot addon for modules every Shinokute casual game needs: player profile, first-run username prompt, local save keys, geolocation cache, leaderboard payloads, and game-specific score metric contracts.

This repo is the canonical home for reusable cross-game code. Individual games should configure the addon through `GameCoreConfig.tres` and should not copy/paste leaderboard or profile logic into gameplay scenes.

## Modules

- `GameCoreConfig`: SSOT for game id, Firebase endpoint, score sort, collection names, username policy, and leaderboard display labels.
- `LocalSaveStore`: ConfigFile-backed profile/progress storage compatible with HTML5 `user://`.
- `PlayerProfile`: first-run username policy, validation, default username generation, and profile-ready signals.
- `LeaderboardClient`: Firestore REST URL/payload/query builder and score submission/fetch orchestration.
- `GeoService`: geolocation request/cache handling without hardcoded country fallback.
- `UsernamePromptOverlay`: reusable first-run prompt scene.

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
