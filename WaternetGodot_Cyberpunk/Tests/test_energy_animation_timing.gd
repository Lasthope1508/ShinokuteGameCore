extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var scene = GameSceneScript.new()
	scene.active_theme_override = theme
	scene.flow_visual_state = {
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.0,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.166,
			"flow_mask": 10,
			"order": 2
		},
		Vector2i(3, 0): {
			"cell_pos": Vector2i(3, 0),
			"input_dir": 3,
			"output_dirs": [],
			"age": 5.0,
			"flow_mask": 8,
			"order": 3
		}
	}

	passed = passed and _assert_true(_has_property(theme, "energy_sheet_frame_count"), "Theme should own energy frame count")
	passed = passed and _assert_true(_has_property(theme, "energy_sheet_frame_size"), "Theme should own energy frame size")
	passed = passed and _assert_true(_has_property(theme, "energy_default_frame_duration"), "Theme should own default energy frame duration")
	passed = passed and _assert_true(_has_property(theme, "energy_frame_duration_by_asset_key"), "Theme should own per-asset energy frame durations")
	passed = passed and _assert_true(scene.has_method("_get_energy_frame_index_for_age"), "GameScene should expose age-based frame helper")

	if scene.has_method("_get_energy_frame_index_for_age"):
		passed = passed and _assert_equal(scene._get_energy_frame_index_for_age(0.0, "I"), 0, "Age 0 should use first frame")
		passed = passed and _assert_equal(scene._get_energy_frame_index_for_age(theme.energy_default_frame_duration * 3.1, "I"), 3, "Age should advance through configured frame duration")
		passed = passed and _assert_equal(scene._get_energy_frame_index_for_age(99.0, "I"), theme.energy_sheet_frame_count - 1, "Large age should clamp to final frame")

	passed = passed and _assert_equal(scene.callv("_get_energy_frame_index", [Vector2i(1, 0), true, "I"]), 0, "Watered tile frame should read FlowVisualState age")
	passed = passed and _assert_equal(scene.callv("_get_energy_frame_index", [Vector2i(2, 0), true, "I"]), 3, "Watered tile should advance by FlowVisualState age")
	passed = passed and _assert_equal(scene.callv("_get_energy_frame_index", [Vector2i(3, 0), true, "I"]), theme.energy_sheet_frame_count - 1, "Settled tile should clamp to final frame")
	passed = passed and _assert_equal(scene.callv("_get_energy_frame_index", [Vector2i(2, 0), false, "I"]), 0, "Dry tile should stay on frame 0")

	scene.free()

	if passed:
		print("test_energy_animation_timing: PASS")
		quit(0)
	else:
		print("test_energy_animation_timing: FAIL")
		quit(1)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
