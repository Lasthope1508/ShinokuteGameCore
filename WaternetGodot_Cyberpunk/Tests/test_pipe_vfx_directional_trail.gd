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
			"age": 0.08,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [],
			"age": 0.08,
			"flow_mask": 8,
			"order": 2
		}
	}
	var geometries := {
		Vector2i(1, 0): theme.pipe_i_geometry,
		Vector2i(2, 0): theme.target_geometry
	}

	passed = passed and _assert_true(layer.has_method("get_directional_trails"), "PipeVfxLayer should expose directional trail data")
	passed = passed and _assert_true(_has_property(theme, "vfx_trail_color"), "Theme should own trail color")
	passed = passed and _assert_true(_has_property(theme, "vfx_trail_duration"), "Theme should own trail duration")
	passed = passed and _assert_true(_has_property(theme, "vfx_trail_width_ratio"), "Theme should own trail width ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_trail_min_alpha"), "Theme should own trail min alpha")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)

	if layer.has_method("get_directional_trails"):
		var trails: Array = layer.get_directional_trails()
		passed = passed and _assert_equal(trails.size(), 1, "Only tile with output direction should create directional trail")
		if trails.size() == 1:
			var trail: Dictionary = trails[0]
			passed = passed and _assert_equal(trail.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Trail should belong to flowing tile")
			passed = passed and _assert_equal(trail.get("input_dir", -1), 3, "Trail should remember input direction")
			passed = passed and _assert_equal(trail.get("output_dir", -1), 1, "Trail should remember output direction")
			passed = passed and _assert_equal(trail.get("color", Color.BLACK), theme.vfx_trail_color, "Trail color should come from theme")
			passed = passed and _assert_float_close(float(trail.get("width", 0.0)), 100.0 * theme.vfx_trail_width_ratio, "Trail width should scale from theme")
			passed = passed and _assert_true(float(trail.get("alpha", 0.0)) >= theme.vfx_trail_min_alpha and float(trail.get("alpha", 0.0)) <= 1.0, "Trail alpha should stay normalized")
			passed = passed and _assert_true(float(trail.get("progress", 0.0)) > 0.0 and float(trail.get("progress", 0.0)) <= 1.0, "Trail progress should derive from age")
			var points: Array = trail.get("points", [])
			passed = passed and _assert_equal(points.size(), 2, "Straight I trail should go input port -> output port")
			if points.size() == 2:
				passed = passed and _assert_vec2_close(points[0], Vector2(110, 70), "Trail should start at west input port")
				passed = passed and _assert_vec2_close(points[1], Vector2(210, 70), "Trail should end at east output port")

	layer.free()

	if passed:
		print("test_pipe_vfx_directional_trail: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_directional_trail: FAIL")
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

func _assert_float_close(actual: float, expected: float, message: String, epsilon: float = 0.01) -> bool:
	if abs(actual - expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.02) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
