extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var scene = GameSceneScript.new()
	scene.active_theme_override = theme

	passed = passed and _assert_true(_has_property(theme, "energy_sheet_root"), "Theme should own canonical energy sheet root")
	passed = passed and _assert_true(_has_property(theme, "energy_texture_prefix"), "Theme should own canonical texture prefix")
	passed = passed and _assert_true(scene.has_method("_get_energy_sheet_path_for_texture"), "GameScene should expose energy sheet path lookup")
	passed = passed and _assert_true(scene.has_method("_get_energy_texture_for_draw"), "GameScene should expose full energy texture helper")

	var canonical_l_path := scene._get_energy_sheet_path_for_texture(theme.l_slices[1].texture.resource_path)
	passed = passed and _assert_equal(canonical_l_path, theme.energy_sheet_root + "/l_slices/l_slice_1_sheet.png", "L energy sheet should use canonical root only")
	passed = passed and _assert_true(not canonical_l_path.contains("energy_sheets_ai"), "Energy sheet lookup should not use AI fallback root")

	var missing_image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var missing_texture := ImageTexture.create_from_image(missing_image)
	missing_texture.resource_path = theme.energy_texture_prefix + "missing_pipe.png"
	var missing_energy = scene.callv("_get_energy_texture_for_draw", [missing_texture, Vector2i(4, 4), true, "I"])
	passed = passed and _assert_equal(missing_energy, null, "Missing energy sheet should return null instead of falling back to base texture")

	scene.free()

	if passed:
		print("test_energy_sheet_no_fallback: PASS")
		quit(0)
	else:
		print("test_energy_sheet_no_fallback: FAIL")
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
