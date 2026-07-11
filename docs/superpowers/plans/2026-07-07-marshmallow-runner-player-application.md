# Marshmallow Runner Player Application Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Marshmallow Runner player root asset direction to the existing 3D player safely without replacing the GLB rig.

**Architecture:** Keep the generated PNG as the approved visual reference and store all player skin tokens in `QuantumThemeConfig`. Extend `theme_applier.gd` to recolor current player mesh parts at runtime, preserving `objects/character.tscn`, `models/character.glb`, animation names, collision, movement, and camera behavior.

**Tech Stack:** Godot 4 GDScript, `.tres` resources, existing `Node3D`/`MeshInstance3D` scenes, PowerShell validation commands.

---

## File Structure

- Modify `Resources/QuantumThemeConfig.gd`: add owner-approved player root asset path and Marshmallow Runner material color tokens.
- Modify `Resources/Data/Themes/candy_sky_islands/theme_config.tres`: store generated root asset path and player material palette.
- Modify `scripts/theme_applier.gd`: add `_apply_player_materials()` that targets existing player mesh parts by node name.
- Modify `tests/test_candy_theme_config.gd`: assert root asset path and player material colors exist.
- Modify `tests/test_theme_applier_contract.gd`: assert player material application contract exists and no GLB replacement path is introduced.
- Modify `tools/capture_candy_sky_screenshots.gd`: save one focused player screenshot and assert player mesh material overrides exist after theme application.
- Modify `docs/asset_manifest.md` and `docs/reskin_checklist.md`: record application proof and validation evidence.

## Task 1: Player Theme Contract Tests

**Files:**
- Modify: `tests/test_candy_theme_config.gd`
- Modify: `tests/test_theme_applier_contract.gd`

- [ ] **Step 1: Extend `test_candy_theme_config.gd` with failing root asset assertions**

Add these assertions inside the `if theme != null:` block after the HUD assertions:

```gdscript
		passed = passed and _assert_equal(theme.player_root_asset_path, "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png", "Player root asset path should match approved concept")
		passed = passed and _assert_equal(theme.player_body_material_color.to_html(false), "fff2c7", "Player body should use cream marshmallow color")
		passed = passed and _assert_equal(theme.player_cap_material_color.to_html(false), "fff2c7", "Player cap should use whipped cream color")
		passed = passed and _assert_equal(theme.player_left_glove_material_color.to_html(false), "ff6f61", "Player left glove should use coral color")
		passed = passed and _assert_equal(theme.player_right_glove_material_color.to_html(false), "7be0ad", "Player right glove should use mint color")
```

- [ ] **Step 2: Extend `test_theme_applier_contract.gd` with failing player applier assertions**

Add these assertions after the existing `APPLIER` checks:

```gdscript
	passed = passed and _assert_file_contains(APPLIER, "func _apply_player_materials", "Theme applier should apply player materials")
	passed = passed and _assert_file_contains(APPLIER, "player_body_material_color", "Theme applier should use player body material token")
	passed = passed and _assert_file_contains(APPLIER, "player_root_asset_path", "Theme applier should keep root asset reference in contract")
	passed = passed and _assert_file_not_contains(MAIN_SCENE, "models/candy_sky_islands", "Main scene should not introduce unapproved GLB replacement")
```

- [ ] **Step 3: Run tests to verify RED**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_candy_theme_config.gd"
& $godot --headless --path $project --script "$project\tests\test_theme_applier_contract.gd"
```

Expected: both fail because `QuantumThemeConfig` and `theme_applier.gd` do not yet expose player material tokens/application.

## Task 2: Player Tokens In Theme SSOT

**Files:**
- Modify: `Resources/QuantumThemeConfig.gd`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

- [ ] **Step 1: Add player fields to `QuantumThemeConfig.gd`**

Insert this section after the HUD export group and before the World group:

```gdscript
@export_group("Player")
@export_file("*.png", "*.webp") var player_root_asset_path := "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png"
@export var player_body_material_color := Color("#FFF2C7")
@export var player_cap_material_color := Color("#FFF2C7")
@export var player_left_glove_material_color := Color("#FF6F61")
@export var player_right_glove_material_color := Color("#7BE0AD")
@export var player_left_boot_material_color := Color("#7BE0AD")
@export var player_right_boot_material_color := Color("#FF6F61")
@export var player_face_material_color := Color("#273043")
```

Update the validation path list:

```gdscript
	for path in [hud_coin_icon_path, hud_font_path, player_root_asset_path, skybox_path]:
```

- [ ] **Step 2: Add matching values to `theme_config.tres`**

Insert these properties after `hud_font_size = 48`:

```ini
player_root_asset_path = "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png"
player_body_material_color = Color(1, 0.94902, 0.780392, 1)
player_cap_material_color = Color(1, 0.94902, 0.780392, 1)
player_left_glove_material_color = Color(1, 0.435294, 0.380392, 1)
player_right_glove_material_color = Color(0.482353, 0.878431, 0.678431, 1)
player_left_boot_material_color = Color(0.482353, 0.878431, 0.678431, 1)
player_right_boot_material_color = Color(1, 0.435294, 0.380392, 1)
player_face_material_color = Color(0.152941, 0.188235, 0.262745, 1)
```

- [ ] **Step 3: Run theme config test to verify GREEN**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_candy_theme_config.gd"
```

Expected: `test_candy_theme_config: PASS`.

## Task 3: Runtime Player Material Application

**Files:**
- Modify: `scripts/theme_applier.gd`

- [ ] **Step 1: Call player material application from `apply_theme()`**

Change the top-level apply function to include player materials after HUD:

```gdscript
func apply_theme(root: Node, theme: QuantumThemeConfig) -> void:
	if root == null or theme == null:
		return
	_apply_hud(root, theme)
	_apply_player_materials(root, theme)
	_apply_player_trail(root, theme)
	_apply_world_materials(root, theme)
```

- [ ] **Step 2: Add player material helper functions**

Insert these functions before `_apply_player_trail()`:

```gdscript
func _apply_player_materials(root: Node, theme: QuantumThemeConfig) -> void:
	var player := root.get_node_or_null("Player")
	if player == null:
		return

	var character := player.get_node_or_null("Character")
	if character == null:
		return

	_apply_named_mesh_tree_color(character, ["torso"], theme.player_body_material_color)
	_apply_named_mesh_tree_color(character, ["antenna"], theme.player_cap_material_color)
	_apply_named_mesh_tree_color(character, ["arm-left"], theme.player_left_glove_material_color)
	_apply_named_mesh_tree_color(character, ["arm-right"], theme.player_right_glove_material_color)
	_apply_named_mesh_tree_color(character, ["leg-left"], theme.player_left_boot_material_color)
	_apply_named_mesh_tree_color(character, ["leg-right"], theme.player_right_boot_material_color)

func _apply_named_mesh_tree_color(root: Node, names: Array[String], color: Color) -> void:
	for descendant in _collect_mesh_instances(root):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var node_name := String(mesh.name)
		var parent_name := String(mesh.get_parent().name) if mesh.get_parent() != null else ""
		if names.has(node_name) or names.has(parent_name):
			var material := _duplicate_mesh_material(mesh)
			material.albedo_color = color
			material.roughness = 0.82
			material.metallic = 0.0
			mesh.set_surface_override_material(0, material)
```

- [ ] **Step 3: Keep root concept path contract explicit**

Add this no-op reference inside `_apply_player_materials()` after the `theme` null checks:

```gdscript
	if not ResourceLoader.exists(theme.player_root_asset_path):
		push_warning("Approved player root asset is missing: %s" % theme.player_root_asset_path)
```

- [ ] **Step 4: Run applier contract test to verify GREEN**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_theme_applier_contract.gd"
```

Expected: `test_theme_applier_contract: PASS`.

## Task 4: Player Screenshot And Smoke Evidence

**Files:**
- Modify: `tools/capture_candy_sky_screenshots.gd`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Add focused player screenshot output**

In `tools/capture_candy_sky_screenshots.gd`, after the desktop screenshot save, add:

```gdscript
	var player_saved: bool = await _save_viewport("candy_sky_islands_player_marshmallow_runner.png", Rect2i(420, 120, 440, 500))
	passed = passed and player_saved
```

- [ ] **Step 2: Add player material smoke assertion**

After the `player` variable is assigned, add:

```gdscript
	if player != null:
		var themed_mesh_count := 0
		for mesh in _collect_mesh_instances(player):
			if mesh.get_surface_override_material(0) != null:
				themed_mesh_count += 1
		passed = passed and _assert_true(themed_mesh_count > 0, "Player should have themed material overrides")
```

Add this helper near the other helpers:

```gdscript
func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes
```

- [ ] **Step 3: Run visible smoke capture**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project --script "$project\tools\capture_candy_sky_screenshots.gd"
```

Expected: `capture_candy_sky_screenshots: PASS` and `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png` exists and is nonblank.

- [ ] **Step 4: Update evidence docs**

In `docs/reskin_checklist.md`, add the player screenshot under screenshot paths:

```markdown
- Player: `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png`
```

In `docs/asset_manifest.md`, update the `player.scene` and `player.root_asset` rows so proof screenshot points to:

```text
res://docs/screenshots/candy_sky_islands_player_marshmallow_runner.png
```

## Task 5: Final Validation

**Files:**
- No production edits unless earlier verification fails.

- [ ] **Step 1: Run all GDScript tests and import**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-ChildItem "$project\tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& $godot --headless --path $project --import
```

Expected: all tests print `PASS`, import exits `0`. Existing invalid UID and Godot 3.x material remap warnings may remain.

- [ ] **Step 2: Run visible smoke one more time**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project --script "$project\tools\capture_candy_sky_screenshots.gd"
```

Expected: `capture_candy_sky_screenshots: PASS`.

- [ ] **Step 3: Check git diff hygiene**

Run:

```powershell
git diff --check
git status --short
```

Expected: `git diff --check` exits `0`. Status shows only intended reskin docs, theme resources, script/test/tool updates, generated root asset PNG, screenshots, `.gitignore`, and Godot `.import` metadata changes from validation.

## Self-Review

- Spec coverage: Root asset approval, SSOT ownership, runtime player application, screenshot evidence, and validation are covered.
- Placeholder scan: no placeholder work remains in this plan.
- Type consistency: all new theme fields use `QuantumThemeConfig` export properties and are referenced by the same names in tests and applier contract.
