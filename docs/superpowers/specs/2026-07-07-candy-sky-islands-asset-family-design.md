# Candy Sky Islands Asset Family Design

## Goal

Design the remaining Candy Sky Islands asset family after the approved Marshmallow Runner Root Asset, without treating the player pass as full reskin completion.

## Approved Approach

Owner approved approach A on 2026-07-07: safe material plus concept sheet.

This phase creates one coherent concept sheet for the asset family, gets owner approval, then applies a safe in-game pass through SSOT tokens, material overrides, HUD assets, and background assets. It does not replace core GLB models, colliders, animations, physics, controls, scoring, or level layout.

## Current Gate

Asset Family / Block Kit design.

Completed before this phase:

- Candy Sky Islands theme and palette approved.
- Marshmallow Runner player Root Asset approved.
- Player material pass applied to the existing rig/model.
- Theme SSOT and theme applier exist.
- Initial screenshots exist for desktop gameplay, player, coin pickup, and HUD.

Pending in this phase:

- Collectible coin/star-candy design.
- Platform/cake/cloud island kit design.
- HUD icon/frame design.
- Props/background/skybox design.
- Obstacle/goal treatment if included in visible scene scope.

## Concept Sheet Requirements

Create one concept sheet under `res://assets/themes/candy_sky_islands/` after owner approves generation.

The sheet must show:

- Marshmallow Runner as style anchor.
- Star-candy collectible with coral body, mint rim or sparkle, and high readability at small size.
- Cake/cloud island platform kit using cream surfaces, soft candy edging, and readable top faces.
- Compact HUD treatment with star-candy icon and optional score frame, sized for the existing top-left HUD.
- Soft cloud props and sky backdrop with sky blue base and candy accent clouds.
- Optional candy wafer obstacle and candy pennant goal treatment if the current scene exposes them.

The sheet is a reference and approval artifact. It is not automatically production art until accepted and mapped into the manifest.

## Asset Application Rules

First implementation pass must be low-risk:

- Keep existing GLB models and collisions.
- Keep player, coin, platform, camera, movement, scoring, falling platform, and scene reload behavior unchanged.
- Add or extend SSOT fields for asset family tokens.
- Apply material colors through `scripts/theme_applier.gd`.
- Replace HUD icon/frame only after approved PNG asset exists and is listed in `docs/asset_manifest.md`.
- Replace skybox/background only after approved asset exists and is listed in `docs/asset_manifest.md`.
- Do not add branding splash/icon/logo work unless owner approves branding scope.

## Asset Group Details

### Collectible

Target: turn current coin role into a star-candy collectible feel while keeping current pickup scene and behavior.

Safe pass:

- Use coral primary material.
- Use mint rim/sparkle accent.
- Keep particle texture unless a new pickup particle is approved.
- Ensure screenshot proves pickup remains readable and HUD increments.

### Platform Kit

Target: make platforms read as cake/cloud islands while keeping existing platform scenes and collisions.

Safe pass:

- Use cream top material.
- Use coral or mint edge accents only where current material surfaces support it safely.
- Keep falling platform behavior unchanged.
- Avoid texture/model swaps until separate approval.

### HUD

Target: make score HUD match star-candy collectible while staying compact and readable.

Safe pass:

- Keep existing top-left position and owner rect.
- Add approved icon asset only after concept approval.
- Optional score frame can be added only if it does not overlap gameplay and has owner rect/padding recorded.
- Keep font unless a replacement is approved.

### Props And Background

Target: make world read as cheerful candy sky islands in screenshots.

Safe pass:

- Recolor cloud props toward soft white/cream with sky bounce.
- Use skybox/background replacement only after approval.
- Keep camera, lighting direction, and environment behavior stable.

### Obstacle And Goal

Target: align visible brick and flag elements if they are part of smoke screenshots.

Safe pass:

- Recolor brick toward candy wafer/block material if visible and stable.
- Recolor flag toward candy pennant material if visible and stable.
- Do not alter break, collision, or goal behavior.

## Manifest And State Rules

Every accepted asset group needs:

- Row in `docs/asset_manifest.md`.
- Source and status.
- Owner approval note.
- In-game size where measurable.
- Proof screenshot after placement.

`docs/reskin_state.md` must be updated after each gate so context reset resumes from the correct phase.

## Validation

After implementation, run:

- All `tests/test_*.gd`.
- Godot import using the available approved binary.
- Visible smoke screenshot run.
- `git diff --check`.

Screenshots must include:

- Desktop gameplay showing platform/background treatment.
- Coin pickup showing collectible and HUD increment.
- HUD close-up showing icon/frame/text fit.
- Optional obstacle/goal proof if touched.

## Out Of Scope

- Full 3D model replacement.
- New rigged character.
- Publish/export/mobile validation.
- Shinokute core integration.
- Branding splash/icon/logo unless owner approves that scope.

## Approval

This design was approved in chat on 2026-07-07 after the owner selected approach A and confirmed the proposed Asset Family design.
