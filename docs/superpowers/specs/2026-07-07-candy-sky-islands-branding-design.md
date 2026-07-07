# Candy Sky Islands Branding Design

## Goal

Create the optional branding set for Candy Sky Islands after the current game-skin scope has passed owner review.

Branding scope covers:

- App icon.
- Splash image.
- Logo or wordmark.

It does not reopen gameplay, controller, camera, physics, scoring, level layout, publish, ads, leaderboard, or Shinokute core work.

## Approved Direction

Owner approved branding scope and selected Option A on 2026-07-07.

Use the already approved Candy Sky Islands visual system:

- Theme: Candy Sky Islands.
- Mascot: Marshmallow Runner.
- Palette: sky blue `#79C7F2`, cream `#FFF2C7`, coral `#FF6F61`, mint `#7BE0AD`, dark text `#273043`.
- Supporting assets: star-candy collectible, cake-cloud platforms, soft candy sky islands.

## Branding Set

### App Icon

Create a square icon using the Marshmallow Runner as the main read. The icon should show the mascot head or upper body, plus a small star-candy cue.

Requirements:

- Square composition suitable for 256x256 and larger source sizes.
- Readable at small launcher size.
- No small text.
- No busy background.
- Strong silhouette, centered subject, clean candy-sky color contrast.
- Save final project-bound icon as a new themed source first, then replace or route `res://icon.png` only after owner visual approval.

### Splash Image

Create a landscape splash/title image for the existing `2560x1440` splash format.

Composition:

- Candy Sky Islands scene.
- Marshmallow Runner standing on a cake-cloud platform.
- Star-candy collectibles around the mascot.
- Bright readable sky backdrop.
- Logo area in upper or center area, without covering the mascot.

Requirements:

- No gameplay UI.
- No tutorial text.
- No store badges.
- No marketing panel layout.
- Must remain readable when scaled down.
- Must preserve enough clean space for the wordmark.

### Logo Or Wordmark

Create a compact transparent PNG wordmark reading exactly:

```text
Candy Sky Islands
```

Style:

- Rounded candy-like lettering.
- Cream, coral, and mint fills or highlights.
- Dark outline using `#273043` for readability.
- Fits splash composition and can stand alone on light sky.

Requirements:

- Exact text only.
- No subtitle.
- No extra slogan.
- Transparent background after Photoroom or approved alpha workflow.
- If AI text generation fails, replace with deterministic local text rendering using the existing font or a compatible local font, then style it to match the approved palette.

## Generation And Extraction Rules

Use `cx/gpt-5.5-image` through 9Router for generated bitmap concepts. Resolve keys in this order without printing secrets:

1. `NINEROUTER_IMAGE_KEY`
2. `NINEROUTER_KEY`
3. `ROUTER_API_KEY`

For any sheet-like output or asset that needs transparent cutout:

1. Run Photoroom on the full approved image or sheet first through Chrome CDP port `9223`.
2. Use polygon outline extraction for individual objects when objects are close or overlap.
3. Cut from the Photoroom alpha image, not from the raw image.
4. Trim alpha with safe padding.
5. QA alpha, edge contact, dimensions, and visual readability.

Do not use grid slicing. Do not crop raw sheets before Photoroom.

## Project Integration

New themed assets should live under:

```text
assets/themes/candy_sky_islands/branding/
```

Planned paths:

- `assets/themes/candy_sky_islands/branding/app_icon_source.png`
- `assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png`
- `assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`

Production paths may be updated only after owner visual approval:

- `res://icon.png`
- `res://splash-screen.png`
- `res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`

`Resources/Data/Themes/candy_sky_islands/theme_config.tres` may record branding paths if existing SSOT fields support them. If not, add branding fields through a plan before code edits.

## Manifest And Checklist

Before production use, record each accepted branding asset in:

- `docs/asset_manifest.md`
- `docs/reskin_checklist.md`
- `docs/reskin_state.md`

Each row must include source, status, approval, ratio, size, proof screenshot or preview image, and whether the asset replaced a project root file.

## Validation

After implementation, run:

- Branding asset file checks.
- Existing Godot script tests.
- Godot import.
- Visual smoke screenshot if project files are changed.
- `git diff --check`.

Validation must not claim app branding is complete until icon, splash, and logo have all been generated or created, visually approved, integrated, and checked.

## Current Approval

This design direction is approved in chat on 2026-07-07. Next step is a written implementation plan before any image generation or file replacement.
