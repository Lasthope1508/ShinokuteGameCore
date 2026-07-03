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

	passed = passed and _assert_true(layer.has_method("set_win_state"), "PipeVfxLayer should accept win state")
	passed = passed and _assert_true(layer.has_method("get_win_bursts"), "PipeVfxLayer should expose win burst data")
	for property_name in ["vfx_win_burst_color", "vfx_win_burst_duration", "vfx_win_burst_radius_ratio", "vfx_win_burst_ring_width_ratio", "vfx_win_burst_max_cells"]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)

	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	if layer.has_method("set_win_state") and layer.has_method("get_win_bursts"):
		layer.set_win_state({"event_time": 4.0})
		var bursts: Array = layer.get_win_bursts(4.1)
		passed = passed and _assert_true(bursts.size() > 0, "Win state should create bursts on powered path")
		passed = passed and _assert_true(bursts.size() <= int(theme.get("vfx_win_burst_max_cells")), "Win bursts should respect theme cap")
		if bursts.size() > 0:
			passed = passed and _assert_equal(bursts[0].get("color", Color.BLACK), theme.get("vfx_win_burst_color"), "Win burst color should come from theme")
			passed = passed and _assert_true(float(bursts[0].get("alpha", 0.0)) > 0.0, "Win burst alpha should be positive during duration")
		passed = passed and _assert_equal(layer.get_win_bursts(6.0).size(), 0, "Expired win burst should disappear")

	layer.free()
	if passed:
		print("test_pipe_vfx_win_burst: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_win_burst: FAIL")
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
