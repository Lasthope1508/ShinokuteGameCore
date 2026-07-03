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
			"output_dirs": [],
			"age": 0.08,
			"flow_mask": 8,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [],
			"age": 0.10,
			"flow_mask": 8,
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
		Vector2i(1, 0): theme.pipe_i_geometry,
		Vector2i(2, 0): theme.target_geometry,
		Vector2i(3, 0): theme.target_geometry
	}

	passed = passed and _assert_true(layer.has_method("get_target_pulses"), "PipeVfxLayer should expose target receive pulse data")
	passed = passed and _assert_true(_has_property(theme, "vfx_target_pulse_color"), "Theme should own target pulse color")
	passed = passed and _assert_true(_has_property(theme, "vfx_target_pulse_duration"), "Theme should own target pulse duration")
	passed = passed and _assert_true(_has_property(theme, "vfx_target_pulse_radius_ratio"), "Theme should own target pulse radius ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_target_pulse_ring_width_ratio"), "Theme should own target pulse ring width ratio")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)

	if layer.has_method("get_target_pulses"):
		var pulses: Array = layer.get_target_pulses()
		passed = passed and _assert_equal(pulses.size(), 1, "Only newly reached target should create receive pulse")
		if pulses.size() == 1:
			var pulse: Dictionary = pulses[0]
			passed = passed and _assert_equal(pulse.get("cell_pos", Vector2i(-1, -1)), Vector2i(2, 0), "Pulse should belong to target tile")
			passed = passed and _assert_vec2_close(pulse.get("position", Vector2.ZERO), Vector2(260.0, 69.21875), "Pulse position should use target energy center")
			passed = passed and _assert_equal(pulse.get("color", Color.BLACK), theme.vfx_target_pulse_color, "Pulse color should come from theme")
			passed = passed and _assert_true(float(pulse.get("radius", 0.0)) > 0.0, "Pulse radius should be positive")
			passed = passed and _assert_true(float(pulse.get("ring_width", 0.0)) > 0.0, "Pulse ring width should be positive")
			passed = passed and _assert_true(float(pulse.get("alpha", 0.0)) > 0.0 and float(pulse.get("alpha", 0.0)) <= 1.0, "Pulse alpha should be normalized")

	layer.free()

	if passed:
		print("test_pipe_vfx_target_pulse: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_target_pulse: FAIL")
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
