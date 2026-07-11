# Candy Sky Islands Reskin Design

## Goal

Reskin `Starter Kit 3D Platformer` into **Candy Sky Islands** while preserving the existing 3D platformer behavior: movement, jump/double jump, camera controls, coin pickup, falling platforms, and scene reload.

## Approved Direction

- Theme: Candy Sky Islands.
- Perspective: true 3D platformer, using the current camera and `Node3D` scene structure.
- Style: bright casual toy-like sky islands with candy/material accents.
- Palette:
  - Sky blue: `#79C7F2`
  - Cream: `#FFF2C7`
  - Coral: `#FF6F61`
  - Mint: `#7BE0AD`
  - Dark text: `#273043`
- Mood: mascot player, star-candy collectible, cake/cloud island platforms, cheerful readable mobile style.
- Image generation: approved by owner for the Checkpoint 2 player root asset concept.

## Scope

First pass is game skin only:

- Create game-local SSOT for theme palette, HUD tokens, model/material paths, skybox, and VFX/audio token names.
- Keep all skin data inside the `quantum_starter` repo.
- Add validation checks for manifest coverage and SSOT coverage.
- Apply visual reskin only after SSOT exists and Checkpoint 2 Root Asset is approved.

Out of scope:

- No Shinokute core integration.
- No leaderboard/profile/ads/publish work.
- No movement, physics, camera, collision, scoring, or level layout behavior changes.
- No additional paid AI generation beyond the approved Checkpoint 2 player root asset concept without explicit owner approval.

## Reskin Surface

Existing assets and scenes:

- Main scene: `res://scenes/main.tscn`
- Environment: `res://scenes/main-environment.tres`
- Player: `res://objects/player.tscn`, `res://objects/character.tscn`, `res://models/character.glb`
- Collectible: `res://objects/coin.tscn`, `res://models/coin.glb`, `res://sprites/coin.png`
- Platforms: `res://objects/platform*.tscn`, `res://models/platform*.glb`
- Props: `res://models/grass*.glb`, `res://models/cloud.glb`, `res://models/flag.glb`, `res://models/brick.glb`
- HUD: `HUD/Icon`, `HUD/Coins`, `fonts/lilita_one_regular.ttf`
- Audio: `sounds/jump.ogg`, `sounds/land.ogg`, `sounds/coin.ogg`, `sounds/walking.ogg`

## SSOT Design

Create a focused Godot resource:

- `Resources/QuantumThemeConfig.gd`
- `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

Fields:

- `theme_name`
- `display_name`
- `palette_sky`
- `palette_surface`
- `palette_primary`
- `palette_accent`
- `palette_text`
- `hud_coin_icon_path`
- `hud_font_path`
- `hud_text_owner_rect`
- `hud_text_padding`
- `skybox_path`
- `player_model_path`
- `coin_model_path`
- `platform_material_color`
- `coin_material_color`
- `trail_particle_color`
- `audio_event_paths`

Runtime application should read the theme resource and apply values in one place. Scene/script constants may remain only for unchanged behavior, not for changed skin values.

## Asset Manifest

`docs/asset_manifest.md` is the source of truth for every changed or generated asset. Before production use, each changed asset row must include:

- role,
- asset key,
- path,
- source,
- status,
- owner rect,
- padding,
- in-game size,
- proof screenshot path.

## Root Asset Checkpoint

Approved root asset: player mascot.

Approved direction: **Marshmallow Runner**.

Reason:

- It is the strongest brand signal for screenshots and later icon/splash work.
- Marshmallow Runner keeps proportions closest to the current character, reducing animation and readability risk.
- The first generated output is a concept/reference PNG, not a rigged GLB replacement.

Checkpoint 2 process:

1. Generate one Marshmallow Runner player concept asset.
2. Inspect it visually.
3. Confirm it matches palette, true 3D style, material, and readability.
4. Ask owner to approve it.
5. Owner approved the generated Marshmallow Runner concept on 2026-07-07.
6. Only then apply matching player materials or plan a separate 3D model replacement path.

## Validation

Use `docs/validation_runbook.md`.

Required gates before completion:

- Gate 0 required files pass.
- Gate 1 owner approval and fallback scan pass.
- Gate 2 asset manifest coverage pass.
- Gate 3 SSOT coverage pass.
- Gate 4 Godot import pass with appropriate engine version.
- Gate 5 gameplay smoke pass.
- Gate 6 screenshot evidence captured.
- Gate 7 completion report includes changed files, gates run, screenshots, warnings, and gaps.

## Risks

- Local available Godot binary is 4.3 while README names Godot 4.6. Import validation may require installing or locating a 4.6 console binary.
- Full 3D model replacement can break animation names. First implementation should prefer material/path-safe reskin unless owner approves deeper model swaps.
- HUD text currently uses scene offsets. Move owner rect into SSOT before changing HUD layout.

## Approval Needed Before Implementation

Review this spec. If accepted, next step is an implementation plan that creates the SSOT, updates validation checks, then applies the smallest safe Candy Sky Islands visual pass.
