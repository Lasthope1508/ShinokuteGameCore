# Candy Sky Islands Deep Reskin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize every remaining old Candy Sky Islands visual asset through SSOT, add contracts and manifest coverage, route existing audio paths without replacing SFX, and prepare owner-gated visual replacement groups.

**Architecture:** Add a typed role source resource so every asset role has a legacy path, reference path, replacement path, mode, and proof path. Extend `QuantumThemeConfig` and `theme_config.tres` to expose deep-reskin role sources, then add contract tests and docs so future asset replacement can switch paths through SSOT instead of scattering direct scene/script references. Keep all gameplay behavior unchanged and stop before SFX replacement.

**Tech Stack:** Godot 4 GDScript resources and tests, existing `QuantumThemeConfig`, existing `scripts/theme_applier.gd`, Markdown manifest/checklist/state docs, PowerShell validation commands, existing visible screenshot script.

**2026-07-08 reset amendment:** `docs/default_skin_size_ssot.md` is now Step 0 for this plan. Before any design option, image generation, Photoroom extraction, wrapper work, model replacement, or UI runtime replacement, read that file and preserve the default runtime size, collider envelope, or UI rect unless the owner approves a size change. Wrapper passes remain wrapper passes until the legacy model/mesh/texture is fully replaced. Primitive-only dummy meshes, rough placeholder geometry, and local Blender scripts without approved reference-derived silhouette/material cues are prototype evidence only, never production replacements.

**2026-07-08 3D parity amendment:** Before any default 3D asset replacement, check whether the default role has nonzero volume/depth in `docs/default_skin_size_ssot.md`. A volumetric default role must get a volumetric production replacement unless the owner explicitly approves a flat 2D downgrade. `Sprite3D`, billboards, screenshots, and reference PNGs are reference/interim visuals only, not full 3D replacements. `prop.cloud` is the known correction: `cloud_large.png` as `CloudReferenceSprite` was flat interim evidence and must not be treated as complete parity for default `models/cloud.glb`; the production fix is `assets/themes/candy_sky_islands/models/cloud_candy_volume.glb`, a reference-derived volumetric GLB built from the approved Photoroom alpha silhouette.

---

## File Structure

- Create `docs/default_skin_size_ssot.md`: baseline default skin size map to Candy Sky Islands roles, including pixel sizes, 3D AABB sizes, HUD runtime rects, wrapper/pending/deferred state, and future gate blocker.
- Create `tools/audit_skin_size_ssot.gd`: Godot measurement tool for image pixel sizes and 3D scene/model AABB sizes.
- Create `tests/test_default_skin_size_ssot_contract.gd`: reset-proof contract for default size SSOT coverage and guard wiring.
- Create `Resources/QuantumAssetRole.gd`: typed resource for `legacy_path`, `reference_path`, `replacement_path`, `mode`, `proof_path`, and role validation.
- Modify `Resources/QuantumThemeConfig.gd`: add deep visual role exports and audio inventory keys `break` and `fall`.
- Modify `Resources/Data/Themes/candy_sky_islands/theme_config.tres`: populate deep visual role source records and audio paths without replacing SFX.
- Create `tests/test_deep_reskin_theme_contract.gd`: verifies required deep-reskin role sources, mode values, and audio inventory.
- Create `tests/test_deep_reskin_manifest_contract.gd`: verifies manifest/checklist/state mention old visual assets, deep-reskin gate, and deferred SFX status.
- Create `tests/test_deep_reskin_audio_contract.gd`: verifies `jump`, `land`, `coin`, `walking`, `break`, and `fall` audio paths are in SSOT and exist, without requiring replacement.
- Modify `scripts/audio.gd`: add optional event map configuration and `play_event(event_name)` while preserving `play(sound_path)`.
- Modify `scripts/player.gd`, `objects/coin.gd`, `objects/brick.gd`, and `objects/platform_falling.gd`: route current audio calls through `Audio.play_event(...)` only after audio contract fails.
- Modify `scripts/main.gd`: configure the audio event map from `theme_config.audio_event_paths` during `_ready()`.
- Modify `docs/asset_manifest.md`: add missing deep-reskin rows for all old visual roles, `break`, `fall`, unused candidates, and deferred SFX status.
- Modify `docs/reskin_checklist.md`: add Checkpoint 5 for Deep Reskin and record stop-before-SFX rule.
- Modify `docs/reskin_state.md`: set current gate to Deep Reskin implementation planning and record pending visual groups.

## Task 0: Default Skin Size SSOT Baseline

**Files:**
- Create: `docs/default_skin_size_ssot.md`
- Create: `tools/audit_skin_size_ssot.gd`
- Create: `tests/test_default_skin_size_ssot_contract.gd`
- Modify: `AGENTS.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/asset_manifest.md`
- Modify: `docs/reskin_state.md`
- Modify: this plan and the deep-reskin design spec

- [x] **Step 1: Measure default and Candy role sizes**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tools\audit_skin_size_ssot.gd"
```

Expected: output maps default role path, default size, Candy role path, and Candy size/state for image, 3D, mixed, and audio roles.

- [x] **Step 2: Record baseline table**

Write `docs/default_skin_size_ssot.md` with rows for every default visual/audio role. Mark wrappers as `wrapper_done, legacy_model_kept` or equivalent. Mark `player.shadow`, `material.colormap`, and deeper legacy GLB replacement as pending. Mark SFX as deferred.

For default 3D roles, record whether the default has nonzero depth/volume. If a replacement uses `Sprite3D`, billboard, screenshot, or reference PNG for a role that was originally volumetric, mark it as interim/reference state with `3d_parity_pending`, not full replacement.

- [x] **Step 3: Guard reset context**

Add `docs/default_skin_size_ssot.md` to `AGENTS.md` required reading before baked asset and art pipeline docs. Add `Checkpoint 0: Default Skin Size SSOT` to `docs/reskin_checklist.md`.

- [x] **Step 4: Add contract**

Create `tests/test_default_skin_size_ssot_contract.gd`, requiring:

- baseline file exists,
- all role keys are present,
- checklist has Checkpoint 0,
- AGENTS requires the file,
- manifest and state point to the baseline.

- [x] **Step 5: Validate**

Run `test_default_skin_size_ssot_contract.gd`, full `tests/test_*.gd`, `git diff --check`, and SFX audit. Expected: pass, with no changed `sounds`.

## Task 1: Deep Theme Role Contract

**Files:**
- Create: `tests/test_deep_reskin_theme_contract.gd`
- Modify: `Resources/QuantumAssetRole.gd`
- Modify: `Resources/QuantumThemeConfig.gd`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

- [ ] **Step 1: Write the failing deep theme contract**

Create `tests/test_deep_reskin_theme_contract.gd`:

```gdscript
extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

const REQUIRED_ROLE_KEYS := [
	"player_model_role",
	"player_shadow_role",
	"player_trail_mesh_role",
	"collectible_model_role",
	"collectible_particle_role",
	"hud_icon_role",
	"platform_small_role",
	"platform_medium_role",
	"platform_falling_role",
	"platform_round_role",
	"platform_large_unused_role",
	"block_coin_unused_role",
	"obstacle_brick_role",
	"obstacle_brick_particle_role",
	"goal_flag_role",
	"prop_cloud_role",
	"prop_grass_role",
	"prop_grass_small_role",
	"skybox_role",
	"colormap_role"
]

const ALLOWED_MODES := ["legacy", "material", "replacement", "unused_candidate", "audio_deferred"]

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		for key in REQUIRED_ROLE_KEYS:
			var role = theme.get(key)
			passed = _assert_true(role != null, "%s should exist" % key) and passed
			if role != null:
				passed = _assert_true(role.has_method("validate_role"), "%s should be a QuantumAssetRole-like resource" % key) and passed
				passed = _assert_true(ALLOWED_MODES.has(role.mode), "%s should use an allowed mode, got %s" % [key, role.mode]) and passed
				passed = _assert_true(not role.legacy_path.strip_edges().is_empty(), "%s should record legacy path" % key) and passed
				passed = _assert_true(role.validate_role().is_empty(), "%s should validate cleanly" % key) and passed
	if passed:
		print("test_deep_reskin_theme_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_theme_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
```

- [ ] **Step 2: Run the failing contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_theme_contract.gd"
```

Expected: FAIL because `QuantumAssetRole.gd` and the deep role fields do not exist yet.

- [ ] **Step 3: Create the asset role resource**

Create `Resources/QuantumAssetRole.gd`:

```gdscript
extends Resource
class_name QuantumAssetRole

const ALLOWED_MODES := ["legacy", "material", "replacement", "unused_candidate", "audio_deferred"]

@export var role_key := ""
@export var legacy_path := ""
@export var reference_path := ""
@export var replacement_path := ""
@export_enum("legacy", "material", "replacement", "unused_candidate", "audio_deferred") var mode := "legacy"
@export var proof_path := ""
@export var notes := ""

func active_path() -> String:
	if mode == "replacement" and not replacement_path.strip_edges().is_empty():
		return replacement_path
	if mode == "material" and not reference_path.strip_edges().is_empty():
		return reference_path
	return legacy_path

func validate_role() -> Array[String]:
	var errors: Array[String] = []
	if role_key.strip_edges().is_empty():
		errors.append("role_key is required")
	if not ALLOWED_MODES.has(mode):
		errors.append("invalid mode: %s" % mode)
	if legacy_path.strip_edges().is_empty():
		errors.append("%s legacy_path is required" % role_key)
	if mode == "replacement" and replacement_path.strip_edges().is_empty():
		errors.append("%s replacement_path is required in replacement mode" % role_key)
	return errors
```

- [ ] **Step 4: Extend `QuantumThemeConfig.gd` with deep role fields**

Add this block after the Branding group and before the World group in `Resources/QuantumThemeConfig.gd`:

```gdscript
@export_group("Deep Reskin Roles")
@export var player_model_role: QuantumAssetRole
@export var player_shadow_role: QuantumAssetRole
@export var player_trail_mesh_role: QuantumAssetRole
@export var collectible_model_role: QuantumAssetRole
@export var collectible_particle_role: QuantumAssetRole
@export var hud_icon_role: QuantumAssetRole
@export var platform_small_role: QuantumAssetRole
@export var platform_medium_role: QuantumAssetRole
@export var platform_falling_role: QuantumAssetRole
@export var platform_round_role: QuantumAssetRole
@export var platform_large_unused_role: QuantumAssetRole
@export var block_coin_unused_role: QuantumAssetRole
@export var obstacle_brick_role: QuantumAssetRole
@export var obstacle_brick_particle_role: QuantumAssetRole
@export var goal_flag_role: QuantumAssetRole
@export var prop_cloud_role: QuantumAssetRole
@export var prop_grass_role: QuantumAssetRole
@export var prop_grass_small_role: QuantumAssetRole
@export var skybox_role: QuantumAssetRole
@export var colormap_role: QuantumAssetRole
```

In `validate()`, change the audio-key loop from:

```gdscript
for key in ["jump", "land", "coin", "walking"]:
```

to:

```gdscript
for key in ["jump", "land", "coin", "walking", "break", "fall"]:
```

Then add role validation before `return errors`:

```gdscript
for role in [
	player_model_role,
	player_shadow_role,
	player_trail_mesh_role,
	collectible_model_role,
	collectible_particle_role,
	hud_icon_role,
	platform_small_role,
	platform_medium_role,
	platform_falling_role,
	platform_round_role,
	platform_large_unused_role,
	block_coin_unused_role,
	obstacle_brick_role,
	obstacle_brick_particle_role,
	goal_flag_role,
	prop_cloud_role,
	prop_grass_role,
	prop_grass_small_role,
	skybox_role,
	colormap_role
]:
	if role == null:
		errors.append("deep reskin role is missing")
	else:
		errors.append_array(role.validate_role())
```

- [ ] **Step 5: Add role subresources to `theme_config.tres`**

Modify the header of `Resources/Data/Themes/candy_sky_islands/theme_config.tres`:

```ini
[gd_resource type="Resource" script_class="QuantumThemeConfig" load_steps=23 format=3]

[ext_resource type="Script" path="res://Resources/QuantumThemeConfig.gd" id="1_theme"]
[ext_resource type="Script" path="res://Resources/QuantumAssetRole.gd" id="2_role"]
```

Add these subresources before `[resource]`:

```ini
[sub_resource type="Resource" id="Role_player_model"]
script = ExtResource("2_role")
role_key = "player.model"
legacy_path = "res://models/character.glb"
reference_path = "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_player_marshmallow_runner.png"
notes = "Existing rig/model remains; material pass only."

[sub_resource type="Resource" id="Role_player_shadow"]
script = ExtResource("2_role")
role_key = "player.shadow"
legacy_path = "res://sprites/blob_shadow.png"
reference_path = ""
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Keep shadow until visual replacement is approved."

[sub_resource type="Resource" id="Role_player_trail_mesh"]
script = ExtResource("2_role")
role_key = "player.trail.dust"
legacy_path = "res://meshes/dust.res"
reference_path = ""
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_coin_pickup.png"
notes = "Trail color is themed; mesh remains old."

[sub_resource type="Resource" id="Role_collectible_model"]
script = ExtResource("2_role")
role_key = "collectible.coin.model"
legacy_path = "res://models/coin.glb"
reference_path = "res://assets/themes/candy_sky_islands/star_collectible.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_coin_pickup.png"
notes = "Coin model remains old until star-candy model/wrapper is approved."

[sub_resource type="Resource" id="Role_collectible_particle"]
script = ExtResource("2_role")
role_key = "collectible.coin.particle"
legacy_path = "res://sprites/particle.png"
reference_path = "res://assets/themes/candy_sky_islands/star_collectible.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_coin_pickup.png"
notes = "Particle color is themed; texture remains old."

[sub_resource type="Resource" id="Role_hud_icon"]
script = ExtResource("2_role")
role_key = "hud.star_candy.icon"
legacy_path = "res://sprites/coin.png"
reference_path = "res://assets/themes/candy_sky_islands/star_collectible.png"
replacement_path = "res://assets/themes/candy_sky_islands/star_collectible.png"
mode = "replacement"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_hud.png"
notes = "HUD icon uses approved extracted star collectible."

[sub_resource type="Resource" id="Role_platform_small"]
script = ExtResource("2_role")
role_key = "platform.small"
legacy_path = "res://models/platform.glb"
reference_path = "res://assets/themes/candy_sky_islands/platform_small.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png"
notes = "Small platform model remains old; material pass only."

[sub_resource type="Resource" id="Role_platform_medium"]
script = ExtResource("2_role")
role_key = "platform.medium"
legacy_path = "res://models/platform-medium.glb"
reference_path = "res://assets/themes/candy_sky_islands/platform_medium.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png"
notes = "Medium platform model remains old; material pass only."

[sub_resource type="Resource" id="Role_platform_falling"]
script = ExtResource("2_role")
role_key = "platform.falling"
legacy_path = "res://models/platform-falling.glb"
reference_path = "res://assets/themes/candy_sky_islands/platform_long.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png"
notes = "Falling behavior remains unchanged."

[sub_resource type="Resource" id="Role_platform_round"]
script = ExtResource("2_role")
role_key = "platform.round.large"
legacy_path = "res://models/platform-grass-large-round.glb"
reference_path = "res://assets/themes/candy_sky_islands/platform_large.png"
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Round platform remains old until approved replacement."

[sub_resource type="Resource" id="Role_platform_large_unused"]
script = ExtResource("2_role")
role_key = "platform.large.unused_candidate"
legacy_path = "res://models/platform-large.glb"
reference_path = "res://assets/themes/candy_sky_islands/platform_large.png"
replacement_path = ""
mode = "unused_candidate"
proof_path = ""
notes = "File exists but no direct scene reference was found in deep inventory."

[sub_resource type="Resource" id="Role_block_coin_unused"]
script = ExtResource("2_role")
role_key = "block.coin.unused_candidate"
legacy_path = "res://models/block-coin.glb"
reference_path = ""
replacement_path = ""
mode = "unused_candidate"
proof_path = ""
notes = "File exists but no direct scene reference was found in deep inventory."

[sub_resource type="Resource" id="Role_obstacle_brick"]
script = ExtResource("2_role")
role_key = "obstacle.brick"
legacy_path = "res://models/brick.glb"
reference_path = "res://assets/themes/candy_sky_islands/wafer_obstacle.png"
replacement_path = ""
mode = "material"
proof_path = ""
notes = "Brick model remains until candy wafer replacement is approved."

[sub_resource type="Resource" id="Role_obstacle_brick_particle"]
script = ExtResource("2_role")
role_key = "obstacle.brick.particle"
legacy_path = "res://models/brick-particle.glb"
reference_path = "res://assets/themes/candy_sky_islands/wafer_obstacle.png"
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Break particles remain old; SFX replacement is deferred."

[sub_resource type="Resource" id="Role_goal_flag"]
script = ExtResource("2_role")
role_key = "goal.flag"
legacy_path = "res://models/flag.glb"
reference_path = "res://assets/themes/candy_sky_islands/goal_flag.png"
replacement_path = ""
mode = "material"
proof_path = ""
notes = "Flag model remains until candy pennant replacement is approved."

[sub_resource type="Resource" id="Role_prop_cloud"]
script = ExtResource("2_role")
role_key = "prop.cloud"
legacy_path = "res://models/cloud.glb"
reference_path = "res://assets/themes/candy_sky_islands/cloud_large.png"
replacement_path = ""
mode = "material"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png"
notes = "Cloud model remains; material pass only."

[sub_resource type="Resource" id="Role_prop_grass"]
script = ExtResource("2_role")
role_key = "prop.grass"
legacy_path = "res://models/grass.glb"
reference_path = ""
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Grass remains old until prop replacement is approved."

[sub_resource type="Resource" id="Role_prop_grass_small"]
script = ExtResource("2_role")
role_key = "prop.grass.small"
legacy_path = "res://models/grass-small.glb"
reference_path = ""
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Small grass remains old until prop replacement is approved."

[sub_resource type="Resource" id="Role_skybox"]
script = ExtResource("2_role")
role_key = "env.skybox"
legacy_path = "res://sprites/skybox.png"
reference_path = "res://assets/themes/candy_sky_islands/sky_panel_islands.png"
replacement_path = "res://assets/themes/candy_sky_islands/sky_panel_islands.png"
mode = "replacement"
proof_path = "res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png"
notes = "Theme path points at approved candy sky panel; scene environment direct reference is tracked for cleanup."

[sub_resource type="Resource" id="Role_colormap"]
script = ExtResource("2_role")
role_key = "material.colormap"
legacy_path = "res://models/Textures/colormap.png"
reference_path = ""
replacement_path = ""
mode = "legacy"
proof_path = ""
notes = "Shared material texture remains until material cleanup is approved."
```

In `[resource]`, add:

```ini
player_model_role = SubResource("Role_player_model")
player_shadow_role = SubResource("Role_player_shadow")
player_trail_mesh_role = SubResource("Role_player_trail_mesh")
collectible_model_role = SubResource("Role_collectible_model")
collectible_particle_role = SubResource("Role_collectible_particle")
hud_icon_role = SubResource("Role_hud_icon")
platform_small_role = SubResource("Role_platform_small")
platform_medium_role = SubResource("Role_platform_medium")
platform_falling_role = SubResource("Role_platform_falling")
platform_round_role = SubResource("Role_platform_round")
platform_large_unused_role = SubResource("Role_platform_large_unused")
block_coin_unused_role = SubResource("Role_block_coin_unused")
obstacle_brick_role = SubResource("Role_obstacle_brick")
obstacle_brick_particle_role = SubResource("Role_obstacle_brick_particle")
goal_flag_role = SubResource("Role_goal_flag")
prop_cloud_role = SubResource("Role_prop_cloud")
prop_grass_role = SubResource("Role_prop_grass")
prop_grass_small_role = SubResource("Role_prop_grass_small")
skybox_role = SubResource("Role_skybox")
colormap_role = SubResource("Role_colormap")
```

Add missing audio paths:

```ini
audio_event_paths = {
"break": "res://sounds/break.ogg",
"coin": "res://sounds/coin.ogg",
"fall": "res://sounds/fall.ogg",
"jump": "res://sounds/jump.ogg",
"land": "res://sounds/land.ogg",
"walking": "res://sounds/walking.ogg"
}
```

- [ ] **Step 6: Run deep theme contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_theme_contract.gd"
```

Expected: PASS with `test_deep_reskin_theme_contract: PASS`.

- [ ] **Step 7: Commit Task 1**

Run:

```powershell
git add Resources/QuantumAssetRole.gd Resources/QuantumThemeConfig.gd Resources/Data/Themes/candy_sky_islands/theme_config.tres tests/test_deep_reskin_theme_contract.gd
git -c user.name='Codex' -c user.email='codex@local' commit -m 'test: add candy deep reskin theme contract'
```

Expected: commit succeeds with only Task 1 files staged.

## Task 2: Audio Inventory Routing Without SFX Replacement

**Files:**
- Create: `tests/test_deep_reskin_audio_contract.gd`
- Modify: `scripts/audio.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/player.gd`
- Modify: `objects/coin.gd`
- Modify: `objects/brick.gd`
- Modify: `objects/platform_falling.gd`

- [ ] **Step 1: Write the failing audio contract**

Create `tests/test_deep_reskin_audio_contract.gd`:

```gdscript
extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const AUDIO_SCRIPT := "res://scripts/audio.gd"
const MAIN_SCRIPT := "res://scripts/main.gd"
const PLAYER_SCRIPT := "res://scripts/player.gd"
const COIN_SCRIPT := "res://objects/coin.gd"
const BRICK_SCRIPT := "res://objects/brick.gd"
const FALLING_SCRIPT := "res://objects/platform_falling.gd"

const REQUIRED_AUDIO_KEYS := ["jump", "land", "coin", "walking", "break", "fall"]

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		for key in REQUIRED_AUDIO_KEYS:
			passed = _assert_true(theme.audio_event_paths.has(key), "Theme should include audio event %s" % key) and passed
			if theme.audio_event_paths.has(key):
				var path := String(theme.audio_event_paths[key])
				passed = _assert_true(ResourceLoader.exists(path) or FileAccess.file_exists(path), "Audio path should exist for %s: %s" % [key, path]) and passed
	passed = _assert_file_contains(AUDIO_SCRIPT, "func configure_events", "Audio autoload should accept event map") and passed
	passed = _assert_file_contains(AUDIO_SCRIPT, "func play_event", "Audio autoload should expose play_event") and passed
	passed = _assert_file_contains(MAIN_SCRIPT, "Audio.configure_events(theme_config.audio_event_paths)", "Main should configure audio events from theme") and passed
	passed = _assert_file_contains(PLAYER_SCRIPT, "Audio.play_event(\"land\")", "Player land should use audio event") and passed
	passed = _assert_file_contains(PLAYER_SCRIPT, "Audio.play_event(\"jump\")", "Player jump should use audio event") and passed
	passed = _assert_file_contains(COIN_SCRIPT, "Audio.play_event(\"coin\")", "Coin pickup should use audio event") and passed
	passed = _assert_file_contains(BRICK_SCRIPT, "Audio.play_event(\"break\")", "Brick break should use audio event") and passed
	passed = _assert_file_contains(FALLING_SCRIPT, "Audio.play_event(\"fall\")", "Falling platform should use audio event") and passed
	passed = _assert_file_not_contains(PLAYER_SCRIPT, "res://sounds/jump.ogg", "Player should not hardcode jump SFX path") and passed
	passed = _assert_file_not_contains(PLAYER_SCRIPT, "res://sounds/land.ogg", "Player should not hardcode land SFX path") and passed
	passed = _assert_file_not_contains(COIN_SCRIPT, "res://sounds/coin.ogg", "Coin should not hardcode coin SFX path") and passed
	passed = _assert_file_not_contains(BRICK_SCRIPT, "res://sounds/break.ogg", "Brick should not hardcode break SFX path") and passed
	passed = _assert_file_not_contains(FALLING_SCRIPT, "res://sounds/fall.ogg", "Falling platform should not hardcode fall SFX path") and passed
	if passed:
		print("test_deep_reskin_audio_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_audio_contract: FAIL")
		quit(1)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains(needle):
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
```

- [ ] **Step 2: Run the failing audio contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_audio_contract.gd"
```

Expected: FAIL because audio routing still uses direct paths. `break` and `fall` should already exist in the theme after Task 1.

- [ ] **Step 3: Update `scripts/audio.gd`**

Replace `scripts/audio.gd` with:

```gdscript
extends Node

# Code adapted from KidsCanCode.

var num_players = 12
var bus = "master"

var available = []
var queue = []
var event_paths := {}

func _ready():
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.volume_db = -10
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus

func configure_events(paths: Dictionary) -> void:
	event_paths = paths.duplicate(true)

func play_event(event_name: String) -> void:
	if not event_paths.has(event_name):
		push_warning("Missing audio event path: %s" % event_name)
		return
	play(String(event_paths[event_name]))

func _on_stream_finished(stream):
	available.append(stream)

func play(sound_path):
	queue.append(sound_path)

func _process(_delta):
	if not queue.is_empty() and not available.is_empty():
		available[0].stream = load(queue.pop_front())
		available[0].play()
		available[0].pitch_scale = randf_range(0.9, 1.1)
		available.pop_front()
```

- [ ] **Step 4: Configure audio events in `scripts/main.gd`**

Ensure `_ready()` includes this inside the existing `if theme_config != null:` block:

```gdscript
if Audio.has_method("configure_events"):
	Audio.configure_events(theme_config.audio_event_paths)
```

The resulting block should be:

```gdscript
if theme_config != null:
	if Audio.has_method("configure_events"):
		Audio.configure_events(theme_config.audio_event_paths)
	var applier := preload("res://scripts/theme_applier.gd").new()
	add_child(applier)
	applier.apply_theme(self, theme_config)
```

- [ ] **Step 5: Route existing audio calls through events**

Change `scripts/player.gd`:

```gdscript
Audio.play("res://sounds/land.ogg")
```

to:

```gdscript
Audio.play_event("land")
```

Change:

```gdscript
Audio.play("res://sounds/jump.ogg")
```

to:

```gdscript
Audio.play_event("jump")
```

Change `objects/coin.gd`:

```gdscript
Audio.play("res://sounds/coin.ogg") # Play sound
```

to:

```gdscript
Audio.play_event("coin") # Play sound
```

Change `objects/brick.gd`:

```gdscript
Audio.play("res://sounds/break.ogg") # Play sound
```

to:

```gdscript
Audio.play_event("break") # Play sound
```

Change `objects/platform_falling.gd`:

```gdscript
Audio.play("res://sounds/fall.ogg") # Play sound
```

to:

```gdscript
Audio.play_event("fall") # Play sound
```

- [ ] **Step 6: Run audio contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_audio_contract.gd"
```

Expected: PASS with `test_deep_reskin_audio_contract: PASS`.

- [ ] **Step 7: Commit Task 2**

Run:

```powershell
git add scripts/audio.gd scripts/main.gd scripts/player.gd objects/coin.gd objects/brick.gd objects/platform_falling.gd tests/test_deep_reskin_audio_contract.gd
git -c user.name='Codex' -c user.email='codex@local' commit -m 'refactor: route candy audio through theme events'
```

Expected: commit succeeds. This commit does not replace any `.ogg` files.

## Task 3: Manifest, Checklist, And State Coverage

**Files:**
- Create: `tests/test_deep_reskin_manifest_contract.gd`
- Modify: `docs/asset_manifest.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`

- [ ] **Step 1: Write the failing manifest contract**

Create `tests/test_deep_reskin_manifest_contract.gd`:

```gdscript
extends SceneTree

const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const SPEC := "res://docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md"
const PLAN := "res://docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md"

const REQUIRED_MANIFEST_KEYS := [
	"player.model",
	"player.shadow",
	"player.trail.dust",
	"collectible.coin.model",
	"collectible.coin.particle",
	"hud.star_candy.icon",
	"platform.small",
	"platform.medium",
	"platform.falling",
	"platform.round.large",
	"platform.large.unused_candidate",
	"block.coin.unused_candidate",
	"obstacle.brick",
	"obstacle.brick.particle",
	"goal.flag",
	"prop.cloud",
	"prop.grass",
	"prop.grass.small",
	"env.skybox",
	"material.colormap",
	"audio.break",
	"audio.fall"
]

func _init() -> void:
	var passed := true
	for key in REQUIRED_MANIFEST_KEYS:
		passed = _assert_file_contains(MANIFEST, key, "Manifest should include %s" % key) and passed
	passed = _assert_file_contains(CHECKLIST, "### Checkpoint 5: Deep Reskin", "Checklist should include deep reskin checkpoint") and passed
	passed = _assert_file_contains(CHECKLIST, "Stop before SFX replacement", "Checklist should record SFX stop rule") and passed
	passed = _assert_file_contains(STATE, "Deep Reskin", "State should mention deep reskin gate") and passed
	passed = _assert_file_contains(STATE, "SFX replacement deferred", "State should record SFX deferral") and passed
	passed = _assert_file_contains(SPEC, "Stop before SFX Replacement", "Spec should record SFX boundary") and passed
	passed = _assert_file_contains(PLAN, "Candy Sky Islands Deep Reskin Implementation Plan", "Plan should exist") and passed
	if passed:
		print("test_deep_reskin_manifest_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_manifest_contract: FAIL")
		quit(1)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
```

- [ ] **Step 2: Run the failing manifest contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_manifest_contract.gd"
```

Expected: FAIL because missing deep rows and Checkpoint 5 docs are not written yet.

- [ ] **Step 3: Add missing manifest rows**

In `docs/asset_manifest.md`, add these rows to `## Current Asset Inventory` after related existing rows:

```markdown
| Platform large unused candidate | platform.large.unused_candidate | `res://models/platform-large.glb` | Kenney package | unused candidate, deep-reskin inventory | N/A | N/A | not used in current scene | none | File exists; no direct scene reference found in current inventory |
| Block coin unused candidate | block.coin.unused_candidate | `res://models/block-coin.glb` | Kenney package | unused candidate, deep-reskin inventory | N/A | N/A | not used in current scene | none | File exists; no direct scene reference found in current inventory |
| Break SFX | audio.break | `res://sounds/break.ogg` | Kenney package | current, SFX replacement deferred | N/A | N/A | brick break event | none | Routed through SSOT only; no SFX replacement in deep visual gate |
| Fall SFX | audio.fall | `res://sounds/fall.ogg` | Kenney package | current, SFX replacement deferred | N/A | N/A | falling platform event | none | Routed through SSOT only; no SFX replacement in deep visual gate |
```

Update existing current rows so notes include the exact old asset status:

```markdown
Player model notes: Existing rig/model unchanged; deep role `player.model` uses material mode.
Coin model notes: Existing coin mesh unchanged; deep role `collectible.coin.model` uses material mode until star-candy model/wrapper approval.
Brick block notes: Existing brick model unchanged; deep role `obstacle.brick` uses material mode until wafer replacement approval.
Flag goal notes: Existing flag model unchanged; deep role `goal.flag` uses material mode until pennant replacement approval.
Shared colormap notes: Keep through deep role `material.colormap`; replacement requires separate material cleanup approval.
```

- [ ] **Step 4: Add Checkpoint 5 to checklist**

In `docs/reskin_checklist.md`, add this section after Checkpoint 4:

```markdown
### Checkpoint 5: Deep Reskin

- [x] Owner approved Approach A: deep-but-safe visual reskin.
- [x] Owner approved stopping before SFX replacement.
- [x] Deep Reskin design spec written: `docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md`.
- [x] Owner reviewed written Deep Reskin spec.
- [x] Deep Reskin implementation plan written: `docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md`.
- [ ] Deep visual roles represented in SSOT.
- [ ] Deep manifest contract passes.
- [ ] Audio inventory includes `break` and `fall`.
- [ ] Existing SFX paths are routed through SSOT without replacing `.ogg` files.
- [ ] Collectible visual replacement group owner approved.
- [ ] Platform visual replacement group owner approved.
- [ ] Obstacle visual replacement group owner approved.
- [ ] Goal visual replacement group owner approved.
- [ ] Props/background visual replacement group owner approved.
- [ ] Player model wrapper group owner approved if attempted.
- [ ] Deep visual validation passed.
- [ ] Stop before SFX replacement confirmed.

Hard gate:
- Do not generate, replace, or approve new SFX in this checkpoint.
- Do not create visual replacements for a group until that group has owner approval.
- Do not use grid slicing. Run Photoroom on the full approved sheet before polygon/outline object extraction.
- Do not use primitive-only dummy meshes, rough placeholder geometry, or local Blender scripts with no approved reference-derived silhouette/material cues as production visual replacements.
```

- [ ] **Step 5: Update state for current gate**

In `docs/reskin_state.md`, replace `## Current Gate` content with:

```markdown
Deep Reskin implementation planning after owner-approved written spec. SFX replacement deferred.
```

Replace `## Pending Assets` with:

```markdown
## Pending Assets

- Deep visual SSOT role coverage for old assets.
- Collectible star-candy model or wrapper replacement if separately approved.
- Cake/cloud platform model or wrapper replacements if separately approved.
- Wafer obstacle replacement if separately approved.
- Candy pennant goal replacement if separately approved.
- Cloud, grass, dust, particle, skybox, and material cleanup if separately approved.
- SFX replacement deferred; current SFX may only be inventoried and routed through SSOT in this gate.
- No branding assets pending.
```

Add this validation note:

```markdown
- Deep Reskin plan written on 2026-07-07; implementation validation not run yet.
```

- [ ] **Step 6: Run manifest contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_deep_reskin_manifest_contract.gd"
```

Expected: PASS with `test_deep_reskin_manifest_contract: PASS`.

- [ ] **Step 7: Commit Task 3**

Run:

```powershell
git add docs/asset_manifest.md docs/reskin_checklist.md docs/reskin_state.md tests/test_deep_reskin_manifest_contract.gd
git -c user.name='Codex' -c user.email='codex@local' commit -m 'docs: record candy deep reskin inventory gate'
```

Expected: commit succeeds.

## Task 4: Visual Replacement Group Gates

**Files:**
- Modify after owner group approvals: `docs/reskin_state.md`
- Modify after owner group approvals: `docs/reskin_checklist.md`
- Modify after owner group approvals: `docs/asset_manifest.md`
- Modify after owner group approvals: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

- [ ] **Step 1: Present group gate list to owner**

Ask owner:

```text
Deep visual replacement group order:
A: collectible star-candy first
B: platform kit first
C: obstacle + goal first
D: props/background first
E: player wrapper first

SFX remains deferred. Chọn group đầu tiên để thiết kế options.
```

Expected: owner chooses one group before any new visual asset creation.

- [ ] **Step 2: For the chosen group, write options before generation**

For collectible, present:

```text
Collectible options:
A: keep current coin mesh, stronger material/VFX only.
B: build simple local Godot star-candy mesh wrapper, keep Area3D behavior.
C: generate approved star-candy sheet/model reference, Photoroom full sheet first, polygon extract refs, then build wrapper.
Recommended: B for safe geometry, C only if owner wants fresh AI art.
```

For platform kit, present:

```text
Platform options:
A: keep GLB mesh, stronger material/top-edge routing.
B: create local wrapper scenes with cake/cloud MeshInstance3D parts around current colliders.
C: generate platform sheet refs, Photoroom full sheet first, polygon extract refs, then build wrappers.
Recommended: B for stable collision and deeper visual change.
```

For obstacle + goal, present:

```text
Obstacle/goal options:
A: material-only wafer and pennant.
B: local wrapper visual meshes around existing brick/flag nodes.
C: generated refs from approved sheet, Photoroom full sheet first, polygon extract refs, then wrapper meshes.
Recommended: B because behavior remains stable.
```

For props/background, present:

```text
Props/background options:
A: keep models and replace skybox only through SSOT.
B: wrapper clouds/grass/dust plus skybox routing.
C: generate props sheet, Photoroom full sheet first, polygon extract refs, then wrappers.
Recommended: A or B depending screenshot priority.
```

For player wrapper, present:

```text
Player options:
A: keep current rig and improve material pass only.
B: add non-rigged cosmetic child meshes to current player.
C: replace model only if animation compatibility is proven first.
Recommended: A now, B only after visible groups pass.
```

- [ ] **Step 3: Record approval before any asset work**

After owner picks group and option, update `docs/reskin_state.md`:

```markdown
## Current Gate

Deep Reskin <group name> visual design approved; implementation pending.
```

Update `docs/reskin_checklist.md` by checking the matching group approval item only.

For any 3D role, also record whether the approved option preserves 3D volume/depth. If it does not, the approval must explicitly say the owner accepts a flat 2D downgrade; otherwise continue to a reference-derived 3D mesh/model plan.

- [ ] **Step 4: Commit the group approval docs**

Run:

```powershell
git add docs/reskin_state.md docs/reskin_checklist.md
git -c user.name='Codex' -c user.email='codex@local' commit -m 'docs: approve candy deep reskin group gate'
```

Expected: commit succeeds. No assets are created in this task.

## Task 5: Validation After SSOT And Audio Routing

**Files:**
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`

- [ ] **Step 1: Run all Godot script tests**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-ChildItem "$project\tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: all tests exit `0`, including:

```text
test_deep_reskin_audio_contract: PASS
test_deep_reskin_manifest_contract: PASS
test_deep_reskin_theme_contract: PASS
```

- [ ] **Step 2: Run Godot import**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --import
```

Expected: exit code `0`. Existing invalid UID and Godot 3.x material remap warnings may remain as known warnings.

- [ ] **Step 3: Run visible smoke screenshot capture**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project --script "$project\tools\capture_candy_sky_screenshots.gd"
```

Expected: `capture_candy_sky_screenshots: PASS`.

- [ ] **Step 4: Run whitespace check**

Run:

```powershell
git diff --check
```

Expected: no output and exit code `0`.

- [ ] **Step 5: Update validation docs**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] Deep visual roles represented in SSOT.
- [x] Deep manifest contract passes.
- [x] Audio inventory includes `break` and `fall`.
- [x] Existing SFX paths are routed through SSOT without replacing `.ogg` files.
```

In `docs/reskin_state.md`, add:

```markdown
- Deep SSOT, manifest, and audio inventory validation passed on 2026-07-07.
- Existing SFX files remained unchanged; SFX replacement deferred.
```

- [ ] **Step 6: Commit validation docs**

Run:

```powershell
git add docs/reskin_checklist.md docs/reskin_state.md
git -c user.name='Codex' -c user.email='codex@local' commit -m 'docs: validate candy deep reskin ssot gate'
```

Expected: commit succeeds.

## Task 6: Final Audit

**Files:**
- Read: `AGENTS.md`
- Read: `docs/reskin_state.md`
- Read: `docs/reskin_checklist.md`
- Read: `docs/asset_manifest.md`
- Read: `docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md`
- Read: `docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md`

- [ ] **Step 1: Re-read reset guard files**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-Content -Raw "$project\AGENTS.md"
Get-Content -Raw "$project\docs\reskin_state.md"
Get-Content -Raw "$project\docs\reskin_checklist.md"
Get-Content -Raw "$project\docs\asset_manifest.md"
Get-Content -Raw "$project\docs\superpowers\specs\2026-07-07-candy-sky-islands-deep-reskin-design.md"
Get-Content -Raw "$project\docs\superpowers\plans\2026-07-07-candy-sky-islands-deep-reskin.md"
git -C $project status --short
```

Expected: docs agree that visual replacement groups are pending and SFX replacement is deferred.

- [ ] **Step 2: Verify SFX files were not replaced**

Run:

```powershell
git diff -- sounds
git status --short -- sounds
```

Expected: no changed `.ogg` files for this gate.

- [ ] **Step 3: Verify gameplay scripts only changed audio routing**

Run:

```powershell
git diff HEAD~4..HEAD -- scripts/player.gd objects/coin.gd objects/brick.gd objects/platform_falling.gd
```

Expected: changes only replace `Audio.play("res://sounds/...")` with `Audio.play_event("<event>")`; movement, scoring, collision, falling, reload, and pickup behavior remain unchanged.

- [ ] **Step 4: Report final state**

Report:

```text
Current gate:
Completed deep-reskin setup:
Pending visual groups:
SFX status:
Validation commands run:
Known warnings:
```

Expected: report does not call deep visual replacement complete and does not claim SFX reskin.
