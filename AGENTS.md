# Mandatory Reskin Agent Guide

Read this file before starting any new mobile game reskin that uses
`ShinokuteGameCore`. Treat this as the project contract.

## Goal

New games must reuse Shinokute core flow instead of copying old game code.
The game owns only rules, art, theme data, scenes, and game-specific UX.
Shared systems stay in `addons/shinokute_game_core/`.

## Required Starting Steps

1. Inspect `addons/shinokute_game_core/README.md`.
2. Inspect `README.md` for current module list and test command.
3. Create or update the game-owned `GameCoreConfig.tres`.
4. Create or update the game-owned `ShinokuteThemeConfig.tres`.
5. Create a game rules adapter that follows `core/game_rules_adapter.gd`.
6. Wire gameplay through `GameCore`, not through copied managers.
7. Run Shinokute core tests before claiming the reskin is ready.

## Core Layers

- `core/`: `GameCore`, `GameCoreConfig`, `GameSession`,
  `GameRulesAdapter`, save, profile, geo, leaderboard.
- `services/`: theme, audio/haptics, ads, analytics, localization,
  remote config.
- `ux/`: scene router and overlay manager.
- `ui/`: reusable UI scenes such as username prompt.

## Game-Owned Files

Each game should own these files or equivalent paths:

- `Resources/Data/<game>_game_core_config.tres`
- `Resources/Data/<game>_theme_config.tres`
- `Scripts/<GameName>Rules.gd`
- Gameplay scenes and art/audio assets
- Optional game-specific overlay scenes

## Required Runtime Pattern

Use this shape in the game bootstrap/autoload:

```gdscript
var core := GameCore.new()
add_child(core)
core.configure(game_core_config)
core.configure_rules_adapter(game_rules)
core.ensure_profile_ready()
```

Gameplay should call:

```gdscript
core.start_run("classic", {"seed": seed})
core.session.apply_move(move_data)
core.submit_score({"mode": "classic", "value": result_value})
core.fetch_leaderboard("world", "classic")
core.scene_router.request_route("game", {"mode": "classic"})
core.overlay_manager.request_overlay("settings")
core.audio_haptics.play_event("tap")
core.analytics.track("game_start", {"mode": "classic"})
```

## Hard Rules

- Do not copy `SaveManager`, `LeaderboardManager`, `AdManager`,
  `AudioManager`, `ThemeManager`, settings, or profile code from older games.
- Do not hardcode Firebase project id, Firestore collection, score label,
  score sort direction, geolocation fallback, ad cooldown, text, colors,
  audio paths, or scene paths in gameplay scripts.
- Do not put game-specific board, puzzle, physics, or scoring rules into
  Shinokute core.
- Do not bypass `GameSession` for run lifecycle.
- Do not bypass `GameRulesAdapter` for game-specific rule logic.
- Do not report completion without running tests.

## Reskin Checklist

- [ ] `GameCoreConfig` has game id, display name, Firebase, leaderboard
      modes, score labels, sort directions, routes, overlays, ad placements,
      remote defaults, translations.
- [ ] `ShinokuteThemeConfig` has colors, fonts, asset paths, audio events,
      and UI metrics.
- [ ] Rules adapter implements `start_run`, `can_make_move`, `apply_move`,
      `is_game_over`, and `get_result`.
- [ ] Menus use `scene_router` and `overlay_manager`.
- [ ] SFX/haptics use `audio_haptics`.
- [ ] Ads use `ads`.
- [ ] Analytics use `analytics`.
- [ ] Text uses `localization`.
- [ ] Tuning values use `remote_config`.
- [ ] Scores go through `submit_score`.
- [ ] Leaderboards go through `fetch_leaderboard`.

## Test Command

Run from PowerShell:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\Users\Admin\Desktop\Godot Casual Games\shared\ShinokuteGameCore'
Get-ChildItem "$project\Tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: all `test_*.gd` scripts exit `0`.
