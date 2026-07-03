extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()
	var flow_state := {
		Vector2i(0, 0): {
			"cell_pos": Vector2i(0, 0),
			"input_dir": -1,
			"output_dirs": [1],
			"age": 2.2,
			"flow_mask": 2,
			"order": 0
		},
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 1.9,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.12,
			"flow_mask": 10,
			"order": 2
		},
		Vector2i(3, 0): {
			"cell_pos": Vector2i(3, 0),
			"input_dir": 3,
			"output_dirs": [],
			"age": 2.0,
			"flow_mask": 8,
			"order": 3
		}
	}
	var geometries := {
		Vector2i(0, 0): theme.source_geometry,
		Vector2i(1, 0): theme.pipe_i_geometry,
		Vector2i(2, 0): theme.pipe_i_geometry,
		Vector2i(3, 0): theme.target_geometry
	}

	passed = passed and _assert_true(layer.has_method("get_idle_hums"), "PipeVfxLayer should expose idle hum data")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_color"), "Theme should own idle hum color")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_delay"), "Theme should own idle hum delay")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_alpha"), "Theme should own idle hum alpha")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_width_ratio"), "Theme should own idle hum width ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_glow_width_ratio"), "Theme should own idle hum glow width ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_core_width_ratio"), "Theme should own idle hum core width ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_radius_ratio"), "Theme should own idle hum radius ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_period"), "Theme should own idle hum period")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_radius_pulse_ratio"), "Theme should own idle hum radius pulse")
	passed = passed and _assert_true(_has_property(theme, "vfx_idle_hum_alpha_pulse_ratio"), "Theme should own idle hum alpha pulse")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)

	if layer.has_method("get_idle_hums"):
		var hums: Array = layer.get_idle_hums()
		passed = passed and _assert_equal(hums.size(), 1, "Only old watered non-source/non-target pipe cells should idle hum")
		if hums.size() == 1:
			var hum: Dictionary = hums[0]
			passed = passed and _assert_equal(hum.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Hum should belong to settled pipe tile")
			passed = passed and _assert_equal(hum.get("input_dir", -99), 3, "Hum should preserve input direction")
			passed = passed and _assert_equal(hum.get("output_dir", -99), 1, "Hum should preserve output direction")
			passed = passed and _assert_equal(hum.get("flow_mask", 0), 10, "Hum should preserve canonical flow mask")
			passed = passed and _assert_equal(hum.get("color", Color.BLACK), theme.vfx_idle_hum_color, "Hum color should come from theme")
			var points: Array = hum.get("points", [])
			passed = passed and _assert_equal(points.size(), 2, "Straight pipe aura should follow input port -> output port")
			if points.size() == 2:
				passed = passed and _assert_vec2_close(points[0], Vector2(110.0, 70.0), "Aura should start at west port")
				passed = passed and _assert_vec2_close(points[1], Vector2(210.0, 70.0), "Aura should end at east port")
			passed = passed and _assert_true(not hum.has("radius"), "Hum should not draw radar-circle radius anymore")
			passed = passed and _assert_true(float(hum.get("core_width", 0.0)) > 0.0, "Hum core width should be positive")
			passed = passed and _assert_true(float(hum.get("glow_width", 0.0)) > float(hum.get("core_width", 0.0)), "Hum glow should be wider than core")
			passed = passed and _assert_true(float(hum.get("alpha", 0.0)) > 0.0 and float(hum.get("alpha", 0.0)) <= 1.0, "Hum alpha should stay normalized")

	layer.free()

	if passed:
		print("test_pipe_vfx_idle_hum: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_idle_hum: FAIL")
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

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.02) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_float_close(actual: float, expected: float, message: String, epsilon: float = 0.01) -> bool:
	if abs(actual - expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
