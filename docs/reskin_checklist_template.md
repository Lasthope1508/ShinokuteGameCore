# Shinokute Reskin Checklist Template

Copy this file into the target game repo before starting a production reskin.
Rename it to `docs/reskin_checklist.md` or a game-specific checklist name.

## Project

- Game name:
- Repo path:
- Reskin goal:
- Owner-approved scope:
- Target platforms:
- ShinokuteGameCore commit:
- Game commit before edits:

## Required Reading

- [ ] `AGENTS.md` read.
- [ ] `docs/reskin_core_skin_boundary.md` read.
- [ ] `docs/reskin_runbook.md` read.
- [ ] `addons/shinokute_game_core/README.md` read.
- [ ] `templates/new_game` copied or existing game structure documented.
- [ ] Game-local publish checklist read if web/mobile publish is in scope.

## Scope Classification

- [ ] Game skin only.
- [ ] Function skin only.
- [ ] Rules adapter work.
- [ ] Shared core work.
- [ ] Publish/release work.

Notes:

## Existing Asset Inventory

| Role | Existing asset key/path | Owner rect | Padding | Ratio/crop | Reuse decision |
|---|---|---|---|---|---|
| Logo | | | | | |
| Main button | | | | | |
| Text input shell | | | | | |
| Popup panel | | | | | |
| Leaderboard row | | | | | |
| Settings row | | | | | |
| HUD score area | | | | | |

New asset requests approved by owner:

## SSOT Resources

- [ ] `GameCoreConfig.tres` updated.
- [ ] `ShinokuteThemeConfig.tres` updated.
- [ ] Board/layout SSOT updated.
- [ ] Function-skin owner rects stored in SSOT.
- [ ] Text limits stored in SSOT.
- [ ] Audio event names stored in SSOT.
- [ ] Scene routes stored in SSOT.
- [ ] Overlay routes stored in SSOT.

Hardcoded values removed:

## Core Wiring

- [ ] `GameCore.configure(...)` used.
- [ ] `GameCore.configure_rules_adapter(...)` used.
- [ ] Runs start through `GameCore.start_run`.
- [ ] Moves go through `GameCore.session.apply_move`.
- [ ] Scores go through `GameCore.submit_score`.
- [ ] Leaderboards go through `GameCore.fetch_leaderboard`.
- [ ] Menus use `scene_router`.
- [ ] Popups use `overlay_manager`.
- [ ] SFX/haptics use `audio_haptics`.
- [ ] Ads use `ads`.
- [ ] Analytics use `analytics`.
- [ ] Text uses `localization`.
- [ ] Tuning uses `remote_config`.

Copied manager code removed or avoided:

## Rules Adapter

- Rules adapter file:
- [ ] `start_run` implemented.
- [ ] `can_make_move` implemented.
- [ ] `apply_move` implemented.
- [ ] `is_game_over` implemented.
- [ ] `get_result` implemented.
- [ ] Invalid move behavior tested.
- [ ] Game over/result behavior tested.

## Text Fit And Game Context

- [ ] All labels fit inside their owner regions at desktop viewport.
- [ ] All labels fit inside their owner regions at mobile viewport.
- [ ] Text does not overlap art, safe area padding, buttons, inputs, scores,
      or neighboring controls.
- [ ] Text hierarchy matches the control role and game context.
- [ ] No compact game control uses hero-size text.
- [ ] Native input/control backgrounds are transparent when asset art owns the
      frame.
- [ ] Screen still reads as a game screen, not a generic app form.
- [ ] Screenshots captured for all changed screens.

Screenshot paths:

## Function Skin Gates

- [ ] Existing assets were inventoried before new visual shells were created.
- [ ] Every reused asset has matching role, ratio, crop, padding, and owner
      rect.
- [ ] Every new generated asset has owner approval.
- [ ] Function-skin visuals live in the game repo, not Shinokute core.
- [ ] Contract test proves chosen controls use SSOT asset keys/owner rects.

## Tests

Reskin audit command:

- Command:
- Result:
- HardcodedValueAudit:
- TextFitEvidence:
- ScreenshotEvidence:

Shinokute core tests:

- Command:
- Result:
- Pass count:

Game-local tests:

- Command:
- Result:
- Pass count:

Godot import:

- Command:
- Result:

Smoke run:

- Command/URL:
- Result:
- Screens checked:

Screenshot verification checklist:

- Path:
- Desktop viewport evidence:
- Mobile viewport evidence:

## Publish Evidence

Fill only if publishing or making an owner test link.

- Publish runbook read:
- Firebase project:
- Hosting target:
- Export preset:
- Output directory:
- Artifact sizes:
- URL:
- Browser smoke result:
- Header/cache result:
- Screenshot paths:

## Completion

- Commit hash:
- Known warnings:
- Known gaps:
- Owner follow-up needed:
