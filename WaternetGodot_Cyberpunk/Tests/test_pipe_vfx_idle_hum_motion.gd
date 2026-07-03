extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()
	var flow_state := {
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 3.0,
			"flow_mask": 10,
			"order": 1
		}
	}
	var geometries := {Vector2i(1, 0): theme.get_asset_geometry("I")}

	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_period"), "Theme should own idle hum period")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_radius_pulse_ratio"), "Theme should own idle hum radius pulse")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_alpha_pulse_ratio"), "Theme should own idle hum alpha pulse")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	if layer.has_method("get_idle_hums") and _has_property(theme, "vfx_idle_hum_period"):
		var early: Array = layer.get_idle_hums(0.0)
		var later: Array = layer.get_idle_hums(theme.vfx_idle_hum_period * 0.25)
		passed = passed and _assert_equal(early.size(), 1, "Settled pipe should expose idle hum")
		passed = passed and _assert_equal(later.size(), 1, "Settled pipe should keep idle hum")
		if early.size() == 1 and later.size() == 1:
			var radius_changed: bool = abs(float(early[0].get("radius", 0.0)) - float(later[0].get("radius", 0.0))) > 0.01
			var alpha_changed: bool = abs(float(early[0].get("alpha", 0.0)) - float(later[0].get("alpha", 0.0))) > 0.01
			passed = passed and _assert_true(radius_changed or alpha_changed, "Idle hum should visibly move over time")
		if layer.has_method("has_active_motion"):
			passed = passed and _assert_true(layer.has_active_motion(0.0), "Animated idle hum should keep runtime redraw active")

	layer.free()
	if passed:
		print("test_pipe_vfx_idle_hum_motion: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_idle_hum_motion: FAIL")
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
