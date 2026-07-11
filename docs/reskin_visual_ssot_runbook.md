# Reskin Visual SSOT Runbook

This file is mandatory reading before any reskin, theme, visual asset, UI skin, VFX skin, material, model, or screenshot-proof work.

## Core Rule

Every visible thing on the game screen must be managed by a canonical visual role before it is changed.

Production scenes and gameplay scripts must not become the source of truth for skin asset paths. They may expose stable targets, but the canonical decision for what asset belongs to a skin must live in SSOT resources and docs.

Valid source of truth layers:

1. `docs/default_skin_size_ssot.md`
2. `docs/asset_manifest.md`
3. `Resources/Data/Themes/<theme_name>/theme_config.tres`
4. theme/runtime applier scripts that consume role keys
5. contract tests that prove no active production reference escaped the SSOT

## Required Mental Model

Use three separate concepts:

| Concept | Purpose | Example |
|---|---|---|
| Visual role | Canonical game meaning | `player.model`, `hud.score.frame`, `env.skybox` |
| Runtime target | Node/property that consumes the role | `objects/player.tscn/Character`, `HUD/CandyScoreFrame.texture` |
| Theme asset | Current skin value | `res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb` |

A scene may know that it has a player visual slot. It must not become the owner of the current theme asset decision.

## Role Key Standard

Use lowercase dotted keys. Name roles by game meaning, not by current asset name.

Good:

```text
player.model
player.shadow
player.trail.dust
hud.score.frame
hud.score.text
collectible.coin.model
collectible.coin.particle
platform.small
platform.medium
platform.falling
obstacle.brick
goal.flag
prop.cloud
env.skybox
audio.jump
```

Bad:

```text
chr077_skeleton_mage
shinokute_player
red_star_png
new_cloud_thing
tmp_mesh_1
```

Asset names can change. Role keys should survive across skins.

## Mandatory Reskin Flow

Before changing any visual asset:

1. Read this file.
2. Read `AGENTS.md`.
3. Read `docs/reskin_state.md`.
4. Read `docs/reskin_checklist.md`.
5. Read `docs/default_skin_size_ssot.md`.
6. Read `docs/asset_manifest.md`.
7. Inventory the current on-screen node or resource that will change.
8. Assign or confirm the canonical role key.
9. Record default size, runtime rect, collider envelope, or scene AABB in `default_skin_size_ssot.md`.
10. For player characters, define the visual scale envelope and scale policy before placing the model in the scene.
11. Record source, license, status, proof path, and notes in `asset_manifest.md`.
12. Put the current theme asset path in `theme_config.tres` or an equivalent theme SSOT resource.
13. Wire scene/script through the role/theme applier when practical.
14. Add or update a contract test that fails if the old hardcoded path returns.
15. Validate in Godot.

Do not integrate a new asset first and document later.

## Canonical Ownership

Allowed places for skin asset paths:

- `Resources/Data/Themes/<theme_name>/theme_config.tres`
- theme config scripts/defaults where fallback is explicitly documented
- `docs/default_skin_size_ssot.md`
- `docs/asset_manifest.md`
- `docs/reskin_state.md`
- `docs/reskin_checklist.md`
- tests that assert canonical behavior
- source evidence folders and historical tools, when clearly not production

Forbidden places for theme-specific asset decisions:

- production gameplay scripts
- ad hoc scene edits with no role entry
- duplicated paths in many scenes
- hidden fallback strings
- generated helper scripts that are then treated as runtime truth
- docs that claim a replacement without SSOT/test coverage

Exception: a `.tscn` may temporarily reference a replacement during migration only if the role is already recorded and a follow-up task exists to route it through a theme role/applier. Mark this explicitly as `migration_pending`.

## Node Binding Rule

Every visible production node should have one of these:

- direct role coverage in `theme_config.tres`
- a parent scene role that owns the visual subtree
- an allowlist reason in a contract test
- unused/source-evidence status in the manifest

Visual node types to check:

```text
MeshInstance3D
Sprite3D
TextureRect
Sprite2D
Label / LabelSettings when text style is themed
WorldEnvironment
Decal
GPUParticles3D / CPUParticles3D
AudioStreamPlayer when reskin includes sound
AnimationPlayer tracks that target visual-only nodes
```

## Player Scale Envelope

Player model replacement has an extra gate. Do not drop a raw GLB into the player scene and accept whatever size imports.

Canonical player constraints:

```text
player.collider_capsule.radius = 0.3
player.collider_capsule.height = 1.0
player.collider_capsule.center_y = 0.55
player.visual_target_height = 1.30 u
player.visual_allowed_height = 1.10..1.35 u
```

Required policy:

- measure the default player model AABB first
- measure the replacement raw model AABB before scaling
- choose a scale factor that puts visual height inside `1.10..1.35 u`
- apply scale through a stable parent slot, not the animated visual child
- keep animation scale tracks on the visual child so they do not overwrite the base scale
- record raw size, scale factor, target height, and resulting production height in `default_skin_size_ssot.md`
- add or update `test_player_visual_scale_contract.gd`

For the current CHR077 integration, the raw model was too large for the gameplay envelope. It must stay under `CHR077SkeletonMageSlot` with scale `0.5`; `AnimationPlayer` tracks target `CHR077SkeletonMageSlot` for position bob and `CHR077SkeletonMageSlot/CHR077SkeletonMageVisual` for scale animation.

If a future player character needs a different height, the owner must approve the new target before scene integration.

## Theme Applier Boundary

Theme appliers may know how to apply a role to a property.

They should not invent role meanings.

Good:

```gdscript
apply_texture("hud.score.frame", candy_score_frame)
apply_scene("player.model", character_visual_slot)
apply_color("palette.primary", collectible_material)
```

Bad:

```gdscript
candy_score_frame.texture = load("res://assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png")
if theme_name == "candy":
	player_model = load("res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb")
```

If a hardcoded theme path is unavoidable during migration, add a comment with the role key and update the contract test to catch it later.

## No Hidden Fallbacks

Fallbacks must be explicit and documented.

Forbidden:

- silently falling back to old HUD coin
- silently falling back to old skybox
- hiding missing mesh/material warnings by skipping visuals
- using dummy primitive replacements to avoid a failed load
- keeping rejected assets active because they still load

Required:

- if a replacement is missing, fail validation
- if an asset is experimental, keep it out of production scenes
- if an asset is source evidence, mark it as source evidence
- if a role is deferred, mark it deferred in SSOT

## Production Eligibility

An asset can be used in a production scene only when all are true:

- role key exists
- source and license are recorded
- commercial-use status is known
- default/runtime size impact is recorded
- replacement path is canonical
- old production path is removed or explicitly legacy-only
- Godot can import/load it
- contract test covers the role
- proof screenshot or runtime proof exists when visual validation is part of the gate

Experimental, rejected, draft, diagnostic, prompt-lab, and candidate assets must not be wired to production nodes.

## Migration Plan For Existing Hardcoded Assets

When an existing game has scattered paths:

1. Run an inventory of active scenes and scripts.
2. Group every visible path by role key.
3. Move role data into `theme_config.tres`.
4. Add role notes to `default_skin_size_ssot.md`.
5. Add source/license/status to `asset_manifest.md`.
6. Update scene/script consumers one role at a time.
7. Add a contract test that scans production files for forbidden old paths.
8. Keep historical tools and source evidence allowed only by explicit path allowlist.

Do not do a broad rewrite without tests. Migrate role by role.

## Contract Tests Required

Every reskin gate should include tests that prove:

- active production scenes load
- required role keys exist
- theme asset paths load
- old production asset paths are absent from active scenes/scripts
- `res://assets/themes/<theme>/...` paths are not scattered outside allowed SSOT files
- every production visual role has manifest coverage
- every replacement with a default 3D source preserves 3D parity unless owner approved downgrade
- every UI replacement uses runtime rect/owner rect, not natural PNG size
- every rejected/experimental asset stays out of production scenes
- player visual height stays inside the canonical scale envelope

Recommended test names:

```text
test_visual_role_ssot_contract.gd
test_theme_asset_paths_contract.gd
test_no_hardcoded_skin_paths_contract.gd
test_production_visual_manifest_contract.gd
```

## Audit Commands

Use `rg` first:

```powershell
rg -n "res://assets/themes/|res://models/|res://sprites/|res://sounds/" scenes objects scripts Resources tests docs
```

Find active theme-specific paths outside SSOT:

```powershell
rg -n "res://assets/themes/candy_sky_islands/" scenes objects scripts Resources tests docs
```

Find rejected/candidate assets in active production files:

```powershell
rg -n "candidate|rejected|prompt_lab|debug|experiment|shinokute_human|character_chr077" scenes objects scripts Resources
```

Godot validation baseline:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tools\audit_skin_size_ssot.gd"
```

## Done Criteria

Do not say a reskin role is done unless:

- role key is canonical
- SSOT files are updated
- production node is routed or explicitly marked as migration-pending
- contract test passes
- Godot load/import validation passes
- old hardcoded active references are removed
- owner-visible proof exists when visual review is required

If any part is missing, report the exact missing gate instead of calling it done.
