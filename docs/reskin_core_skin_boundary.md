# MUST READ BEFORE RESKIN: Core And Skin Boundary

Every agent must read this document before reskinning any Shinokute game.

For web test links or official web publishing, also read `docs/godot_web_publish_runbook.md`. Do not deploy from memory.

## Canonical Split

Core = behavior.

Core owns reusable logic, API contracts, validation, signals, data schema, storage primitives, leaderboard transport, geolocation, publish gates, audio bus contracts, and shared lifecycle patterns.

Game skin = game-specific art.

Game skin owns gameplay visuals: board, tiles, pipes, blocks, backgrounds, VFX routes, fake3D coordinates, generated UI assets, fonts, icons, color palettes, responsive layout, and brand presentation.

Function skin = game-specific presentation for a shared feature.

Function skin owns how a core feature appears in a game: username popup frame, settings rows, leaderboard table art, button icons, modal animation, copy text, and per-theme layout. Core may provide a minimal test/demo UI, but production games must inject their own function skin through game resources or wrappers.

## Canonical Cross-Platform Standard

This is the only approved standard for production reskins.

Reusable function behavior belongs in `ShinokuteGameCore`. Games may configure, wrap, and connect core behavior, but must not fork profile, settings, leaderboard, input, camera, audio, progression schema, overlay grouping, routing, storage, publish gates, or other reusable function logic inside game scenes.

Every reskin must create or update a game-owned SSOT before UI or asset integration:

- UI skin/layout SSOT: owner rects, padding, safe areas, font tokens, text limits, alignments, hitboxes, responsive rules, and platform viewport rules.
- Asset checklist/manifest: every gameplay, function UI, HUD, branding, audio, and 3D role maps from old/default asset to approved new asset, source, status, in-game size, proof, and platform usage.
- Core wiring map: each enabled feature names its core owner, game adapter/wrapper, game function skin, tests, and screenshot evidence.
- Platform map: iOS, Android, HTML5, and Roblox must consume the same canonical asset keys and art/audio/source assets unless the owner approves a documented exception.

Canonical assets are shared across platforms. Do not create separate iOS, Android, HTML5, or Roblox asset forks for the same role. Platform-specific code may adapt input, export, shell, safe area, renderer, storage bridge, or API glue in that platform layer only; it must still reference the same canonical asset keys and SSOT roles.

If a platform needs a different file format or size bucket, record it as a derivative of the same canonical asset key, with source asset, transform command, size, and platform target. Do not treat the derivative as a new design branch.

## Core Learning Gate

At the end of every reskin, record what the game taught the core.

Required:

1. List each new behavior or schema touched by the game.
2. Classify it as core-owned, game-owned, function-skin-owned, or
   platform-owned.
3. Move reusable behavior/schema into `addons/shinokute_game_core` with core
   tests.
4. Leave only skin, config, assets, adapters, and platform shims in the game.
5. Run `ShinokuteReskinBoundaryAudit` or the matching contract before pushing.

`ShinokuteReskinBoundaryAudit` is the reusable helper for catching accidental
game leaks inside core. It scans for hardcoded game names, game asset paths,
stale JS globals, duplicate game-local schema classes, and similar markers.

Forbidden:

- Do not keep reusable input, camera, progression, overlay, settings, audio,
  profile, or leaderboard logic only in the latest game.
- Do not copy a game-local schema into the next game when a core schema exists.
- Do not push a core module that contains a game node path, skin asset path,
  DOM id, JS global, Firebase collection, save prefix, or theme folder.

## Definition Resolver Boundary

Core owns id-based definition resolution, duplicate-id validation, missing-reference reporting, and weighted id selection only.

Games own definition meaning, domain keys, stat application, enemy behavior, projectile behavior, inventory semantics, and upgrade effects.

Function skin owns picker panels, option cards, labels, icons, animation, and text layout for any resolved options.

Use this split when moving SSOT table logic from a reskin into
`ShinokuteGameCore`:

| Layer | Owns | Must not own |
|---|---|---|
| Core | Generic dictionary definitions, pool refs, id keys, weight keys, merge order, duplicate-id errors, missing-ref reports, deterministic weighted selection | Upgrade names, enemy ids, projectile ids, combat formulas, stat keys, UI text, art paths |
| Game | Canonical domain tables, level-local weighted refs, target keys, operations, values, caps, unlock rules, effect application, gameplay tests | Shared merge/pick/validation implementation already available in core |
| UI/function skin | Option labels after game supplies them, buttons, picker overlay, card art, layout metrics, text fit, input/focus behavior | Gameplay stat mutation, weighted selection rules, canonical table storage |

If a resolver needs to know what `enemy`, `projectile`, `inventory`,
`character_update`, or any game-specific id means, it is no longer core code.

## Platform Input Matrix

For input, camera, movement, Shift Lock, zoom, mobile touch, or platform
controls, record the expected behavior for PC keyboard/mouse, gamepad, mobile
touch, iOS Web, Android Web/native, HTML5 desktop, and Roblox.

Platform adapters may translate gestures or browser APIs, but the semantic
move/look/jump/zoom path must converge into one core route where possible. Do
not create a second hidden camera or movement path for one platform.

## Export Audit

After core/schema/export edits, scan selected export resources and generated
packages for stale game-local schema names, debug/source folders, authoring-only
assets, old JS globals, and missing core helpers.

Do not hand off a web test link or publish build when export resources still
refer to removed game-local schemas or old core paths.

## Core Wiring Is Not UI Completion

Core wiring is logic/service wiring only; it is not production feature completion.

Every enabled shared core feature must have game-owned function-skin UI before the feature can be marked done.

This applies to username, leaderboard, result, settings, menus, ads, profile, and publish prompts.

A shared feature is not done until game-owned UI exists, is theme/SSOT backed, and has contract tests plus screenshot validation.

Core demo UI may be used only as scaffold/prototype. It is not production skin unless the owner explicitly approves it and the game reskins it through game-owned SSOT, assets, layout metrics, text fit rules, and screenshot evidence.

## Non-Negotiable Rules

- Do not move game skin into `ShinokuteGameCore`.
- Do not move function skin into `ShinokuteGameCore`.
- Do not copy core behavior into game scenes.
- Do not fork reusable core behavior per game or per platform. Move reusable behavior into core with tests, then let each game/platform configure or wrap it.
- Do not skip the Core Learning Gate after a reskin adds reusable behavior.
- Do not skip Export Audit after core/schema/export changes.
- Do not start UI/function skin work before the game has a UI skin/layout SSOT and asset checklist mapping old/default roles to new canonical roles.
- Do not start final art or final screen assembly from a placeholder/basic
  source before the owner approves a production visual direction and the game
  records a polished Block Kit plan.
- Do not create separate platform art branches for iOS, Android, HTML5, or Roblox. Use the same canonical asset keys and record platform derivatives only as generated variants of those keys.
- Do not put platform-specific code in the shared game logic layer. Keep it in the platform layer/branch/shim and prove it still consumes canonical SSOT assets.
- Do not mark shared features complete after core logic/service wiring only; each enabled feature needs game-owned UI/function skin.
- Do not hardcode game id, Firebase project, collection, score label, sort direction, username policy, or geolocation fallback inside feature code.
- Do not invent fallback assets or fallback config. No fallback unless owner explicitly approves it for that exact project.
- Do not reskin by manually scattering constants through scenes. Add SSOT resources, tests, and docs first.
- Do not rename legacy folders during a reskin unless a separate path migration plan updates imports, export presets, debug tools, docs, and hosting scripts.

## Function Skin Existing Asset Gate

Before creating a new visual frame, field shell, capsule, badge, or button shell for a shared feature, inventory the existing approved game assets first.

Required order for every production reskin:

1. Read the game's runtime asset manifest and generated UI/component manifest.
2. Read the game's theme/skin SSOT for existing asset keys, geometry, owner rects, padding, and scale policy.
3. Inspect the target scene for an existing semantic owner box before adding nodes.
4. Use an existing asset through the game SSOT only when the role, ratio, crop, padding, and owner rect match the target control.
5. Put text/input controls inside that asset-owned box and make the native control background transparent when the asset owns the frame.
6. Add a contract test proving the chosen control uses an existing asset key, owner rect, and theme token.
7. Generate a new 9Router/artist asset only when no approved existing asset matches the role, and only after adding it to the game's component queue and getting owner approval.

Forbidden:

- Do not draw a new procedural frame, `StyleBoxFlat`, default control background, or hand-coded border when an approved generated role-matching asset already exists.
- Do not let username fields, settings values, leaderboard rows, or profile text float without an asset-backed owner box.
- Do not pick a random image path in code. The chosen asset must be represented by a game SSOT key.
- Do not reuse multi-panel tray art as a field shell unless the game creates a role-specific crop asset, geometry key, owner rect, and screenshot audit first.
- Do not fix missing boxes with offsets, padding guesses, or default layout containers.
- Do not add new function-skin art to `ShinokuteGameCore`; the game owns that presentation.

## Text Fit And Game Context Gate

Before a screen, popup, HUD row, button, input, leaderboard item, or settings
control can be called reskinned, text and text-owner regions must fit the game
screen, art style, and control role.

In every reskin, text and text-owner regions must fit the game screen, art style, and control role before the agent moves to another task.

Required:

1. Identify the owner visual region for each label, value, input, or button
   caption before placing text.
2. Use the game SSOT for owner rect, padding, max width, max lines, alignment,
   font token, and scale policy.
3. Verify desktop and mobile viewports.
4. Capture screenshots for changed screens.
5. Ask whether the result still reads as an actual game screen, not a generic
   app form pasted over game art.

Forbidden:

- Do not let text overflow outside its owner region.
- Do not let text overlap art, controls, safe area padding, scores, input
  fields, or neighboring UI.
- Do not use hero-scale text inside compact controls.
- Do not fix overflow with random offsets or one-off font sizes.
- Do not forget gameplay context: every menu, popup, result, and settings
  screen must still feel like part of the current game theme.

## Required Reskin Flow

1. Read this boundary document.
2. Read `docs/reskin_runbook.md`.
3. Read the game's local reskin checklist and publish checklist.
4. If the game has no local reskin checklist, copy `docs/reskin_checklist_template.md` into the game repo before edits.
5. Read `docs/godot_web_publish_runbook.md` before any owner test link or official web publish.
6. Identify core feature behavior already owned by `ShinokuteGameCore`.
7. Create or update the UI skin/layout SSOT, asset checklist/manifest, core wiring map, and platform map before UI or asset edits.
8. If the source visuals are only placeholders/basic shapes, record the
   owner-approved visual direction and build a polished Block Kit before final
   art or screen assembly.
9. Keep or move reusable behavior to core only after adding core tests.
10. Keep all game skin and function skin inside the game repo.
11. Keep platform-specific code in the platform layer/branch/shim only, and keep platform asset usage pointed at canonical SSOT asset keys.
12. Create or update the game SSOT resource for coordinates, colors, fonts, asset paths, VFX parameters, text owner regions, and layout bounds.
13. For every enabled shared core feature, create or update game-owned UI/function skin before marking that feature done.
14. Add contract tests proving the game reads skin values from SSOT, not scattered constants.
15. Run Godot import, contract tests, screenshot validation, packaging tests, and a smoke launch before claiming the game works.

## Examples

Username:
- Core owns username validation, first-run policy, profile readiness, and save keys.
- Function skin owns the cyber/fruit/brick popup art, button style, copy text, and animation.

Leaderboard:
- Core owns Firestore payloads, query construction, sorting contract, and result normalization.
- Core owns local best score persistence, pending score persistence, submit retry handoff after username commit, and score comparison by configured sort direction.
- Games must submit canonical score dictionaries even when username is not ready; core must persist local best before remote leaderboard transport.
- Core must not auto-create username fallback during score submit. If username is missing, keep pending score and emit/request profile readiness.
- Function skin owns leaderboard tabs, cards, avatars, icons, rank visuals, and screen placement.

Audio:
- Core owns canonical settings keys, toggles, persistence, signals, audio gate contracts, web unlock contract, and debug state.
- Game skin owns concrete BGM/SFX assets, event names, per-theme pitch/volume offsets, mix taste, and generated/imported audio files.
- For BGM made from multiple owner-provided files, trim leading/trailing silence on each source before concat, then encode a mobile-sized runtime asset such as OGG Vorbis. Record source files, trim filter, output duration, size, and route in the game manifest.
- Function skin owns settings rows, toggles, labels, and panel art. Core settings logic alone is not a completed settings feature.

Shift lock / camera:
- Core may own the saved setting key and signal: `shift_lock_enabled`.
- Each game owns camera math, default value in `GameCoreConfig.settings_defaults`, and any mobile/desktop UI used to toggle it.
- Do not hardcode shift-lock defaults inside a camera script. Read from the core settings bridge and keep the game-specific view behavior in the game repo.

Theme:
- Core may own a theme registry shape and generic token application helper.
- Game skin owns concrete `ThemeConfig` fields for board geometry, generated assets, fake3D, and VFX.
