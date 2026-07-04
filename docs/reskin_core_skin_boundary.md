# MUST READ BEFORE RESKIN: Core And Skin Boundary

Every agent must read this document before reskinning any Shinokute game.

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

## Required Reskin Flow

1. Read this boundary document.
2. Read the game's local reskin checklist and publish checklist.
3. Identify core feature behavior already owned by `ShinokuteGameCore`.
4. Keep or move reusable behavior to core only after adding core tests.
5. Keep all game skin and function skin inside the game repo.
6. Create or update the game SSOT resource for coordinates, colors, fonts, asset paths, VFX parameters, and layout bounds.
7. Add contract tests proving the game reads skin values from SSOT, not scattered constants.
8. Run Godot import, contract tests, packaging tests, and a smoke launch before claiming the game works.

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
