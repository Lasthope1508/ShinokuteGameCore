# Shinokute Reskin Runbook

Use this runbook for every production mobile game reskin. Do not skip phases.
Each phase has a stop gate. If a gate fails, fix that phase before moving on.

## Phase 0: Read And Freeze Scope

1. Read `AGENTS.md`.
2. Read `docs/reskin_core_skin_boundary.md`.
3. Read `addons/shinokute_game_core/README.md`.
4. Read `docs/asset_generation_guardrails.md` before generating or editing art.
5. Read the target game's local reskin checklist. If none exists, create one
   from `docs/reskin_checklist_template.md` inside the game repo before edits.
6. For a fresh game, copy `templates/new_game` into the target repo and rename
   example files before gameplay edits.
7. If the source/template only provides basic placeholder shapes, generic UI,
   or contract-level visuals, record that it is not production art. Add an
   art-direction and polished Block Kit gate before final art or screen
   assembly.
8. Identify whether the work is:
   - game skin only,
   - function skin only,
   - rules adapter work,
   - shared core work,
   - publish/release work.
9. Identify the canonical cross-platform layer split:
   - reusable functions and behavior in `ShinokuteGameCore`,
   - game adapters/wrappers in the target game,
   - game-owned UI/function skin in the target game,
   - platform-specific code only in platform layers/branches/shims,
   - canonical assets shared by iOS, Android, HTML5, and Roblox through the same SSOT keys.
10. List files expected to change. Keep the list small and update it when scope
   changes.
11. Start a Core Learning Gate note for any behavior that may belong in
    `ShinokuteGameCore`.

Stop gate:
- The agent can name which layer owns each requested change.
- The agent has a game-local checklist file for evidence.
- No gameplay scene edit begins before the SSOT targets are named.
- No UI/function/asset work begins before the UI skin/layout SSOT, asset checklist, core wiring map, and platform map exist or are updated.
- No final art or final screen assembly begins from a basic placeholder source
  until the owner approves a visual direction and the game has a polished Block
  Kit plan.
- The platform map confirms iOS, Android, HTML5, and Roblox use the same canonical asset keys, with platform derivatives recorded only as derivatives.
- Fresh games use `templates/new_game` or document why an existing game
  structure already satisfies the same files.
- Potential reusable behavior is tracked for the Core Learning Gate before
  implementation begins.

## Phase 1: Inventory Existing Game Assets

1. List approved runtime assets, generated UI/component assets, fonts, audio,
   and theme resources already in the game repo.
2. Create or update the game-local asset manifest from
   `templates/new_game/docs/asset_manifest.md`.
3. Identify existing owner regions for text, buttons, panels, inputs,
   leaderboard rows, settings rows, badges, and popups.
4. Record the canonical platform usage for every accepted asset role:
   iOS, Android, HTML5, and Roblox all point to the same asset key unless an
   owner-approved exception is documented.
5. Record asset keys, owner rects, padding, aspect ratio, crop policy, scale
   policy, in-game size, and platform derivatives in the game-local checklist.
6. Decide whether each function-skin element reuses an approved asset or needs
   a new owner-approved asset request.
7. If the inherited/source visuals are only placeholder level, choose and record
   a production visual direction before final art work. The direction must name
   palette, mood, gameplay readability target, UI style, and what old/default
   visuals are being replaced.
8. For a fresh test game or placeholder-only source, build a polished Block Kit
   before real screens:
   button shell, panel shell, input shell, leaderboard row, settings row,
   HUD score owner, gameplay tile/block, player, enemy, boss, projectile,
   background, and VFX.
9. Capture an asset test scene screenshot after the Block Kit is placed.

Stop gate:
- No new frame, border, button shell, field shell, badge, or row background is
  created before existing assets are inventoried.
- Placeholder shapes, debug polygons, generic default controls, and source-demo
  UI are not acceptable final art. They can only be kept as temporary contract
  proof until the polished Block Kit replaces them.
- Every chosen visual asset has an SSOT key, role, owner rect, and padding.
- Generated or reused assets have asset manifest rows with In-game Size.
- iOS, Android, HTML5, and Roblox platform usage is recorded for changed
  assets, and no platform-specific asset fork exists without owner approval.
- Asset test game blocks pass screenshot review before full screen assembly.
- The approved visual direction and Block Kit screenshot are recorded before
  production screen assembly starts.

## Phase 2: Build Or Update SSOT Resources

1. Update the game-owned `GameCoreConfig.tres`.
2. Update the game-owned `ShinokuteThemeConfig.tres`.
3. Add or update game-specific SSOT resources for board geometry, function-skin
   owner rects, text limits, VFX parameters, audio event names, and route keys.
4. Add or update the UI skin/layout SSOT for safe areas, responsive anchors,
   text owner regions, hitboxes, platform viewport behavior, and style tokens.
5. Add or update the platform map for iOS, Android, HTML5, and Roblox asset
   consumers and any platform code shims.
6. Add contract tests proving gameplay and UI read these values from SSOT
   resources rather than hardcoded scene constants.

Stop gate:
- `GameCoreConfig` owns game id, Firebase, leaderboard modes, score labels,
  sort directions, routes, overlays, ads, translations, and remote defaults.
- `ShinokuteThemeConfig` owns colors, fonts, art paths, audio events, and UI
  metrics.
- No hardcoded path/color/text/scene route remains in gameplay code when an
  SSOT key exists.
- Platform-specific code can customize input/export/safe-area/runtime shims, but
  shared gameplay/function code and canonical assets remain SSOT-driven.

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
- No copied input, camera, mobile control, overlay grouping, profile,
  leaderboard, settings, audio gate, or publish-gate function logic remains in
  game scenes when `ShinokuteGameCore` owns the reusable behavior.
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
3. Run the Core Learning Gate:
   - list what the reskin taught core,
   - move reusable behavior/schema into `addons/shinokute_game_core`,
   - leave skin/config/assets/adapters in the game,
   - run `ShinokuteReskinBoundaryAudit` or
     `Tests/test_reskin_core_audit_contract.gd`.
4. Complete the Platform Input Matrix when input/camera/control behavior
   changes.
5. Run `tools/reskin_audit.ps1 -GameRoot <game> -FailOnWarnings`.
6. Treat `HardcodedValueAudit`, `TextFitEvidence`, and `ScreenshotEvidence`
   findings as blockers.
7. Run Godot import if assets or scenes changed.
8. Launch the game locally.
9. Exercise the full loop:
   - splash/menu,
   - start run,
   - valid move,
   - invalid move,
   - score update,
   - pause/settings,
   - game over/result,
   - username path,
   - leaderboard path.
10. Capture screenshots for changed screens.

Stop gate:
- No parse errors, missing resources, missing fonts, missing images, broken
  signals, or blank screens.
- Console output is reviewed. Known existing warnings are named; new warnings
  are fixed or documented.
- `tools/reskin_audit.ps1` passes in warning-as-failure mode.
- All checklist evidence fields are filled.
- The Core Learning Gate records every reusable behavior moved to core or left
  game-owned with rationale.
- The Platform Input Matrix is filled for any control/camera/input changes.

## Phase 5.5: Export Audit

Use this phase after core/schema/export edits and before any package handoff.

1. Check selected export resources.
2. Verify new core helper scripts are included.
3. Verify removed game-local schemas are not selected.
4. Scan generated PCK/package output for stale schema names, debug/source
   folders, old JS globals, and authoring-only markers.

Stop gate:
- No stale selected resources.
- No removed schema names in package output.
- No old platform bridge globals in package output.

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
