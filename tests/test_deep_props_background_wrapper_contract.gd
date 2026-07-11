extends SceneTree

const CLOUD_SCENE := "res://objects/cloud.tscn"
const ROUND_PLATFORM_SCENE := "res://objects/platform_grass_large_round.tscn"
const ENVIRONMENT := "res://scenes/main-environment.tres"
const THEME_APPLIER := "res://scripts/theme_applier.gd"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const PROOF := "res://docs/screenshots/candy_sky_islands_props_background_wrapper.png"
const GLB_PROOF := "res://docs/screenshots/candy_sky_islands_props_background_glb_replacement.png"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(CLOUD_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb\"", "Cloud scene should use reference-derived volumetric Candy cloud GLB") and passed
	passed = _assert_file_contains(CLOUD_SCENE, "[node name=\"CloudModel\" parent=\".\" instance=", "Cloud scene should render a volumetric cloud model") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "type=\"Sprite3D\"", "Cloud scene should not keep flat Sprite3D after 3D parity fix") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/cloud_candy.glb\"", "Cloud scene should not use the primitive dummy cloud GLB") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "path=\"res://models/cloud.glb\"", "Cloud scene should not keep legacy cloud GLB visual after replacement") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "CandyCloudWrapper", "Cloud scene should not keep old wrapper nodes after GLB replacement") and passed
	passed = _assert_file_contains(CLOUD_SCENE, "script = ExtResource(\"2_hugjq\")", "Cloud root should keep cloud movement script") and passed
	passed = _assert_file_contains("res://AGENTS.md", "Do not use dummy primitive", "Reset guard should ban dummy primitive production replacements") and passed

	passed = _assert_file_contains(ROUND_PLATFORM_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/platform_candy_round_large.glb\"", "Round platform should use Candy GLB") and passed
	passed = _assert_file_contains(ROUND_PLATFORM_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/grass_candy.glb\"", "Round platform should use Candy grass GLB refs") and passed
	passed = _assert_file_contains(ROUND_PLATFORM_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/grass_candy_small.glb\"", "Round platform should use Candy small grass GLB refs") and passed
	passed = _assert_file_not_contains(ROUND_PLATFORM_SCENE, "path=\"res://models/platform-grass-large-round.glb\"", "Round platform should not keep legacy platform GLB visual after replacement") and passed
	passed = _assert_file_not_contains(ROUND_PLATFORM_SCENE, "path=\"res://models/grass.glb\"", "Round platform should not keep legacy grass GLB visual after replacement") and passed
	passed = _assert_file_not_contains(ROUND_PLATFORM_SCENE, "path=\"res://models/grass-small.glb\"", "Round platform should not keep legacy small grass GLB visual after replacement") and passed
	passed = _assert_file_contains(ROUND_PLATFORM_SCENE, "[node name=\"platform-grass-large-round2#StaticBody3D\" type=\"StaticBody3D\" parent=\".\"", "Round platform static body should remain") and passed
	passed = _assert_file_contains(ROUND_PLATFORM_SCENE, "[node name=\"platform-grass-large-round2_StaticBody3D#CollisionShape3D\" type=\"CollisionShape3D\" parent=\"platform-grass-large-round2#StaticBody3D\"", "Round platform collision shape should remain") and passed
	passed = _assert_file_not_contains(ROUND_PLATFORM_SCENE, "CandyRoundPlatformWrapper", "Round platform should not keep old wrapper nodes after GLB replacement") and passed

	passed = _assert_file_contains(ENVIRONMENT, "path=\"res://assets/themes/candy_sky_islands/sky_panel_islands.png\"", "Environment should route skybox texture to approved Candy Sky asset") and passed
	passed = _assert_file_not_contains(ENVIRONMENT, "path=\"res://sprites/skybox.png\"", "Environment should not point directly at old skybox texture after cleanup") and passed
	passed = _assert_file_contains(THEME_APPLIER, "_apply_cloud_node", "Theme applier should color cloud wrappers") and passed
	passed = _assert_file_contains(THEME_APPLIER, "MintSpark", "Theme applier should preserve cloud mint highlight") and passed
	passed = _assert_file_contains(THEME_APPLIER, "mesh_name.contains(\"grass\")", "Theme applier should preserve candy grass accent") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		passed = _assert_role(theme, "platform_round_role", "res://objects/platform_grass_large_round.tscn", GLB_PROOF, "Candy GLB") and passed
		passed = _assert_role(theme, "prop_cloud_role", "res://objects/cloud.tscn", GLB_PROOF, "reference-derived volumetric") and passed
		passed = _assert_role(theme, "prop_grass_role", "res://objects/platform_grass_large_round.tscn", GLB_PROOF, "Candy GLB") and passed
		passed = _assert_role(theme, "prop_grass_small_role", "res://objects/platform_grass_large_round.tscn", GLB_PROOF, "Candy GLB") and passed
		passed = _assert_role(theme, "skybox_role", "res://assets/themes/candy_sky_islands/sky_panel_islands.png", PROOF, "") and passed

	if passed:
		print("test_deep_props_background_wrapper_contract: PASS")
		quit(0)
	else:
		print("test_deep_props_background_wrapper_contract: FAIL")
		quit(1)

func _assert_role(theme: Resource, key: String, path: String, proof: String, note_fragment: String) -> bool:
	var role = theme.get(key)
	if role == null:
		push_error("%s should exist" % key)
		return false
	if role.mode != "replacement":
		push_error("%s should be replacement mode" % key)
		return false
	if role.replacement_path != path:
		push_error("%s replacement_path should be %s, got %s" % [key, path, role.replacement_path])
		return false
	if role.proof_path != proof:
		push_error("%s proof_path should be %s, got %s" % [key, proof, role.proof_path])
		return false
	if not note_fragment.is_empty() and not role.notes.contains(note_fragment):
		push_error("%s notes should include %s" % [key, note_fragment])
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
