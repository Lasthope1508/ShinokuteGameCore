extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")
const GameScene = preload("res://Scenes/Gameplay/GameScene.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()
	var scene = GameScene.new()

	passed = passed and _assert_true(_has_property(theme, "energy_overlay_draw_enabled"), "Theme should own static energy overlay draw toggle")
	passed = passed and _assert_true(_has_property(theme, "vfx_trail_draw_enabled"), "Theme should own trail draw toggle")
	passed = passed and _assert_true(_has_property(theme, "vfx_path_wave_draw_enabled"), "Theme should own path wave draw toggle")
	if _has_property(theme, "energy_overlay_draw_enabled"):
		passed = passed and _assert_equal(theme.get("energy_overlay_draw_enabled"), false, "Cyber gameplay should hide static energy overlay by default")
	if _has_property(theme, "vfx_trail_draw_enabled"):
		passed = passed and _assert_equal(theme.get("vfx_trail_draw_enabled"), false, "Cyber gameplay should hide directional route trail line")
	if _has_property(theme, "vfx_path_wave_draw_enabled"):
		passed = passed and _assert_equal(theme.get("vfx_path_wave_draw_enabled"), true, "Cyber gameplay should keep moving path wave flow enabled")
	layer.apply_theme_config(theme, 100.0)
	if layer.get("trail_draw_enabled") != null:
		passed = passed and _assert_equal(layer.get("trail_draw_enabled"), false, "Layer should apply trail draw toggle")
	if layer.get("path_wave_draw_enabled") != null:
		passed = passed and _assert_equal(layer.get("path_wave_draw_enabled"), true, "Layer should apply path wave draw toggle")
	passed = passed and _assert_true(scene.has_method("_is_energy_overlay_draw_enabled"), "GameScene should expose energy overlay draw gate")
	if scene.has_method("_is_energy_overlay_draw_enabled"):
		passed = passed and _assert_equal(scene._is_energy_overlay_draw_enabled(theme), false, "GameScene should hide static energy overlay when theme disables it")

	scene.free()
	layer.free()
	if passed:
		print("test_vfx_route_line_visibility: PASS")
		quit(0)
	else:
		print("test_vfx_route_line_visibility: FAIL")
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
