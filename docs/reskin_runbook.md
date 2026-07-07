# Shinokute Reskin Runbook

Use this runbook for every production mobile game reskin. Do not skip phases.
Each phase has a stop gate. If a gate fails, fix that phase before moving on.

## Phase 0: Read And Freeze Scope

1. Read `AGENTS.md`.
2. Read `docs/reskin_core_skin_boundary.md`.
3. Read `addons/shinokute_game_core/README.md`.
4. Read the target game's local reskin checklist. If none exists, create one
   from `docs/reskin_checklist_template.md` inside the game repo before edits.
5. Identify whether the work is:
   - game skin only,
   - function skin only,
   - rules adapter work,
   - shared core work,
   - publish/release work.
6. List files expected to change. Keep the list small and update it when scope
   changes.

Stop gate:
- The agent can name which layer owns each requested change.
- The agent has a game-local checklist file for evidence.
- No gameplay scene edit begins before the SSOT targets are named.

## Phase 1: Inventory Existing Game Assets

1. List approved runtime assets, generated UI/component assets, fonts, audio,
   and theme resources already in the game repo.
2. Identify existing owner regions for text, buttons, panels, inputs,
   leaderboard rows, settings rows, badges, and popups.
3. Record asset keys, owner rects, padding, aspect ratio, crop policy, and scale
   policy in the game-local checklist.
4. Decide whether each function-skin element reuses an approved asset or needs
   a new owner-approved asset request.

Stop gate:
- No new frame, border, button shell, field shell, badge, or row background is
  created before existing assets are inventoried.
- Every chosen visual asset has an SSOT key, role, owner rect, and padding.

## Phase 2: Build Or Update SSOT Resources

1. Update the game-owned `GameCoreConfig.tres`.
2. Update the game-owned `ShinokuteThemeConfig.tres`.
3. Add or update game-specific SSOT resources for board geometry, function-skin
   owner rects, text limits, VFX parameters, audio event names, and route keys.
4. Add contract tests proving gameplay and UI read these values from SSOT
   resources rather than hardcoded scene constants.

Stop gate:
- `GameCoreConfig` owns game id, Firebase, leaderboard modes, score labels,
  sort directions, routes, overlays, ads, translations, and remote defaults.
- `ShinokuteThemeConfig` owns colors, fonts, art paths, audio events, and UI
  metrics.
- No hardcoded path/color/text/scene route remains in gameplay code when an
  SSOT key exists.

## Phase 3: Wire Core Runtime

1. Instantiate and configure `GameCore`.
2. Configure the game rules adapter with `GameCore.configure_rules_adapter`.
3. Start runs through `GameCore.start_run`.
4. Apply gameplay moves through `GameCore.session.apply_move`.
5. Submit scores through `GameCore.submit_score`.
6. Fetch leaderboard data through `GameCore.fetch_leaderboard`.
7. Route screens through `core.scene_router`.
8. Route popups through `core.overlay_manager`.
9. Use `core.audio_haptics`, `core.analytics`, `core.ads`,
   `core.localization`, and `core.remote_config`.

Stop gate:
- No copied `SaveManager`, `LeaderboardManager`, `AdManager`, `AudioManager`,
  `ThemeManager`, profile, settings, route, or localization logic remains in
  new reskin work.
- Game-specific board, puzzle, enemy, physics, and scoring rules live in the
  game rules adapter or game-owned scripts, not in Shinokute core.

## Phase 4: Function Skin And Text Fit

1. For each popup, HUD label, settings row, leaderboard row, button, input, and
   badge, identify its owner visual region before placing text.
2. Match text size, alignment, wrapping, and truncation to that owner region.
3. Use the game's art style, density, and interaction role to choose text
   hierarchy. A compact in-game control should not use hero text.
4. Run desktop and mobile viewport checks.
5. Capture screenshots for all changed function-skin screens.
6. Ask whether this still looks like a game screen, not a generic app form.

Stop gate:
- Do not continue until text fits inside its owner region at all required
  viewports.
- Do not continue if a label overlaps art, buttons, input fields, score areas,
  safe area padding, or neighboring controls.
- Do not continue if the screen loses game context: gameplay visual language,
  theme assets, or player-facing feedback must still be visible.
- Do not fix overflow with random offsets. Update SSOT owner rect, text limit,
  font size token, or asset crop policy.

## Phase 5: Gameplay Smoke And Contract Tests

1. Run Shinokute core tests.
2. Run the game-local contract tests.
3. Run Godot import if assets or scenes changed.
4. Launch the game locally.
5. Exercise the full loop:
   - splash/menu,
   - start run,
   - valid move,
   - invalid move,
   - score update,
   - pause/settings,
   - game over/result,
   - username path,
   - leaderboard path.
6. Capture screenshots for changed screens.

Stop gate:
- No parse errors, missing resources, missing fonts, missing images, broken
  signals, or blank screens.
- Console output is reviewed. Known existing warnings are named; new warnings
  are fixed or documented.
- All checklist evidence fields are filled.

## Phase 6: Publish Gate

Use this phase only when creating an owner test link or official web publish.

1. Read `docs/godot_web_publish_runbook.md`.
2. Read the target game's local publish checklist.
3. Confirm Firebase project, hosting target, export preset, output directory,
   forbidden files, and smoke URL from repo config or owner-provided data.
4. Export and smoke test according to the publish runbook.
5. Record command, commit hash, artifact sizes, URL, smoke path, and screenshot
   evidence in the game-local checklist.

Stop gate:
- Do not deploy from memory.
- Do not invent Firebase ids, hosting targets, or fallback URLs.
- Do not claim publish success without a browser smoke test.

## Final Completion Report

The final report must include:

- changed layers,
- changed SSOT files,
- changed screens,
- changed rules adapter files,
- tests run and pass count,
- screenshot/smoke evidence location,
- known warnings or gaps,
- commit hash if committed.
