extends SceneTree

const PLAYER_CORE := "res://addons/shinokute_game_core/controllers/character_3d_controller.gd"
const CAMERA_CORE := "res://addons/shinokute_game_core/controllers/follow_camera_3d.gd"
const TOUCH_CORE := "res://addons/shinokute_game_core/controllers/mobile_touch_controls_3d.gd"
const PLAYER_WRAPPER := "res://scripts/player.gd"
const CAMERA_WRAPPER := "res://scripts/view.gd"
const TOUCH_WRAPPER := "res://scripts/candy_mobile_touch_controls.gd"
const EXPORT_PRESETS := "res://export_presets.cfg"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	for path in [PLAYER_CORE, CAMERA_CORE, TOUCH_CORE]:
		passed = _assert_true(ResourceLoader.exists(path), "Shinokute core should own 3D controller module %s" % path) and passed
		var source := FileAccess.get_file_as_string(path)
		for forbidden in [
			"CandyGameCore",
			"candySky",
			"candy-touch",
			"__candy",
			"Candy Sky"
		]:
			passed = _assert_not_contains(source, forbidden, "Shinokute core controller %s must not hardcode Candy game boundary names" % path) and passed

	if passed:
		var player = load(PLAYER_CORE).new()
		var camera = load(CAMERA_CORE).new()
		var touch = load(TOUCH_CORE).new()
		passed = _assert_true(player is CharacterBody3D, "Core character controller should be a CharacterBody3D") and passed
		passed = _assert_true(camera is Node3D, "Core follow camera should be a Node3D") and passed
		passed = _assert_true(touch is Control, "Core mobile touch controls should be a Control") and passed
		for method in [
			"reset_for_level",
			"apply_shift_lock_look_delta_degrees",
			"apply_progression_profile"
		]:
			passed = _assert_true(player.has_method(method), "Core character controller missing %s" % method) and passed
		for method in [
			"set_shift_lock_enabled",
			"is_os_mouse_capture_active",
			"get_last_mouse_capture_center_position",
			"handle_input"
		]:
			passed = _assert_true(camera.has_method(method), "Core follow camera missing %s" % method) and passed
		for method in [
			"configure",
			"set_touch_controls_visible",
			"get_move_stick_rect",
			"get_move_guard_rect",
			"get_jump_button_rect",
			"get_jump_guard_rect",
			"get_look_area_rect",
			"handle_web_pointer_event"
		]:
			passed = _assert_true(touch.has_method(method), "Core mobile touch controls missing %s" % method) and passed
		player.free()
		camera.free()
		touch.free()

	var player_wrapper := FileAccess.get_file_as_string(PLAYER_WRAPPER)
	var camera_wrapper := FileAccess.get_file_as_string(CAMERA_WRAPPER)
	var touch_wrapper := FileAccess.get_file_as_string(TOUCH_WRAPPER)
	passed = _assert_contains(player_wrapper, PLAYER_CORE, "Candy player script should inherit Shinokute core character controller") and passed
	passed = _assert_contains(camera_wrapper, CAMERA_CORE, "Candy view script should inherit Shinokute core follow camera") and passed
	passed = _assert_contains(touch_wrapper, TOUCH_CORE, "Candy mobile controls should inherit Shinokute core mobile touch controls") and passed
	passed = _assert_not_contains(player_wrapper, "extends CharacterBody3D", "Candy player wrapper should not own controller base directly") and passed
	passed = _assert_not_contains(camera_wrapper, "extends Node3D", "Candy view wrapper should not own camera base directly") and passed
	passed = _assert_not_contains(touch_wrapper, "extends Control", "Candy touch wrapper should not own touch base directly") and passed

	var export_text := FileAccess.get_file_as_string(EXPORT_PRESETS)
	for path in [PLAYER_CORE, CAMERA_CORE, TOUCH_CORE]:
		passed = _assert_contains(export_text, path, "Web export selected resources should include core controller %s" % path) and passed

	_finish(passed)

func _assert_contains(text: String, needle: String, message: String) -> bool:
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_not_contains(text: String, needle: String, message: String) -> bool:
	if text.contains(needle):
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_shinokute_3d_controller_core_contract: PASS")
		quit(0)
	else:
		print("test_shinokute_3d_controller_core_contract: FAIL")
		quit(1)
