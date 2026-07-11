extends SceneTree

const PLATFORM_SMALL := "res://objects/platform.tscn"
const PLATFORM_MEDIUM := "res://objects/platform_medium.tscn"
const PLATFORM_FALLING := "res://objects/platform_falling.tscn"
const PLATFORM_FALLING_SCRIPT := "res://objects/platform_falling.gd"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const PLATFORM_PROOF := "res://docs/screenshots/candy_sky_islands_platform_glb_replacement.png"

func _init() -> void:
	var passed := true
	passed = _assert_platform_scene(
		PLATFORM_SMALL,
		"res://models/platform.glb",
		"res://assets/themes/candy_sky_islands/models/platform_candy_small.glb",
		"platform2#StaticBody3D",
		"platform2_StaticBody3D#CollisionShape3D"
	) and passed
	passed = _assert_platform_scene(
		PLATFORM_MEDIUM,
		"res://models/platform-medium.glb",
		"res://assets/themes/candy_sky_islands/models/platform_candy_medium.glb",
		"platform-medium2#StaticBody3D",
		"platform-medium2_StaticBody3D#CollisionShape3D"
	) and passed
	passed = _assert_platform_scene(
		PLATFORM_FALLING,
		"res://models/platform-falling.glb",
		"res://assets/themes/candy_sky_islands/models/platform_candy_falling.glb",
		"platform-falling2#StaticBody3D",
		"platform-falling2_StaticBody3D#CollisionShape3D"
	) and passed
	passed = _assert_file_contains(PLATFORM_FALLING, "path=\"res://objects/platform_falling.gd\"", "Falling platform script should remain attached") and passed
	passed = _assert_file_contains(PLATFORM_FALLING, "[node name=\"Area3D\" type=\"Area3D\" parent=\".\" index=\"0\"]", "Falling trigger Area3D should remain") and passed
	passed = _assert_file_contains(PLATFORM_FALLING, "[connection signal=\"body_entered\" from=\"Area3D\" to=\".\" method=\"_on_body_entered\"]", "Falling trigger signal should remain") and passed
	passed = _assert_file_contains(PLATFORM_FALLING_SCRIPT, "Audio.play_event(\"fall\")", "Falling SFX should stay routed through SSOT event") and passed
	passed = _assert_file_contains(PLATFORM_FALLING_SCRIPT, "position.y -= fall_velocity * delta", "Falling motion should remain") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		for key in ["platform_small_role", "platform_medium_role", "platform_falling_role"]:
			var role = theme.get(key)
			passed = _assert_true(role != null, "%s should exist" % key) and passed
			if role != null:
				passed = _assert_true(role.mode == "replacement", "%s should be replacement mode after GLB gate" % key) and passed
				passed = _assert_true(role.proof_path == PLATFORM_PROOF, "%s should point at platform GLB screenshot proof" % key) and passed
				passed = _assert_true(role.notes.contains("Candy GLB"), "%s should document Candy GLB visual replacement" % key) and passed

	if passed:
		print("test_deep_platform_wrapper_contract: PASS")
		quit(0)
	else:
		print("test_deep_platform_wrapper_contract: FAIL")
		quit(1)

func _assert_platform_scene(path: String, legacy_model: String, candy_model: String, body_name: String, collision_name: String) -> bool:
	var passed := true
	passed = _assert_file_contains(path, "path=\"%s\"" % candy_model, "%s should use Candy GLB visual replacement" % path) and passed
	passed = _assert_file_not_contains(path, "path=\"%s\"" % legacy_model, "%s should not keep legacy platform GLB visual after replacement" % path) and passed
	passed = _assert_file_contains(path, "[node name=\"%s\" type=\"StaticBody3D\" parent=\".\"" % body_name, "%s should keep static body collider node" % path) and passed
	passed = _assert_file_contains(path, "[node name=\"%s\" type=\"CollisionShape3D\" parent=\"%s\"" % [collision_name, body_name], "%s should keep collision shape node" % path) and passed
	passed = _assert_file_not_contains(path, "CandyPlatformWrapper", "%s should not keep old wrapper nodes after GLB replacement" % path) and passed
	return passed

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
