# Candy Sky Islands Deep Reskin Design

## Goal

Open a new Candy Sky Islands deep-reskin gate after the completed game-skin and branding pass. This gate prepares the project for a safer future full replacement pass by normalizing all asset roles through the theme SSOT first, then replacing visible visual assets group by group without changing gameplay behavior.

Owner selected approach A: deep-but-safe full reskin.

SFX is explicitly separated. This design stops before replacing, generating, or approving new SFX. Audio paths may be inventoried and routed through SSOT so a later SFX pass can replace them cleanly.

2026-07-08 reset amendment: before any future design option, generation prompt, Photoroom extraction, wrapper, model replacement, or UI runtime replacement, the agent must read `docs/default_skin_size_ssot.md`. The default runtime size, collider envelope, or UI rect is the baseline contract unless the owner explicitly approves a size change. Wrapper work must remain labeled as wrapper work until the legacy model/mesh/texture is fully replaced. Primitive-only dummy meshes, rough placeholder geometry, and local Blender scripts without approved reference-derived silhouette/material cues are prototype evidence only, never production replacements.

2026-07-08 3D parity amendment: if the default role is a 3D model or 3D scene with nonzero volume/depth, the production replacement must also preserve 3D volume/depth unless the owner explicitly approves a flat 2D downgrade. `Sprite3D`, billboards, screenshots, and reference PNGs can be used as references or interim visuals, but they cannot be marked as full 3D replacements for volumetric default roles. The cloud regression is the reset example: default `models/cloud.glb` is volumetric, so `cloud_large.png` as `CloudReferenceSprite` was only interim evidence. The production fix is the reference-derived volumetric GLB `assets/themes/candy_sky_islands/models/cloud_candy_volume.glb`, built from the approved Photoroom cloud reference alpha silhouette.

2026-07-08 2D character to 3D amendment: when the owner supplies a 2D player character image/sheet, read `docs/reskin_2d_character_to_3d_runbook.md` before any generation or modeling. Required order: Photoroom the full owner source, polygon-extract a clean source pose/sprite, use 9Router with that extracted character as the reference to generate a full turnaround/multiview sprite sheet, Photoroom the full generated sheet, polygon-extract every generated view/sprite, then run 3D reconstruction/render. Do not use raw-sheet crop, grid slicing, primitive kitbash, manual reinterpretation, or single flat extrusion as production.

## Current Gate Report

Current gate:

- Deep Reskin Design.
- Previous game-skin scope and branding scope are closed, validated, and owner approved.

Completed assets:

- Theme direction: Candy Sky Islands.
- Root asset direction: Marshmallow Runner.
- Runtime theme SSOT: `res://Resources/QuantumThemeConfig.gd`.
- Theme resource: `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres`.
- Runtime theme applier: `res://scripts/theme_applier.gd`.
- Approved extracted asset family PNGs under `res://assets/themes/candy_sky_islands/`.
- App branding: `res://icon.png`, `res://splash-screen.png`, and `res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`.

Pending assets for this gate:

- Real visual replacements or stronger wrappers for player, collectible, platform kit, obstacle, goal, props, VFX, skybox, material texture usage, and hardcoded scene references.
- Audio/SFX replacement is not part of this gate.

Next required gate:

- Written implementation plan after owner reviews and approves this spec.

## Scope

In scope:

- Inventory every old visual asset still present in the game.
- Normalize old, reference, and future replacement asset paths into SSOT fields.
- Add contracts that prove every visual role is represented in the manifest and theme config.
- Replace visible assets only through approved asset groups and theme-owned paths.
- Preserve 3D parity: volumetric default 3D roles need volumetric replacements or explicitly approved flat downgrade records.
- Keep physics, camera, movement, scoring, falling platform behavior, scene reload, and level layout unchanged.
- Record every accepted changed asset in `docs/asset_manifest.md`, `docs/reskin_checklist.md`, and `docs/reskin_state.md`.
- Run validation and screenshot evidence for each applied group.

Out of scope:

- SFX replacement, SFX generation, SFX visual approval, or claiming SFX reskin completion.
- Shinokute core integration.
- Publish/export/mobile validation.
- Gameplay changes.
- New monetization, leaderboard, profile, ads, analytics, localization, or remote config.

## Asset Source Model

Each reskin role should be represented as a small asset source record in `QuantumThemeConfig` or an equivalent typed resource. The implementation plan may choose explicit fields or a typed sub-resource, but each role must expose these meanings:

- `legacy_path`: current Kenney/source asset still used by the template.
- `reference_path`: owner-approved Candy Sky Islands PNG or concept reference.
- `replacement_path`: production replacement asset path when approved.
- `mode`: `legacy`, `material`, or `replacement`.
- `proof_path`: screenshot or contact sheet evidence after application.

The goal is to make future approach B possible without rewriting callers. In approach B, most roles should switch from `material` to `replacement` by changing SSOT paths and wrapper scenes, not by scattering direct paths through gameplay scripts.

## Complete Old Asset Inventory

These old assets must be represented in the deep-reskin manifest and SSOT plan.

### Player

- `res://models/character.glb`
- `res://objects/character.tscn`
- `res://objects/player.tscn`
- `res://sprites/blob_shadow.png`
- `res://meshes/dust.res`
- `res://models/dust.glb`

Decision for this gate:

- Keep controller, collider, animation names, camera target, and input behavior unchanged.
- Prefer wrapper scene or material/model substitution that preserves `Player` node contracts.
- Player SFX path stays inventory-only until the later SFX pass.

### Collectible And HUD

- `res://models/coin.glb`
- `res://objects/coin.tscn`
- `res://sprites/coin.png`
- `res://sprites/particle.png`
- `res://scenes/main.tscn` HUD icon `ExtResource`
- `res://scenes/main.tscn` HUD score label offsets
- `res://fonts/lilita_one_regular.ttf`

Decision for this gate:

- Replace the coin visual with star-candy only after owner approves the production role asset.
- Keep `Area3D`, pickup signal behavior, score increment, and HUD update unchanged.
- Font may remain if it fits. If changed, it must go through a separate owner-approved UI/font row.

### Platform Kit

- `res://models/platform.glb`
- `res://objects/platform.tscn`
- `res://models/platform-medium.glb`
- `res://objects/platform_medium.tscn`
- `res://models/platform-falling.glb`
- `res://objects/platform_falling.tscn`
- `res://models/platform-grass-large-round.glb`
- `res://objects/platform_grass_large_round.tscn`
- `res://models/platform-large.glb`
- `res://models/block-coin.glb`

Decision for this gate:

- Replace or wrap platform visuals as cake/cloud islands while preserving colliders, world transforms, falling behavior, and scene layout.
- `platform-large.glb` and `block-coin.glb` must be classified as unused, reused, or replacement candidates in the implementation plan.

### Obstacle And Goal

- `res://models/brick.glb`
- `res://objects/brick.tscn`
- `res://models/brick-particle.glb`
- `res://meshes/brick.res`
- `res://models/flag.glb`
- direct flag instance in `res://scenes/main.tscn`

Decision for this gate:

- Replace brick visual with candy wafer/block only after owner approval.
- Replace flag visual with candy pennant only after owner approval.
- Preserve brick collision, break behavior, particle timing, and goal placement.

### Props, Background, Materials, VFX

- `res://models/cloud.glb`
- `res://objects/cloud.tscn`
- `res://models/grass.glb`
- `res://models/grass-small.glb`
- `res://sprites/skybox.png`
- `res://scenes/main-environment.tres`
- `res://models/Textures/colormap.png`
- `res://models/colormap.tres`

Decision for this gate:

- Replace skybox through SSOT and environment routing only after approval.
- Replace cloud/grass visuals or keep material pass if replacement risks layout clarity.
- Reduce direct reliance on shared colormap only where it is safe and tested.

### Audio Inventory Only

- `res://sounds/jump.ogg`
- `res://sounds/land.ogg`
- `res://sounds/coin.ogg`
- `res://sounds/walking.ogg`
- `res://sounds/break.ogg`
- `res://sounds/fall.ogg`

Decision for this gate:

- Add missing `break` and `fall` to the audio inventory and theme audio path map.
- Route direct audio references through an approved SSOT path or event map if the implementation plan can do that without behavior changes.
- Stop before replacing or generating SFX.
- Do not mark SFX as reskinned in this gate.

## Required Workflow

Every creative visual group must follow this sequence:

0. Read `docs/default_skin_size_ssot.md` and identify the default role size, runtime rect, collider envelope, and current Candy Sky Islands state.
1. Design options for the group.
2. Owner approval of the group.
3. Asset creation, generation, or local modeling only after approval.
4. If a sheet is used, run Photoroom on the full approved sheet first through Chrome CDP port `9223`.
5. Clone/cut each object from the Photoroom alpha sheet using owner polygon or outline data.
6. Do not crop from the raw sheet first.
7. Do not use automatic grid slicing.
8. Trim and QA alpha, edge contact, dimensions, and visual readability.
9. Update manifest, checklist, state, default-size SSOT, and theme SSOT.
10. Apply in game.
11. Validate default-size contract and capture proof screenshots.
12. Reject primitive-only dummy replacements before production integration; production visuals must trace to approved real reference art, Photoroom/outline extraction, owner-approved generated art, or a model derived from those references.
13. For owner-supplied 2D player characters, use `docs/reskin_2d_character_to_3d_runbook.md`: 9Router reference-based multiview sprites must be produced and Photoroom/polygon extracted before 3D reconstruction/render.

## Phased Design

### Phase 0A: Default Skin Size SSOT

Create and maintain `docs/default_skin_size_ssot.md` before visual design work. This is the first baseline for default skin image pixel sizes, 3D AABB sizes, HUD runtime rects, collider envelope notes, replacement/wrapper state, pending roles, unused candidates, and SFX-deferred roles.

Required outcome:

- Every default visual/audio role is mapped to a Candy Sky Islands asset, wrapper state, pending state, unused candidate, or deferred SFX state.
- Every wrapper role is marked as wrapper work, not full replacement, while legacy GLBs/meshes/textures remain.
- Every future visual group updates this file before validation.
- `test_default_skin_size_ssot_contract.gd` passes.

### Phase 0B: Theme SSOT Normalization

Create or extend theme-owned role fields for all visual asset groups. The first implementation should make the current state explicit before replacing more assets.

Required outcome:

- Every old visual asset is either mapped to a role or marked unused.
- Every approved Candy Sky Islands reference PNG is mapped to a role.
- Future replacement paths exist as empty or blocked values until owner approval.
- Missing audio keys `break` and `fall` are represented for inventory and routing only.

### Phase 1: Contract And Manifest Coverage

Add or extend contract tests so reset context cannot skip old assets.

Required coverage:

- Player visual roles.
- Collectible and HUD roles.
- Platform kit roles.
- Obstacle and goal roles.
- Props, skybox, VFX, and material roles.
- Audio inventory keys, including `break` and `fall`.
- No test should claim SFX replacement is complete.

### Phase 2: Visual Replacement Groups

Replace or wrap visuals in small gates:

- Collectible star-candy.
- Platform cake/cloud kit.
- Obstacle wafer block.
- Goal candy pennant.
- Cloud, grass, dust, and particle visuals.
- Skybox and environment background.
- Optional player model wrapper only if the approved method preserves player behavior.

Each group must be shippable alone, with screenshot proof and no behavior changes.

### Phase 3: Old Reference Cleanup

After a group passes validation:

- Remove or route direct scene references to old visual assets where safe.
- Keep old assets on disk until a cleanup plan proves they are unused.
- Do not delete old assets as part of this design spec.
- Record old asset status as `replaced`, `kept`, `unused candidate`, or `audio deferred`.

### Phase 4: Stop Before SFX Replacement

The deep visual reskin stops after visual validation and audio path normalization. A later separate SFX gate may start only after owner approval.

The later SFX gate should cover:

- Sound direction options.
- Generation or sourcing approval.
- Replacement assets.
- Volume/loop QA.
- Gameplay smoke.
- Manifest and checklist evidence.

## Validation

The implementation plan must include:

- All Godot script tests: `tests/test_*.gd`.
- Default skin size SSOT contract: `test_default_skin_size_ssot_contract.gd`.
- Deep-reskin manifest contract.
- Deep-reskin SSOT contract.
- Audio inventory contract that includes `break` and `fall`.
- Godot import.
- Visible smoke screenshot capture.
- Proof screenshots for each applied visual group.
- Contact sheet or asset QA for every newly extracted or generated visual asset.
- `git diff --check`.

Do not claim mobile, web, publish, or SFX readiness from this validation.

## Risks

- Full player model replacement can break animation names or collider assumptions.
- Platform model replacement can break collision shape expectations if wrapper scale does not match.
- Skybox replacement can change readability and contrast.
- Generated sheets can drift, overlap, or create bad object boundaries; use Photoroom full-sheet first and owner polygon extraction only.
- Local primitive-only models can look fast but fail art-direction truth. Treat them as prototypes unless their silhouette/material cues are explicitly derived from approved reference assets.
- Flat 2D reference art can remove bad dummy geometry, but it is not enough for a volumetric default role. Track it as interim/reference state until a real 3D replacement exists.
- Worktree is already dirty. Implementation must stage only related files and must not revert unrelated changes.

## Approval Status

Owner approved approach A on 2026-07-07:

- Deep-but-safe visual reskin.
- Normalize sources through SSOT so future approach B is easier.
- Separate SFX and stop before SFX replacement.

Next step after owner reviews this written spec:

- Invoke the writing-plans skill and create a detailed implementation plan.
