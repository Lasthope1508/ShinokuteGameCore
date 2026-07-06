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
4. Use an existing asset through the game SSOT when a matching blank box or shell exists.
5. Put text/input controls inside that asset-owned box and make the native control background transparent when the asset owns the frame.
6. Add a contract test proving the chosen control uses an existing asset key, owner rect, and theme token.
7. Generate a new 9Router/artist asset only when no approved existing asset matches the role, and only after adding it to the game's component queue and getting owner approval.

Forbidden:

- Do not draw a new procedural frame, `StyleBoxFlat`, default control background, or hand-coded border when an approved generated asset already exists for that role.
- Do not let username fields, settings values, leaderboard rows, or profile text float without an asset-backed owner box.
- Do not pick a random image path in code. The chosen asset must be represented by a game SSOT key.
- Do not fix missing boxes with offsets, padding guesses, or default layout containers.
- Do not add new function-skin art to `ShinokuteGameCore`; the game owns that presentation.

## Required Reskin Flow

1. Read this boundary document.
2. Read the game's local reskin checklist and publish checklist.
3. Read `docs/godot_web_publish_runbook.md` before any owner test link or official web publish.
4. Identify core feature behavior already owned by `ShinokuteGameCore`.
5. Keep or move reusable behavior to core only after adding core tests.
6. Keep all game skin and function skin inside the game repo.
7. Create or update the game SSOT resource for coordinates, colors, fonts, asset paths, VFX parameters, and layout bounds.
8. Add contract tests proving the game reads skin values from SSOT, not scattered constants.
9. Run Godot import, contract tests, packaging tests, and a smoke launch before claiming the game works.

## Examples

Username:
- Core owns username validation, first-run policy, profile readiness, and save keys.
- Function skin owns the cyber/fruit/brick popup art, button style, copy text, and animation.

Leaderboard:
- Core owns Firestore payloads, query construction, sorting contract, and result normalization.
- Function skin owns leaderboard tabs, cards, avatars, icons, rank visuals, and screen placement.

Audio:
- Core owns canonical bus names, toggles, saved volume contract, web unlock contract, and debug state.
- Game skin owns concrete BGM/SFX assets, event names, per-theme pitch/volume offsets, and mix taste.

Theme:
- Core may own a theme registry shape and generic token application helper.
- Game skin owns concrete `ThemeConfig` fields for board geometry, generated assets, fake3D, and VFX.
