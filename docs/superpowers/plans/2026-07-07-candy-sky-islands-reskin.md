# Candy Sky Islands Reskin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SSOT-first Candy Sky Islands visual reskin for `quantum_starter` while preserving existing 3D platformer gameplay behavior.

**Architecture:** Add a small theme resource and a single theme application script so skin values live in game-owned SSOT instead of being scattered through scenes. Apply the first visual pass with material/HUD/environment tokens, avoiding deep GLB swaps until a Root Asset is owner-approved.

**Tech Stack:** Godot 4 GDScript, `.tres` resources, PowerShell validation commands, existing Godot scenes/scripts.

---

## File Structure

- Create `Resources/QuantumThemeConfig.gd`: typed game-local resource for Candy Sky Islands skin tokens.
- Create `Resources/Data/Themes/candy_sky_islands/theme_config.tres`: approved palette, paths, HUD owner rect, material colors, audio events.
- Create `scripts/theme_applier.gd`: applies `QuantumThemeConfig` to HUD, environment, coin material, player trail, and scene metadata.
- Modify `scenes/main.tscn`: add `theme_config` export to `Main`, attach theme applier via `scripts/main.gd`, and move HUD values toward SSOT.
- Modify `scripts/main.gd`: load/apply the theme on ready.
- Create `tests/test_candy_theme_config.gd`: validates theme resource required values.
- Create `tests/test_reskin_static_contract.gd`: validates manifest/checklist/SSOT coverage without launching the editor.
- Modify `docs/asset_manifest.md`: record Candy Sky Islands SSOT-owned current/reused assets.
- Modify `docs/reskin_checklist.md`: record plan, validation evidence, and gate results.

## Task 1: Theme SSOT Resource

**Files:**
- Create: `Resources/QuantumThemeConfig.gd`
- Create: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`
- Test: `tests/test_candy_theme_config.gd`

- [ ] **Step 1: Create failing theme config test**

Create `tests/test_candy_theme_config.gd`:

```gdscript
extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		passed = passed and _assert_equal(theme.theme_name, "candy_sky_islands", "Theme name should match")
		passed = passed and _assert_equal(theme.display_name, "Candy Sky Islands", "Display name should match")
		passed = passed and _assert_equal(theme.palette_sky.to_html(false), "79c7f2", "Sky color should match approval")
		passed = passed and _assert_equal(theme.palette_surface.to_html(false), "fff2c7", "Surface color should match approval")
		passed = passed and _assert_equal(theme.palette_primary.to_html(false), "ff6f61", "Primary color should match approval")
		passed = passed and _assert_equal(theme.palette_accent.to_html(false), "7be0ad", "Accent color should match approval")
		passed = passed and _assert_equal(theme.palette_text.to_html(false), "273043", "Text color should match approval")
		passed = passed and _assert_true(theme.hud_coin_icon_path == "res://sprites/coin.png", "HUD coin path should be explicit")
		passed = passed and _assert_true(theme.hud_font_path == "res://fonts/lilita_one_regular.ttf", "HUD font path should be explicit")
		passed = passed and _assert_true(theme.hud_text_owner_rect.size.x > 0.0, "HUD text owner width should be positive")
		passed = passed and _assert_true(theme.hud_text_owner_rect.size.y > 0.0, "HUD text owner height should be positive")
	if passed:
		print("test_candy_theme_config: PASS")
		quit(0)
	else:
		print("test_candy_theme_config: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_candy_theme_config.gd"
```

Expected: FAIL because `theme_config.tres` does not exist yet.

- [ ] **Step 3: Create theme resource script**

Create `Resources/QuantumThemeConfig.gd`:

```gdscript
extends Resource
class_name QuantumThemeConfig

@export var theme_name := ""
@export var display_name := ""

@export_group("Palette")
@export var palette_sky := Color("#79C7F2")
@export var palette_surface := Color("#FFF2C7")
@export var palette_primary := Color("#FF6F61")
@export var palette_accent := Color("#7BE0AD")
@export var palette_text := Color("#273043")

@export_group("HUD")
@export_file("*.png", "*.webp") var hud_coin_icon_path := "res://sprites/coin.png"
@export_file("*.ttf", "*.otf") var hud_font_path := "res://fonts/lilita_one_regular.ttf"
@export var hud_text_owner_rect := Rect2(144.0, 64.0, 224.0, 59.0)
@export var hud_text_padding := Vector4(0.0, 0.0, 0.0, 0.0)
@export var hud_font_size := 48

@export_group("World")
@export_file("*.png", "*.webp") var skybox_path := "res://sprites/skybox.png"
@export var platform_material_color := Color("#FFF2C7")
@export var coin_material_color := Color("#FF6F61")
@export var coin_rim_color := Color("#7BE0AD")
@export var trail_particle_color := Color("#7BE0AD")
@export var cloud_material_color := Color("#FFFFFF")

@export_group("Audio")
@export var audio_event_paths := {
	"jump": "res://sounds/jump.ogg",
	"land": "res://sounds/land.ogg",
	"coin": "res://sounds/coin.ogg",
	"walking": "res://sounds/walking.ogg"
}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if theme_name.strip_edges().is_empty():
		errors.append("theme_name is required")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	for path in [hud_coin_icon_path, hud_font_path, skybox_path]:
		if path.strip_edges().is_empty():
			errors.append("asset path is empty")
		elif not ResourceLoader.exists(path):
			errors.append("missing asset path: %s" % path)
	if hud_text_owner_rect.size.x <= 0.0 or hud_text_owner_rect.size.y <= 0.0:
		errors.append("hud_text_owner_rect must have positive size")
	for key in ["jump", "land", "coin", "walking"]:
		if not audio_event_paths.has(key):
			errors.append("missing audio event: %s" % key)
	return errors
```

- [ ] **Step 4: Create Candy theme `.tres`**

Create `Resources/Data/Themes/candy_sky_islands/theme_config.tres`:

```ini
[gd_resource type="Resource" script_class="QuantumThemeConfig" load_steps=2 format=3]

[ext_resource type="Script" path="res://Resources/QuantumThemeConfig.gd" id="1_theme"]

[resource]
script = ExtResource("1_theme")
theme_name = "candy_sky_islands"
display_name = "Candy Sky Islands"
palette_sky = Color(0.47451, 0.780392, 0.94902, 1)
palette_surface = Color(1, 0.94902, 0.780392, 1)
palette_primary = Color(1, 0.435294, 0.380392, 1)
palette_accent = Color(0.482353, 0.878431, 0.678431, 1)
palette_text = Color(0.152941, 0.188235, 0.262745, 1)
hud_coin_icon_path = "res://sprites/coin.png"
hud_font_path = "res://fonts/lilita_one_regular.ttf"
hud_text_owner_rect = Rect2(144, 64, 224, 59)
hud_text_padding = Vector4(0, 0, 0, 0)
hud_font_size = 48
skybox_path = "res://sprites/skybox.png"
platform_material_color = Color(1, 0.94902, 0.780392, 1)
coin_material_color = Color(1, 0.435294, 0.380392, 1)
coin_rim_color = Color(0.482353, 0.878431, 0.678431, 1)
trail_particle_color = Color(0.482353, 0.878431, 0.678431, 1)
cloud_material_color = Color(1, 1, 1, 1)
audio_event_paths = {
"coin": "res://sounds/coin.ogg",
"jump": "res://sounds/jump.ogg",
"land": "res://sounds/land.ogg",
"walking": "res://sounds/walking.ogg"
}
```

- [ ] **Step 5: Run test to verify it passes**

Run same command from Step 2.

Expected: PASS with `test_candy_theme_config: PASS`.

## Task 2: Static Reskin Contract

**Files:**
- Create: `tests/test_reskin_static_contract.gd`
- Modify: `docs/asset_manifest.md`
- Modify: `docs/reskin_checklist.md`

- [ ] **Step 1: Create static contract test**

Create `tests/test_reskin_static_contract.gd`:

```gdscript
extends SceneTree

const CHECKLIST := "res://docs/reskin_checklist.md"
const MANIFEST := "res://docs/asset_manifest.md"
const SPEC := "res://docs/superpowers/specs/2026-07-07-candy-sky-islands-reskin-design.md"
const THEME := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Owner approved theme name: Candy Sky Islands.", "Checklist should record theme approval")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Checkpoint 1 approved.", "Checklist should record Checkpoint 1")
	passed = passed and _assert_file_contains(MANIFEST, "collectible.coin.scene", "Manifest should inventory coin scene")
	passed = passed and _assert_file_contains(MANIFEST, "hud.coin.text", "Manifest should inventory HUD text")
	passed = passed and _assert_file_contains(SPEC, "Candy Sky Islands", "Spec should name the approved theme")
	passed = passed and _assert_true(ResourceLoader.exists(THEME), "Theme resource should exist")
	if passed:
		print("test_reskin_static_contract: PASS")
		quit(0)
	else:
		print("test_reskin_static_contract: FAIL")
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

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
```

- [ ] **Step 2: Run static contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_reskin_static_contract.gd"
```

Expected: PASS after Task 1 is complete.

- [ ] **Step 3: Update checklist evidence**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] `Resources/QuantumThemeConfig.gd` or equivalent game-local theme resource created.
- [x] `Resources/Data/Themes/<theme>/theme_config.tres` or equivalent created.
- [x] Color palette stored in SSOT.
- [x] HUD icon/font/color/owner rect stored in SSOT.
- [x] Audio event names stored in SSOT if changed.
```

Expected: checklist reflects SSOT creation without claiming visual completion.

## Task 3: Theme Application Pass

**Files:**
- Create: `scripts/theme_applier.gd`
- Modify: `scripts/main.gd`
- Modify: `scenes/main.tscn`
- Test: `tests/test_theme_applier_contract.gd`

- [ ] **Step 1: Create theme applier contract test**

Create `tests/test_theme_applier_contract.gd`:

```gdscript
extends SceneTree

const APPLIER := "res://scripts/theme_applier.gd"
const MAIN_SCRIPT := "res://scripts/main.gd"
const MAIN_SCENE := "res://scenes/main.tscn"

func _init() -> void:
	var passed := true
	passed = passed and _assert_file_contains(APPLIER, "func apply_theme", "Theme applier should expose apply_theme")
	passed = passed and _assert_file_contains(APPLIER, "hud_text_owner_rect", "Theme applier should use HUD owner rect")
	passed = passed and _assert_file_contains(MAIN_SCRIPT, "theme_config", "Main script should expose theme config")
	passed = passed and _assert_file_contains(MAIN_SCENE, "candy_sky_islands/theme_config.tres", "Main scene should reference Candy theme")
	if passed:
		print("test_theme_applier_contract: PASS")
		quit(0)
	else:
		print("test_theme_applier_contract: FAIL")
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

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_theme_applier_contract.gd"
```

Expected: FAIL because `scripts/theme_applier.gd` does not exist yet.

- [ ] **Step 3: Create theme applier**

Create `scripts/theme_applier.gd`:

```gdscript
extends Node

func apply_theme(root: Node, theme: QuantumThemeConfig) -> void:
	if root == null or theme == null:
		return
	_apply_hud(root, theme)
	_apply_player_trail(root, theme)
	_apply_coin_materials(root, theme)
	_apply_cloud_materials(root, theme)

func _apply_hud(root: Node, theme: QuantumThemeConfig) -> void:
	var hud := root.get_node_or_null("HUD")
	if hud == null:
		return
	var icon := hud.get_node_or_null("Icon") as TextureRect
	if icon != null and ResourceLoader.exists(theme.hud_coin_icon_path):
		icon.texture = load(theme.hud_coin_icon_path)
	var coins := hud.get_node_or_null("Coins") as Label
	if coins != null:
		coins.offset_left = theme.hud_text_owner_rect.position.x + theme.hud_text_padding.x
		coins.offset_top = theme.hud_text_owner_rect.position.y + theme.hud_text_padding.y
		coins.offset_right = theme.hud_text_owner_rect.end.x - theme.hud_text_padding.z
		coins.offset_bottom = theme.hud_text_owner_rect.end.y - theme.hud_text_padding.w
		coins.add_theme_color_override("font_color", theme.palette_text)
		coins.add_theme_font_size_override("font_size", theme.hud_font_size)
		if ResourceLoader.exists(theme.hud_font_path):
			coins.add_theme_font_override("font", load(theme.hud_font_path))

func _apply_player_trail(root: Node, theme: QuantumThemeConfig) -> void:
	var player := root.get_node_or_null("Player")
	if player == null:
		return
	var particles := player.get_node_or_null("ParticlesTrail") as GPUParticles3D
	if particles == null:
		return
	var material := particles.material_override as StandardMaterial3D
	if material == null:
		return
	var themed_material := material.duplicate() as StandardMaterial3D
	themed_material.albedo_color = theme.trail_particle_color
	themed_material.backlight = theme.palette_sky
	particles.material_override = themed_material

func _apply_coin_materials(root: Node, theme: QuantumThemeConfig) -> void:
	for coin in root.get_tree().get_nodes_in_group("candy_theme_coin"):
		_apply_coin_node(coin, theme)
	var world := root.get_node_or_null("World")
	if world == null:
		return
	for child in world.get_children():
		if String(child.name).begins_with("coin"):
			_apply_coin_node(child, theme)

func _apply_coin_node(node: Node, theme: QuantumThemeConfig) -> void:
	var mesh := node.get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var material := mesh.get_surface_override_material(0) as StandardMaterial3D
	if material == null:
		return
	var themed_material := material.duplicate() as StandardMaterial3D
	themed_material.albedo_color = theme.coin_material_color
	themed_material.rim_enabled = true
	themed_material.rim = 0.5
	themed_material.rim_tint = 0.8
	mesh.set_surface_override_material(0, themed_material)

func _apply_cloud_materials(root: Node, theme: QuantumThemeConfig) -> void:
	var world := root.get_node_or_null("World")
	if world == null:
		return
	for child in world.get_children():
		if not String(child.name).begins_with("cube"):
			continue
		var mesh := child.get_node_or_null("cloud/cloud") as MeshInstance3D
		if mesh == null:
			continue
		var material := mesh.get_surface_override_material(0) as StandardMaterial3D
		if material == null:
			continue
		var themed_material := material.duplicate() as StandardMaterial3D
		themed_material.albedo_color = theme.cloud_material_color
		mesh.set_surface_override_material(0, themed_material)
```

- [ ] **Step 4: Modify `scripts/main.gd`**

Replace `scripts/main.gd` with this version, preserving the existing Compatibility renderer brightness adjustment:

```gdscript
extends Node3D

@export var theme_config: QuantumThemeConfig

func _ready() -> void:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		# Reduce background and sun brightness when using the Compatibility renderer;
		# this tries to roughly match the appearance of Forward+.
		# This compensates for the different color space and light rendering for lights with shadows enabled.
		$Sun.light_energy = 0.24
		$Sun.shadow_opacity = 0.85
		$Environment.environment.background_energy_multiplier = 0.25
	if theme_config != null:
		var applier := preload("res://scripts/theme_applier.gd").new()
		add_child(applier)
		applier.apply_theme(self, theme_config)
```

- [ ] **Step 5: Modify `scenes/main.tscn`**

Add an `ext_resource` for the theme and set the root property:

```ini
[ext_resource type="Resource" path="res://Resources/Data/Themes/candy_sky_islands/theme_config.tres" id="18_candy"]

[node name="Main" type="Node3D"]
script = ExtResource("1_jkv2x")
theme_config = ExtResource("18_candy")
```

Keep existing resources and nodes intact.

- [ ] **Step 6: Run theme applier contract**

Run Step 2 command again.

Expected: PASS with `test_theme_applier_contract: PASS`.

## Task 4: Validation And Evidence

**Files:**
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Run all script tests**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-ChildItem "$project\tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: every test exits `0`.

- [ ] **Step 2: Run Godot import**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --import
```

Expected: exit code `0`, or stop and record Godot 4.6 requirement if 4.3 cannot import.

- [ ] **Step 3: Launch smoke run**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project
```

Expected manual smoke:
- Main scene loads.
- Player moves.
- Player jumps and double-jumps.
- Camera rotates and zooms.
- Coin pickup increments HUD.
- Falling platform behavior remains intact.
- Candy palette is visible in HUD/coins/cloud/trail.

- [ ] **Step 4: Capture screenshots**

Capture:
- Desktop gameplay before coin pickup.
- Desktop gameplay after coin pickup.
- HUD close-up after coin pickup.

Save screenshots under:

```text
docs/screenshots/candy_sky_islands_desktop_gameplay.png
docs/screenshots/candy_sky_islands_coin_pickup.png
docs/screenshots/candy_sky_islands_hud.png
```

- [ ] **Step 5: Update checklist evidence**

In `docs/reskin_checklist.md`, fill:

```markdown
Screenshot paths:
- Desktop: `docs/screenshots/candy_sky_islands_desktop_gameplay.png`
- Coin pickup: `docs/screenshots/candy_sky_islands_coin_pickup.png`
- HUD: `docs/screenshots/candy_sky_islands_hud.png`
```

Set validation results for script tests, Godot import, and smoke run.

- [ ] **Step 6: Final completion audit**

Check:
- Objective still says Candy Sky Islands.
- Checklist gates are not falsely checked.
- Paid generation remains unchecked unless owner approved it.
- Root Asset generation remains blocked unless owner approved it.
- No gameplay behavior was changed.
- Screenshots prove nonblank game visuals.

Expected: completion report can honestly list passed gates and remaining unapproved deeper asset-generation work.
