extends SceneTree

const BRICK_SCENE := "res://objects/brick.tscn"
const BRICK_SCRIPT := "res://objects/brick.gd"
const GOAL_SCENE := "res://objects/goal_flag.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const PROGRESSION_CONFIG := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const ROUTE_GENERATOR := "res://scripts/obby_route_generator.gd"
const THEME_APPLIER := "res://scripts/theme_applier.gd"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const PROOF := "res://docs/screenshots/candy_sky_islands_obstacle_goal_wrapper.png"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(BRICK_SCENE, "[node name=\"brick\" type=\"StaticBody3D\"]", "Brick root should remain StaticBody3D") and passed
	passed = _assert_file_contains(BRICK_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/brick_candy_wafer.glb\"", "Brick should use Candy wafer GLB after replacement gate") and passed
	passed = _assert_file_not_contains(BRICK_SCENE, "path=\"res://models/brick.glb\"", "Brick should not keep legacy brick GLB visual after replacement") and passed
	passed = _assert_file_contains(BRICK_SCENE, "path=\"res://objects/brick.gd\"", "Brick behavior script should remain") and passed
	passed = _assert_file_contains(BRICK_SCENE, "[node name=\"CollisionShape3D\" type=\"CollisionShape3D\" parent=\".\"]", "Brick collision should remain") and passed
	passed = _assert_file_contains(BRICK_SCENE, "[node name=\"BottomDetector\" type=\"Area3D\" parent=\".\"]", "Brick bottom detector should remain") and passed
	passed = _assert_file_contains(BRICK_SCENE, "[node name=\"Particles\" type=\"GPUParticles3D\" parent=\".\"]", "Brick break particles should remain") and passed
	passed = _assert_file_not_contains(BRICK_SCENE, "CandyWaferWrapper", "Brick should not keep old wrapper nodes after GLB replacement") and passed
	passed = _assert_file_contains(BRICK_SCRIPT, "Audio.play_event(\"break\")", "Brick SFX should stay routed through SSOT event") and passed
	passed = _assert_file_contains(BRICK_SCRIPT, "mesh.hide()", "Brick should hide legacy visual on break") and passed
	passed = _assert_file_not_contains(BRICK_SCRIPT, "wafer_wrapper", "Brick script should not reference removed wafer wrapper") and passed
	passed = _assert_file_contains(BRICK_SCRIPT, "$CollisionShape3D.set_deferred(\"disabled\", true)", "Brick collision disable should be deferred to avoid physics flush warnings") and passed

	passed = _assert_true(ResourceLoader.exists(GOAL_SCENE), "Goal wrapper scene should exist") and passed
	passed = _assert_file_contains(GOAL_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/goal_candy_pennant.glb\"", "Goal should use Candy pennant GLB after replacement gate") and passed
	passed = _assert_file_not_contains(GOAL_SCENE, "path=\"res://models/flag.glb\"", "Goal should not keep legacy flag GLB visual after replacement") and passed
	passed = _assert_file_not_contains(GOAL_SCENE, "CandyPennantWrapper", "Goal should not keep old wrapper nodes after GLB replacement") and passed
	passed = _assert_file_contains(MAIN_SCENE, "path=\"res://objects/goal_flag.tscn\"", "Main scene should instance goal wrapper scene") and passed
	passed = _assert_file_contains(MAIN_SCENE, "goal_scene = ExtResource", "World builder should receive goal scene reference") and passed
	passed = _assert_file_contains(PROGRESSION_CONFIG, "\"role\": \"goal\"", "Goal placement should live in data-owned stage segments") and passed
	passed = _assert_generated_environment_has_kind("brick", "Brick terrain placement should be generated from data-owned layout profile") and passed
	passed = _assert_file_contains(THEME_APPLIER, "_apply_obstacle_node", "Theme applier should preserve wafer wrapper color roles") and passed
	passed = _assert_file_contains(THEME_APPLIER, "_apply_goal_node", "Theme applier should preserve goal wrapper color roles") and passed
	passed = _assert_file_contains(THEME_APPLIER, "CreamStripe", "Theme applier should handle obstacle cream stripes") and passed
	passed = _assert_file_contains(THEME_APPLIER, "MintPole", "Theme applier should handle goal mint pole") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		passed = _assert_role(theme, "obstacle_brick_role", "res://objects/brick.tscn") and passed
		passed = _assert_role(theme, "goal_flag_role", "res://objects/goal_flag.tscn") and passed

	if passed:
		print("test_deep_obstacle_goal_wrapper_contract: PASS")
		quit(0)
	else:
		print("test_deep_obstacle_goal_wrapper_contract: FAIL")
		quit(1)

func _assert_generated_environment_has_kind(kind: String, message: String) -> bool:
	var config = load(PROGRESSION_CONFIG)
	var generator = load(ROUTE_GENERATOR)
	if config == null or generator == null:
		push_error("%s: missing config or route generator" % message)
		return false
	for level in config.level_catalog:
		if level == null:
			continue
		var profile: Dictionary = level.difficulty_profile()
		var route: Array = generator.build_stage_segments(profile)
		var environment: Array = generator.build_environment_segments(profile, route)
		for segment in environment:
			if String(Dictionary(segment).get("kind", "")) == kind:
				return true
	push_error("%s: generated environment missing kind %s" % [message, kind])
	return false

func _assert_role(theme: Resource, key: String, path: String) -> bool:
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
	if role.proof_path != PROOF:
		push_error("%s proof_path should be %s" % [key, PROOF])
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
