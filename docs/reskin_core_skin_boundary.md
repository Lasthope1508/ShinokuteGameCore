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

## Non-Negotiable Rules

- Do not move game skin into `ShinokuteGameCore`.
- Do not move function skin into `ShinokuteGameCore`.
- Do not copy core behavior into game scenes.
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
7. Keep or move reusable behavior to core only after adding core tests.
8. Keep all game skin and function skin inside the game repo.
9. Create or update the game SSOT resource for coordinates, colors, fonts, asset paths, VFX parameters, text owner regions, and layout bounds.
10. Add contract tests proving the game reads skin values from SSOT, not scattered constants.
11. Run Godot import, contract tests, packaging tests, and a smoke launch before claiming the game works.

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
- Core owns canonical bus names, toggles, saved volume contract, web unlock contract, and debug state.
- Game skin owns concrete BGM/SFX assets, event names, per-theme pitch/volume offsets, and mix taste.

Theme:
- Core may own a theme registry shape and generic token application helper.
- Game skin owns concrete `ThemeConfig` fields for board geometry, generated assets, fake3D, and VFX.
