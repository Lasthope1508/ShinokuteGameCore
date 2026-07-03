extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()
	var flow_state := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [1], "age": 2.0, "flow_mask": 2, "order": 0},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 1},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [], "age": 2.0, "flow_mask": 8, "order": 2}
	}
	var geometry_by_cell := {
		Vector2i(0, 0): theme.get_asset_geometry("source"),
		Vector2i(1, 0): theme.get_asset_geometry("I"),
		Vector2i(2, 0): theme.get_asset_geometry("target")
	}

	for property_name in [
		"vfx_energy_stream_enabled",
		"vfx_energy_stream_color",
		"vfx_energy_stream_period",
		"vfx_energy_stream_alpha",
		"vfx_energy_stream_width_ratio",
		"vfx_energy_stream_glow_width_ratio",
		"vfx_energy_stream_shimmer_width_ratio",
		"vfx_energy_stream_shimmer_segment_ratio",
		"vfx_energy_stream_pulse_alpha_ratio",
		"vfx_energy_stream_order_phase_offset",
		"vfx_energy_stream_max_effects"
	]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)
	passed = passed and _assert_true(layer.has_method("get_energy_streams"), "PipeVfxLayer should expose continuous energy stream data")

	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	if layer.has_method("get_energy_streams"):
		var early: Array = layer.get_energy_streams(0.0)
		var later: Array = layer.get_energy_streams(float(theme.get("vfx_energy_stream_period")) * 0.25)
		passed = passed and _assert_true(early.size() > 0, "Powered outputs should create continuous energy streams")
		passed = passed and _assert_true(early.size() <= int(theme.get("vfx_energy_stream_max_effects")), "Energy streams should respect theme cap")
		if early.size() > 0 and later.size() > 0:
			passed = passed and _assert_equal(early[0].get("color", Color.BLACK), theme.get("vfx_energy_stream_color"), "Stream color should come from theme")
			passed = passed and _assert_true(float(early[0].get("shimmer_head_progress", -1.0)) != float(later[0].get("shimmer_head_progress", -1.0)), "Stream shimmer should move over time")
			passed = passed and _assert_true(early[0].get("points", []).size() >= 2, "Stream should use canonical route points")
			passed = passed and _assert_true(float(early[0].get("glow_width", 0.0)) > float(early[0].get("core_width", 0.0)), "Stream glow should be wider than core")

	layer.free()
	if passed:
		print("test_pipe_vfx_energy_stream: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_energy_stream: FAIL")
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
