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
			"age": 0.09,
			"flow_mask": 2,
			"order": 0
		},
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": -1,
			"output_dirs": [1],
			"age": 0.09,
			"flow_mask": 2,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": -1,
			"output_dirs": [1],
			"age": 2.0,
			"flow_mask": 2,
			"order": 2
		},
		Vector2i(3, 0): {
			"cell_pos": Vector2i(3, 0),
			"input_dir": -1,
			"output_dirs": [],
			"age": 2.0,
			"flow_mask": 0,
			"order": 0
		}
	}
	var geometries := {
		Vector2i(0, 0): theme.source_geometry,
		Vector2i(1, 0): theme.pipe_i_geometry,
		Vector2i(2, 0): theme.pipe_i_geometry,
		Vector2i(3, 0): theme.source_geometry
	}

	passed = passed and _assert_true(layer.has_method("get_source_emissions"), "PipeVfxLayer should expose source emission data")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_emission_color"), "Theme should own source emission color")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_emission_duration"), "Theme should own source emission duration")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_emission_radius_ratio"), "Theme should own source emission radius ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_emission_ring_width_ratio"), "Theme should own source emission ring width ratio")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_idle_enabled"), "Theme should own source idle enabled")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_idle_period"), "Theme should own source idle period")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_idle_alpha_min_ratio"), "Theme should own source idle alpha minimum")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_idle_alpha_pulse_ratio"), "Theme should own source idle alpha pulse")
	passed = passed and _assert_true(_has_property(theme, "vfx_source_idle_radius_pulse_ratio"), "Theme should own source idle radius pulse")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)

	if layer.has_method("get_source_emissions"):
		var emissions: Array = layer.get_source_emissions()
		passed = passed and _assert_equal(emissions.size(), 2, "Source should pulse when newly active and keep idling when blocked")
		if emissions.size() == 2:
			var emission: Dictionary = emissions[0]
			passed = passed and _assert_equal(emission.get("cell_pos", Vector2i(-1, -1)), Vector2i(0, 0), "Emission should belong to source tile")
			passed = passed and _assert_vec2_close(emission.get("position", Vector2.ZERO), Vector2(60, 70), "Emission position should use source energy center")
			passed = passed and _assert_equal(emission.get("output_dirs", []), [1], "Emission should preserve canonical output dirs")
			passed = passed and _assert_equal(emission.get("color", Color.BLACK), theme.vfx_source_emission_color, "Emission color should come from theme")
			passed = passed and _assert_true(float(emission.get("radius", 0.0)) > 0.0, "Emission radius should be positive")
			passed = passed and _assert_true(float(emission.get("ring_width", 0.0)) > 0.0, "Emission ring width should be positive")
			passed = passed and _assert_true(float(emission.get("alpha", 0.0)) > 0.0 and float(emission.get("alpha", 0.0)) <= 1.0, "Emission alpha should be normalized")
			var blocked_source: Dictionary = emissions[1]
			passed = passed and _assert_equal(blocked_source.get("cell_pos", Vector2i(-1, -1)), Vector2i(3, 0), "Blocked source should still emit local idle source pulse")
			passed = passed and _assert_vec2_close(blocked_source.get("position", Vector2.ZERO), Vector2(360, 70), "Blocked source emission should stay centered on source tile")
			passed = passed and _assert_equal(blocked_source.get("output_dirs", []), [], "Blocked source should preserve empty canonical output dirs")

	layer.free()

	if passed:
		print("test_pipe_vfx_source_emission: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_source_emission: FAIL")
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
