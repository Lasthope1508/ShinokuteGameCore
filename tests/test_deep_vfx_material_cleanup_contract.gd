extends SceneTree

const PLAYER_SCENE := "res://objects/player.tscn"
const COIN_SCENE := "res://objects/coin.tscn"
const BRICK_SCENE := "res://objects/brick.tscn"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const CAPTURE_TOOL := "res://tools/capture_candy_sky_screenshots.gd"
const PROOF := "res://docs/screenshots/candy_sky_islands_vfx_material_cleanup.png"

func _init() -> void:
	var passed := true

	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"CandyTrailSparkle\" type=\"GPUParticles3D\" parent=\".\"]", "Player should add candy trail sparkle VFX") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "Material_CandyTrailSparkle", "Player trail sparkle should use local candy material") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "ParticleProcessMaterial_CandyTrailSparkle", "Player trail sparkle should use local candy process material") and passed
	passed = _assert_file_not_contains(PLAYER_SCENE, "res://meshes/dust.res", "Player particles should not pull legacy dust mesh into platform exports") and passed

	passed = _assert_file_contains(COIN_SCENE, "[node name=\"CandyPickupHalo\" type=\"MeshInstance3D\" parent=\".\"]", "Coin should add candy pickup halo") and passed
	passed = _assert_file_contains(COIN_SCENE, "Material_CandyPickupHalo", "Coin halo should use local candy material") and passed
	passed = _assert_file_contains(COIN_SCENE, "ParticleProcessMaterial_CandyPickup", "Coin pickup particles should use candy process material") and passed

	passed = _assert_file_contains(BRICK_SCENE, "Material_CandyCrumb", "Brick crumbs should use local candy material") and passed
	passed = _assert_file_contains(BRICK_SCENE, "ParticleProcessMaterial_CandyCrumb", "Brick crumbs should use candy process material") and passed
	passed = _assert_file_not_contains(BRICK_SCENE, "res://meshes/brick.res", "Brick particles should not pull legacy brick particle mesh into platform exports") and passed
	passed = _assert_file_not_contains(BRICK_SCENE, "material_override = ExtResource(\"3_2u2la\")", "Brick particles should no longer rely directly on shared colormap material") and passed

	passed = _assert_file_contains(CAPTURE_TOOL, "candy_sky_islands_vfx_material_cleanup.png", "Screenshot tool should capture VFX/material proof") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		passed = _assert_role(theme, "player_trail_mesh_role", "replacement", "res://objects/player.tscn") and passed
		passed = _assert_role(theme, "collectible_particle_role", "replacement", "res://objects/coin.tscn") and passed
		passed = _assert_role(theme, "obstacle_brick_particle_role", "replacement", "res://objects/brick.tscn") and passed
		passed = _assert_role(theme, "colormap_role", "unused_candidate", "") and passed
		var colormap_role = theme.get("colormap_role")
		if colormap_role != null:
			passed = _assert_true(String(colormap_role.notes).contains("no active production scene references"), "Colormap notes should record active scene cleanup") and passed

	if passed:
		print("test_deep_vfx_material_cleanup_contract: PASS")
		quit(0)
	else:
		print("test_deep_vfx_material_cleanup_contract: FAIL")
		quit(1)

func _assert_role(theme: Resource, key: String, mode: String, replacement_path: String) -> bool:
	var role = theme.get(key)
	if role == null:
		push_error("%s should exist" % key)
		return false
	if role.mode != mode:
		push_error("%s should be %s mode, got %s" % [key, mode, role.mode])
		return false
	if replacement_path != "" and role.replacement_path != replacement_path:
		push_error("%s replacement_path should be %s, got %s" % [key, replacement_path, role.replacement_path])
		return false
	if role.proof_path != PROOF:
		push_error("%s proof_path should be %s, got %s" % [key, PROOF, role.proof_path])
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
