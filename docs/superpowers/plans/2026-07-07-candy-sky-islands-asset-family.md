# Candy Sky Islands Asset Family Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved Candy Sky Islands Asset Family pass for collectibles, platforms, HUD, props/background, and visible obstacle/goal elements without changing gameplay.

**Architecture:** Keep the current GLB models, collisions, player controller, coin logic, camera, scoring, and falling-platform behavior. Use an approval-gated concept sheet as the visual source, extend `QuantumThemeConfig` with asset-family tokens, and apply safe material/HUD/background changes through `scripts/theme_applier.gd`. Track every accepted asset in `docs/asset_manifest.md`, `docs/reskin_checklist.md`, and `docs/reskin_state.md`.

**Tech Stack:** Godot 4 GDScript, `.tres` resources, PNG assets under `assets/themes/candy_sky_islands/`, PowerShell validation commands, existing smoke screenshot tool.

---

## File Structure

- Create `tests/test_asset_family_theme_contract.gd`: verifies asset-family SSOT tokens exist and preserve approved palette relationships.
- Create `tests/test_asset_family_manifest_contract.gd`: verifies concept sheet and asset-family rows are recorded before placement claims.
- Modify `Resources/QuantumThemeConfig.gd`: add asset-family paths and material tokens.
- Modify `Resources/Data/Themes/candy_sky_islands/theme_config.tres`: set Candy Sky Islands asset-family defaults.
- Modify `scripts/theme_applier.gd`: apply collectible, platform, cloud, obstacle, and goal material tokens through one runtime path.
- Create after owner generation approval: `assets/themes/candy_sky_islands/asset_family_concept_sheet.png`.
- Create after concept approval: `assets/themes/candy_sky_islands/hud_star_candy_icon.png` if the HUD icon is accepted for production use.
- Create after concept approval: `assets/themes/candy_sky_islands/skybox_candy_sky.png` if the skybox is accepted for production use.
- Modify `docs/asset_manifest.md`: record approved asset-family paths, source, status, in-game size, and proof screenshots.
- Modify `docs/reskin_checklist.md`: update Checkpoint 3 without claiming completion before validation.
- Modify `docs/reskin_state.md`: keep reset state aligned with the active gate.
- Modify `tools/capture_candy_sky_screenshots.gd`: add screenshot names only for newly applied groups.

## Task 1: Asset-Family SSOT Contract

**Files:**
- Create: `tests/test_asset_family_theme_contract.gd`
- Modify: `Resources/QuantumThemeConfig.gd`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

- [ ] **Step 1: Write the failing SSOT contract test**

Create `tests/test_asset_family_theme_contract.gd`:

```gdscript
extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		passed = passed and _assert_equal(theme.get("asset_family_concept_sheet_path"), "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png", "Concept sheet path should be explicit")
		passed = passed and _assert_color_html(theme.get("collectible_star_body_color"), "ff6f61", "Collectible body should use coral")
		passed = passed and _assert_color_html(theme.get("collectible_star_rim_color"), "7be0ad", "Collectible rim should use mint")
		passed = passed and _assert_color_html(theme.get("platform_top_material_color"), "fff2c7", "Platform top should use cream")
		passed = passed and _assert_color_html(theme.get("platform_edge_material_color"), "ff6f61", "Platform edge should use coral")
		passed = passed and _assert_color_html(theme.get("hud_score_frame_color"), "fff2c7", "HUD frame should use cream")
		passed = passed and _assert_color_html(theme.get("skybox_tint_color"), "79c7f2", "Skybox tint should use sky blue")
		passed = passed and _assert_color_html(theme.get("obstacle_wafer_material_color"), "ffb38c", "Obstacle wafer color should use warm candy wafer")
		passed = passed and _assert_color_html(theme.get("goal_pennant_material_color"), "7be0ad", "Goal pennant should use mint")
	if passed:
		print("test_asset_family_theme_contract: PASS")
		quit(0)
	else:
		print("test_asset_family_theme_contract: FAIL")
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

func _assert_color_html(actual, expected: String, message: String) -> bool:
	if not actual is Color:
		push_error("%s: expected Color %s, got %s" % [message, expected, str(actual)])
		return false
	return _assert_equal(actual.to_html(false), expected, message)
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_asset_family_theme_contract.gd"
```

Expected: FAIL because the asset-family fields do not exist yet.

- [ ] **Step 3: Extend `QuantumThemeConfig.gd`**

Add this block after the Player group and before the World group:

```gdscript
@export_group("Asset Family")
@export_file("*.png", "*.webp") var asset_family_concept_sheet_path := "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png"
@export_file("*.png", "*.webp") var hud_score_frame_path := ""
@export_file("*.png", "*.webp") var candy_skybox_path := ""
@export var collectible_star_body_color := Color("#FF6F61")
@export var collectible_star_rim_color := Color("#7BE0AD")
@export var platform_top_material_color := Color("#FFF2C7")
@export var platform_edge_material_color := Color("#FF6F61")
@export var hud_score_frame_color := Color("#FFF2C7")
@export var skybox_tint_color := Color("#79C7F2")
@export var obstacle_wafer_material_color := Color("#FFB38C")
@export var goal_pennant_material_color := Color("#7BE0AD")
@export var cloud_shadow_material_color := Color("#DDF5FF")
```

Update `validate()` so approval-stage asset-family paths remain allowed until those assets are generated and approved. Keep core runtime paths strict:

```gdscript
for path in [hud_coin_icon_path, hud_font_path, player_root_asset_path, skybox_path]:
	if path.strip_edges().is_empty():
		errors.append("asset path is empty")
	elif not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		errors.append("missing asset path: %s" % path)
```

Do not validate `asset_family_concept_sheet_path`, `hud_score_frame_path`, or `candy_skybox_path` here. Their existence is enforced by `tests/test_asset_family_manifest_contract.gd` after the relevant owner approval gates.

- [ ] **Step 4: Extend `theme_config.tres`**

Add these resource values after the player material values:

```ini
asset_family_concept_sheet_path = "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png"
hud_score_frame_path = ""
candy_skybox_path = ""
collectible_star_body_color = Color(1, 0.435294, 0.380392, 1)
collectible_star_rim_color = Color(0.482353, 0.878431, 0.678431, 1)
platform_top_material_color = Color(1, 0.94902, 0.780392, 1)
platform_edge_material_color = Color(1, 0.435294, 0.380392, 1)
hud_score_frame_color = Color(1, 0.94902, 0.780392, 1)
skybox_tint_color = Color(0.47451, 0.780392, 0.94902, 1)
obstacle_wafer_material_color = Color(1, 0.701961, 0.54902, 1)
goal_pennant_material_color = Color(0.482353, 0.878431, 0.678431, 1)
cloud_shadow_material_color = Color(0.866667, 0.960784, 1, 1)
```

- [ ] **Step 5: Run the SSOT contract test**

Run the command from Step 2.

Expected: PASS with `test_asset_family_theme_contract: PASS`.

## Task 2: Concept Sheet Approval And Asset Log

**Files:**
- Create after owner approval: `assets/themes/candy_sky_islands/asset_family_concept_sheet.png`
- Create: `tests/test_asset_family_manifest_contract.gd`
- Modify: `docs/asset_manifest.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`

- [ ] **Step 0: Resolve image generation key**

Use `NINEROUTER_IMAGE_URL=https://img.teelab247.com`.

Resolve auth key in this order, without printing secret values:

```powershell
$imageKey = $env:NINEROUTER_IMAGE_KEY
if (-not $imageKey) { $imageKey = $env:NINEROUTER_KEY }
if (-not $imageKey) { $imageKey = $env:ROUTER_API_KEY }
if (-not $imageKey) { throw 'No owner-approved 9Router image/system key found' }
```

Owner approved this system-key fallback on 2026-07-07 because prior source reskins use the shared system key.

- [ ] **Step 1: Request concept sheet generation approval**

Ask the owner exactly:

```text
Approve paid/AI image generation for one Candy Sky Islands Asset Family concept sheet at res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png?
```

Expected: continue only after the owner gives clear approval.

- [ ] **Step 2: Generate the concept sheet**

Use the image generation skill with this prompt:

```text
Create a bright casual toy-like 3D game asset family concept sheet for Candy Sky Islands, matching an approved Marshmallow Runner mascot style. White or very light sky background, clean readable mobile game shapes, no text labels, no logo, no UI instructions. Show: a coral star-candy collectible with mint rim sparkles, cream cake-cloud island platforms with coral candy edging and readable top faces, a compact HUD score icon/frame based on the star-candy collectible, soft white candy clouds and sky backdrop pieces, a candy wafer obstacle block, and a mint candy pennant goal flag. Use palette sky blue #79C7F2, cream #FFF2C7, coral #FF6F61, mint #7BE0AD, dark accent #273043. Orthographic-ish front/three-quarter product sheet view, separated assets, full asset visible, high clarity, polished 3D render style, 1024x1024 PNG.
```

Save the accepted output to:

```text
assets/themes/candy_sky_islands/asset_family_concept_sheet.png
```

Expected: PNG exists and is visually inspectable.

- [ ] **Step 3: Write the failing manifest contract test**

Create `tests/test_asset_family_manifest_contract.gd`:

```gdscript
extends SceneTree

const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const CONCEPT_SHEET := "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png"

func _init() -> void:
	var passed := true
	passed = passed and _assert_true(FileAccess.file_exists(CONCEPT_SHEET), "Asset family concept sheet should exist")
	passed = passed and _assert_file_contains(MANIFEST, "asset_family.concept_sheet", "Manifest should include concept sheet asset key")
	passed = passed and _assert_file_contains(MANIFEST, "collectible.star_candy", "Manifest should include collectible asset-family key")
	passed = passed and _assert_file_contains(MANIFEST, "platform.cake_cloud_kit", "Manifest should include platform kit key")
	passed = passed and _assert_file_contains(MANIFEST, "hud.star_candy.icon", "Manifest should include HUD icon key")
	passed = passed and _assert_file_contains(MANIFEST, "env.candy_skybox", "Manifest should include skybox key")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Concept sheet generated and visually inspected.", "Checklist should record concept sheet inspection")
	passed = passed and _assert_file_contains(STATE, "Asset Family concept sheet generated", "State should record concept sheet gate")
	if passed:
		print("test_asset_family_manifest_contract: PASS")
		quit(0)
	else:
		print("test_asset_family_manifest_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

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

- [ ] **Step 4: Run the manifest contract test and verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_asset_family_manifest_contract.gd"
```

Expected: FAIL until manifest, checklist, and state record the concept sheet gate.

- [ ] **Step 5: Update `docs/asset_manifest.md` Block Kit rows**

Add rows to the Block Kit table:

```markdown
| Asset family concept sheet | asset_family.concept_sheet | `res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png` | image generation after owner approval | generated, pending owner concept approval | N/A | N/A | 1024x1024 concept/reference PNG | none | Shows collectible, platform kit, HUD, props/background, obstacle, and goal style anchors |
| Star-candy collectible | collectible.star_candy | `res://objects/coin.tscn` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | existing scene plus theme tokens | planned safe material pass | N/A | N/A | current coin pickup scale | none | No GLB replacement in this pass |
| Cake/cloud platform kit | platform.cake_cloud_kit | `res://objects/platform*.tscn` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | existing scenes plus theme tokens | planned safe material pass | N/A | N/A | current platform scales | none | No collider or layout changes |
| Star-candy HUD icon | hud.star_candy.icon | `res://assets/themes/candy_sky_islands/hud_star_candy_icon.png` | generated after concept approval | blocked until concept approval | N/A | N/A | existing HUD icon rect | none | Production HUD icon only if owner approves it after concept sheet |
| Candy skybox | env.candy_skybox | `res://assets/themes/candy_sky_islands/skybox_candy_sky.png` | generated after concept approval | blocked until concept approval | N/A | N/A | world environment background | none | Production skybox only if owner approves it after concept sheet |
```

- [ ] **Step 6: Update checklist and state for concept sheet generation**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] Concept sheet generation approved before generation.
- [x] Concept sheet generated and visually inspected.
- [ ] Concept sheet owner approved.
```

In `docs/reskin_state.md`, set:

```markdown
## Current Gate

Asset Family concept sheet owner approval.
```

Add this completed asset line:

```markdown
- Asset Family concept sheet generated: `assets/themes/candy_sky_islands/asset_family_concept_sheet.png`.
```

- [ ] **Step 7: Run the manifest contract test**

Run the command from Step 4.

Expected: PASS with `test_asset_family_manifest_contract: PASS`.

## Task 3: Safe Material Application Pass

**Files:**
- Modify: `scripts/theme_applier.gd`
- Modify: `tests/test_theme_applier_contract.gd`
- Modify: `tests/test_asset_family_theme_contract.gd`

- [ ] **Step 1: Extend the theme applier contract test**

Add these assertions to `tests/test_theme_applier_contract.gd`:

```gdscript
passed = passed and _assert_file_contains(APPLIER, "collectible_star_body_color", "Theme applier should use collectible star body token")
passed = passed and _assert_file_contains(APPLIER, "platform_top_material_color", "Theme applier should use platform top token")
passed = passed and _assert_file_contains(APPLIER, "platform_edge_material_color", "Theme applier should use platform edge token")
passed = passed and _assert_file_contains(APPLIER, "obstacle_wafer_material_color", "Theme applier should use obstacle wafer token")
passed = passed and _assert_file_contains(APPLIER, "goal_pennant_material_color", "Theme applier should use goal pennant token")
```

- [ ] **Step 2: Run the contract test and verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_theme_applier_contract.gd"
```

Expected: FAIL because the applier has not used the new asset-family tokens.

- [ ] **Step 3: Update `scripts/theme_applier.gd` world material routing**

Replace `_apply_world_materials` with:

```gdscript
func _apply_world_materials(root: Node, theme: QuantumThemeConfig) -> void:
	var world := root.get_node_or_null("World")
	if world == null:
		return

	for child in world.get_children():
		var child_name := String(child.name)
		if child_name.begins_with("coin"):
			_apply_coin_node(child, theme)
		elif child_name.begins_with("cube"):
			_apply_cloud_node(child, theme)
		elif child_name.begins_with("platform"):
			_apply_platform_node(child, theme)
		elif child_name.begins_with("brick"):
			_apply_mesh_tree_color(child, theme.obstacle_wafer_material_color)
		elif child_name.begins_with("flag"):
			_apply_mesh_tree_color(child, theme.goal_pennant_material_color)
```

Replace `_apply_coin_node` with:

```gdscript
func _apply_coin_node(node: Node, theme: QuantumThemeConfig) -> void:
	_apply_mesh_tree_color(node, theme.collectible_star_body_color, true, theme.collectible_star_rim_color)

	var particles := node.get_node_or_null("Particles") as GPUParticles3D
	if particles == null:
		return
	var process_material := particles.process_material as ParticleProcessMaterial
	if process_material != null:
		var themed_process := process_material.duplicate() as ParticleProcessMaterial
		themed_process.color = theme.collectible_star_rim_color
		particles.process_material = themed_process
```

Add these helpers before `_apply_mesh_tree_color`:

```gdscript
func _apply_cloud_node(node: Node, theme: QuantumThemeConfig) -> void:
	_apply_mesh_tree_color(node, theme.cloud_material_color)
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var material := _duplicate_mesh_material(mesh)
		material.albedo_color = theme.cloud_material_color
		material.emission_enabled = true
		material.emission = theme.cloud_shadow_material_color
		material.emission_energy_multiplier = 0.04
		mesh.set_surface_override_material(0, material)

func _apply_platform_node(node: Node, theme: QuantumThemeConfig) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var material := _duplicate_mesh_material(mesh)
		var node_name := String(mesh.name).to_lower()
		var parent_name := String(mesh.get_parent().name).to_lower() if mesh.get_parent() != null else ""
		if node_name.contains("edge") or parent_name.contains("edge"):
			material.albedo_color = theme.platform_edge_material_color
		else:
			material.albedo_color = theme.platform_top_material_color
		material.roughness = 0.86
		material.metallic = 0.0
		mesh.set_surface_override_material(0, material)
```

- [ ] **Step 4: Run the applier contract test**

Run the command from Step 2.

Expected: PASS with `test_theme_applier_contract: PASS`.

## Task 4: Production HUD And Skybox Extraction Gate

**Files:**
- Create after owner approval: `assets/themes/candy_sky_islands/source/hud_star_candy_icon_crop.png`
- Create after owner approval: `assets/themes/candy_sky_islands/source/skybox_candy_sky_crop.png`
- Create after owner approval: `assets/themes/candy_sky_islands/hud_star_candy_icon_photoroom.png`
- Create after owner approval: `assets/themes/candy_sky_islands/skybox_candy_sky_photoroom.png`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Ask owner which approved concept parts become production PNGs**

Ask the owner exactly:

```text
Concept sheet approved. Extract production PNGs by running Photoroom on the full sheet first, then cloning/cutting objects from the Photoroom alpha sheet. Options: A: HUD icon only. B: HUD icon + skybox/background panel. C: skip production PNG extraction and do material-only pass.
```

Expected: choose A, B, or C before creating production PNGs.

- [ ] **Step 2A: If owner chooses A, run Photoroom on the full sheet, then clone/crop HUD icon from the alpha sheet**

Do not generate a new icon. Crop the approved sheet region around the star-candy HUD icon into:

```powershell
assets/themes/candy_sky_islands/source/hud_star_candy_icon_crop.png
```

First run Photoroom CDP through Chrome debugging port 9223 on the full approved concept sheet. Then clone/crop the approved object region from that Photoroom alpha sheet:

```powershell
$env:PHOTOROOM_TURNSTILE_TIMEOUT_MS = '60000'
node C:\Users\Admin\.codex\skills\photoroom-cdp-background-removal\scripts\photoroom_cdp_fetch_segment.js `
  9223 `
  "C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\assets\themes\candy_sky_islands\source\hud_star_candy_icon_crop.png" `
  "C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\assets\themes\candy_sky_islands\hud_star_candy_icon_photoroom.png"
```

Verify PNG mode is RGBA and alpha extrema include `0` and `255`.

Update `theme_config.tres`:

```ini
hud_coin_icon_path = "res://assets/themes/candy_sky_islands/hud_star_candy_icon_photoroom.png"
```

- [ ] **Step 2B: If owner chooses B, extract HUD icon and skybox/background panel**

Extract HUD icon with Step 2A. Crop the approved sheet region around the sky/background panel into:

```powershell
assets/themes/candy_sky_islands/source/skybox_candy_sky_crop.png
```

First run Photoroom CDP through Chrome debugging port 9223 on the full approved concept sheet. Then clone/crop approved object regions from that Photoroom alpha sheet:

```powershell
$env:PHOTOROOM_TURNSTILE_TIMEOUT_MS = '60000'
node C:\Users\Admin\.codex\skills\photoroom-cdp-background-removal\scripts\photoroom_cdp_fetch_segment.js `
  9223 `
  "C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\assets\themes\candy_sky_islands\source\skybox_candy_sky_crop.png" `
  "C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\assets\themes\candy_sky_islands\skybox_candy_sky_photoroom.png"
```

Verify PNG mode is RGBA and alpha extrema include `0` and `255`. If the skybox is meant to remain opaque, record that exception in the manifest and do not claim alpha-cutout quality for that asset.

Update `theme_config.tres`:

```ini
hud_coin_icon_path = "res://assets/themes/candy_sky_islands/hud_star_candy_icon_photoroom.png"
candy_skybox_path = "res://assets/themes/candy_sky_islands/skybox_candy_sky_photoroom.png"
skybox_path = "res://assets/themes/candy_sky_islands/skybox_candy_sky_photoroom.png"
```

- [ ] **Step 2C: If owner chooses C, keep production image paths unchanged**

Keep:

```ini
hud_coin_icon_path = "res://sprites/coin.png"
candy_skybox_path = ""
skybox_path = "res://sprites/skybox.png"
```

Expected: material-only pass remains valid.

- [ ] **Step 3: Update manifest rows for chosen production PNGs**

For each extracted production PNG, change status from blocked to Photoroom cutout, owner-approved, and record source as Photoroom full-sheet output on port 9223 plus owner-approved clone/cut region from the Photoroom alpha sheet.

Expected: no production PNG is marked accepted unless owner selected it, Photoroom succeeded, and alpha/edge QA passed.

## Task 5: Screenshot Tool And Evidence

**Files:**
- Modify: `tools/capture_candy_sky_screenshots.gd`
- Modify: `docs/asset_manifest.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`

- [ ] **Step 1: Add asset-family screenshot capture names**

In `tools/capture_candy_sky_screenshots.gd`, after the desktop screenshot save, add:

```gdscript
var asset_family_saved: bool = await _save_viewport("candy_sky_islands_asset_family_gameplay.png", Rect2i())
passed = passed and asset_family_saved
```

After the HUD screenshot save, add:

```gdscript
var asset_family_hud_saved: bool = await _save_viewport("candy_sky_islands_asset_family_hud.png", Rect2i(0, 0, 480, 180))
passed = passed and asset_family_hud_saved
```

- [ ] **Step 2: Update manifest proof screenshot paths**

Set proof screenshots:

```markdown
collectible.star_candy proof: `res://docs/screenshots/candy_sky_islands_coin_pickup.png`
platform.cake_cloud_kit proof: `res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png`
hud.star_candy.icon proof: `res://docs/screenshots/candy_sky_islands_asset_family_hud.png`
env.candy_skybox proof: `res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png`
```

For production PNGs not selected in Task 4, keep their status blocked and proof screenshot `none`.

- [ ] **Step 3: Update checklist and state for applied groups**

In `docs/reskin_checklist.md`, set only the groups that were actually applied:

```markdown
- [x] Collectible asset pass applied and screenshot captured.
- [x] Platform kit pass applied and screenshot captured.
- [x] HUD icon/frame pass applied and screenshot captured.
- [x] Props/background pass applied and screenshot captured.
```

If owner selected material-only pass, keep HUD icon/frame and skybox production rows unchecked and note material-only HUD/background proof in the state file.

Update `docs/reskin_state.md`:

```markdown
## Current Gate

Asset Family validation.
```

Add evidence lines for:

```markdown
- Asset Family gameplay screenshot: `docs/screenshots/candy_sky_islands_asset_family_gameplay.png`.
- Asset Family HUD screenshot: `docs/screenshots/candy_sky_islands_asset_family_hud.png`.
```

## Task 6: Validation

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

Expected: every `test_*.gd` exits `0`, including:

```text
test_asset_family_theme_contract: PASS
test_asset_family_manifest_contract: PASS
test_candy_theme_config: PASS
test_reskin_static_contract: PASS
test_theme_applier_contract: PASS
```

- [ ] **Step 2: Run Godot import**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --import
```

Expected: exit code `0`. Record existing invalid UID/material remap warnings as warnings, not blockers, if the exit code remains `0`.

- [ ] **Step 3: Run visible smoke screenshot capture**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project --script "$project\tools\capture_candy_sky_screenshots.gd"
```

Expected: `capture_candy_sky_screenshots: PASS` and nonblank PNGs under `docs/screenshots/`.

- [ ] **Step 4: Run whitespace diff check**

Run:

```powershell
git diff --check
```

Expected: no output and exit code `0`.

- [ ] **Step 5: Update validation evidence**

In `docs/reskin_checklist.md`, append the validation result with exact command names, date `2026-07-07`, and pass/fail result.

In `docs/reskin_state.md`, set:

```markdown
## Current Gate

Asset Family complete pending owner review.
```

Only use the word complete after all commands in this task pass.

## Task 7: Final Audit

**Files:**
- Read: `AGENTS.md`
- Read: `docs/reskin_state.md`
- Read: `docs/reskin_checklist.md`
- Read: `docs/asset_manifest.md`
- Read: `docs/superpowers/specs/2026-07-07-candy-sky-islands-asset-family-design.md`

- [ ] **Step 1: Re-read reset guard files**

Run:

```powershell
Get-Content -Raw 'AGENTS.md'
Get-Content -Raw 'docs\reskin_state.md'
Get-Content -Raw 'docs\reskin_checklist.md'
Get-Content -Raw 'docs\asset_manifest.md'
Get-Content -Raw 'docs\superpowers\specs\2026-07-07-candy-sky-islands-asset-family-design.md'
git status --short
```

Expected: state, checklist, and manifest agree on current gate and no unapproved asset group is marked accepted.

- [ ] **Step 2: Confirm no gameplay behavior changed**

Run:

```powershell
git diff -- scripts/player.gd scripts/camera.gd scripts/coin.gd objects/platform_falling.tscn objects/coin.tscn objects/player.tscn
```

Expected: no gameplay logic changes. If scene/import metadata appears, verify it is import metadata or skin data only before reporting.

- [ ] **Step 3: Report result**

Report:

```text
Current gate:
Completed assets:
Pending assets:
Validation commands run:
Screenshots:
Known warnings:
```

Expected: report does not call the whole reskin finished if splash/icon/logo or publish scope remains unapproved.
