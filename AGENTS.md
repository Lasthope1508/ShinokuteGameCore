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
3. Read `docs/reskin_core_skin_boundary.md`.
4. Read `docs/reskin_runbook.md`.
5. Read `docs/git_branch_topology.md` before committing or pushing any core
   or game branch.
6. Read `docs/asset_generation_guardrails.md` before generating or editing art.
7. Read `docs/art_ui_design_gate.md` and use
   `tools/validate_art_ui_gate.py` before claiming any game UI/art pass is
   complete.
8. Read `docs/gameplay_progression_ssot.md` before adding or migrating
   level completion, fail/retry, or difficulty-scaling behavior.
9. Copy `docs/reskin_checklist_template.md` into the game repo if the game
   has no local reskin checklist.
10. Use `templates/new_game` when starting a fresh game.
11. Create or update the game-owned `GameCoreConfig.tres`.
12. Create or update the game-owned `ShinokuteThemeConfig.tres`.
13. Create a game rules adapter that follows `core/game_rules_adapter.gd`.
14. Wire gameplay through `GameCore`, not through copied managers.
15. Run `tools/reskin_audit.ps1 -GameRoot <game> -FailOnWarnings`.
16. Run Shinokute core tests before claiming the reskin is ready.
17. Run the Core Learning Gate after any reskin uncovers reusable behavior.
    Use `ShinokuteReskinBoundaryAudit` and
    `Tests/test_reskin_core_audit_contract.gd` before pushing core changes.

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
- Do not mark profile, username, leaderboard, settings, ads, menus, result, or publish features complete after code wiring only.
- Each enabled core feature needs game-owned UI/function skin, backed by game SSOT/theme assets, contract tests, and screenshot evidence.
- Do not put game-specific board, puzzle, physics, or scoring rules into
  Shinokute core.
- Do not bypass `GameSession` for run lifecycle.
- Do not bypass `GameRulesAdapter` for game-specific rule logic.
- Do not continue when text overflows, overlaps, or does not fit its visual
  owner region.
- Do not forget game context: menus, popups, buttons, settings, and result
  screens must still look like the current game, not a generic app UI.
- Do not place generated or reused art into production scenes before it exists
  in the game-local asset manifest with owner rect, padding, and In-game Size.
- Do not run paid asset generation without owner approval.
- Do not report completion without running tests.
- Do not call UI/art done when `RUNTIME_FIT_PASS` only proves layout fit.
  Final art needs the Art UI Design Gate and must clear `ART_DESIGN_PENDING`.
- Do not call generated/runtime UI images production-ready unless the game
  contract selects a core `image_quality_profile` and every declared UI PNG
  meets its source-scale requirement.
- Do not leave reusable behavior/schema duplicated in a game after it has been
  identified as core-owned.
- Do not push core changes that contain game names, game asset paths, stale JS
  globals, duplicate game-local schema names, or export stale markers.

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
- [ ] Every enabled shared core feature has game-owned UI/function skin.
- [ ] Shared feature UI uses game SSOT/theme assets and has test/screenshot evidence.
- [ ] Text and text-owner regions fit desktop and mobile viewports.
- [ ] Changed screens still read as game screens.
- [ ] Asset manifest contains Block Kit rows for changed/generated assets.
- [ ] Art UI Design Gate has game-owned docs/contract and passes
      `tools/validate_art_ui_gate.py`.
- [ ] `tools/reskin_audit.ps1 -GameRoot <game> -FailOnWarnings` passes.
- [ ] Core Learning Gate completed for reusable behavior discovered by this
      reskin.
- [ ] `ShinokuteReskinBoundaryAudit` or the matching test contract was run
      after core edits.
- [ ] Platform Input Matrix records PC, mobile touch, iOS/Android Web, HTML5
      desktop, and Roblox expectations when input/camera/control behavior
      changes.
- [ ] Export Audit scanned selected resources and generated packages for stale
      schema names, debug/source files, and old JS globals.

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
