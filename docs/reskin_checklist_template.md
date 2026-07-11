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
- [ ] `docs/asset_generation_guardrails.md` read.
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

## Canonical Cross-Platform Standard

- [ ] Reusable function behavior owner identified in `ShinokuteGameCore`.
- [ ] Game adapter/wrapper files identified.
- [ ] Game-owned UI/function skin files identified.
- [ ] UI skin/layout SSOT exists before UI edits.
- [ ] Asset checklist/manifest maps every changed old/default role to a canonical new role.
- [ ] Core wiring map names each enabled feature, core owner, game wrapper, game skin, test, and proof screenshot.
- [ ] Platform map covers iOS, Android, HTML5, and Roblox.
- [ ] iOS, Android, HTML5, and Roblox consume the same canonical asset keys.
- [ ] Platform-specific derivatives are recorded as derivatives of canonical asset keys, not new design branches.
- [ ] Platform-specific code is isolated in platform layers/branches/shims.
- [ ] No reusable function code is copied into game scenes or platform branches.

Platform map:

| Platform | Runtime/export layer | Input/view shim | Canonical asset keys used | Derivative assets | Notes |
|---|---|---|---|---|---|
| iOS | | | | | |
| Android | | | | | |
| HTML5 | | | | | |
| Roblox | | | | | |

## Existing Asset Inventory

Asset manifest:

- Path:
- [ ] Block Kit rows filled for changed/generated assets.
- [ ] In-game Size recorded for every accepted asset.
- [ ] Owner Rect recorded for text-bearing assets.
- [ ] Paid generation approval recorded before generation.
- [ ] Generated PNG reviewed before conversion/import.
- [ ] Platform usage recorded for iOS, Android, HTML5, and Roblox.
- [ ] No platform-specific asset fork exists without owner approval and manifest notes.

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
- [ ] Platform map stored or linked from SSOT/docs.
- [ ] Platform derivatives linked to canonical asset keys.

Hardcoded values removed:

## Core Wiring

- [ ] Core feature wiring is logic/service only; feature completion also requires game-owned UI/function skin.
- [ ] Existing core function owner checked before writing new behavior.
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

Copied reusable function code removed or avoided:

## Core Learning Gate

- [ ] New reusable behavior/schema discovered during this reskin is listed.
- [ ] Each item is classified as core-owned, game-owned, function-skin-owned,
      or platform-owned.
- [ ] Core-owned behavior/schema lives in `addons/shinokute_game_core`.
- [ ] Game repo keeps only skin, config, assets, adapters, and platform shims.
- [ ] `ShinokuteReskinBoundaryAudit` or
      `Tests/test_reskin_core_audit_contract.gd` passed.
- [ ] No core file contains hardcoded game names, skin paths, stale JS globals,
      duplicate game-local schema names, or export stale markers.

Core learning notes:

| Learned behavior/schema | Owner layer | Core file or game adapter | Test/contract | Notes |
|---|---|---|---|---|
| | | | | |

## Platform Input Matrix

- [ ] PC keyboard/mouse behavior recorded.
- [ ] Gamepad behavior recorded.
- [ ] Mobile touch behavior recorded.
- [ ] iOS Web behavior recorded.
- [ ] Android Web/native behavior recorded.
- [ ] HTML5 desktop behavior recorded.
- [ ] Roblox behavior recorded when relevant.
- [ ] All platform adapters route into one semantic core input path when
      possible.

| Platform | Move | Look/camera | Jump/action | Zoom | Adapter/shim | Notes |
|---|---|---|---|---|---|---|
| PC keyboard/mouse | | | | | | |
| Gamepad | | | | | | |
| Mobile touch | | | | | | |
| iOS Web | | | | | | |
| Android Web/native | | | | | | |
| HTML5 desktop | | | | | | |
| Roblox | | | | | | |

## Export Audit

- [ ] Selected export resources include every runtime core helper.
- [ ] Selected export resources do not include removed game-local schema files.
- [ ] Generated package/PCK scanned for stale schema names.
- [ ] Generated package/PCK scanned for debug/source folders.
- [ ] Generated package/PCK scanned for old JS globals and platform bridge
      names.
- [ ] Export audit result recorded before publish/test-link handoff.

Enabled shared core features:

| Feature | Core wired | Game-owned UI/function skin | SSOT/theme asset keys | Contract test | Screenshot evidence |
|---|---|---|---|---|---|
| Username/profile | | | | | |
| Leaderboard | | | | | |
| Result/game over | | | | | |
| Settings | | | | | |
| Menus/routes | | | | | |
| Ads/publish prompts | | | | | |

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
- [ ] Each enabled shared feature has game-owned UI.
- [ ] Shared feature UI uses game SSOT/theme assets.
- [ ] Every reused asset has matching role, ratio, crop, padding, and owner
      rect.
- [ ] Every new generated asset has owner approval.
- [ ] Function-skin visuals live in the game repo, not Shinokute core.
- [ ] Contract test proves chosen controls use SSOT asset keys/owner rects.
- [ ] Contract test and screenshot validation exist for each enabled shared-feature UI.

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
