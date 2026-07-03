extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()
	var geometries := {
		Vector2i(0, 0): theme.source_geometry,
		Vector2i(1, 0): theme.pipe_i_geometry
	}
	var flow_state := {
		Vector2i(0, 0): {
			"cell_pos": Vector2i(0, 0),
			"input_dir": -1,
			"output_dirs": [1],
			"age": 0.25,
			"flow_mask": 2,
			"order": 0
		},
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.1,
			"flow_mask": 10,
			"order": 1
		}
	}

	passed = passed and _assert_true(layer is Node2D, "PipeVfxLayer should be a Node2D overlay")
	passed = passed and _assert_true(layer.has_method("set_visual_context"), "PipeVfxLayer should accept visual context")
	passed = passed and _assert_true(layer.has_method("set_vfx_enabled"), "PipeVfxLayer should expose enable toggle")
	passed = passed and _assert_true(layer.has_method("set_debug_visible"), "PipeVfxLayer should expose debug toggle")
	passed = passed and _assert_true(layer.has_method("apply_theme_config"), "PipeVfxLayer should read VFX theme config")
	passed = passed and _assert_true(layer.has_method("get_debug_segments"), "PipeVfxLayer should expose debug segment data")

	if layer.has_method("set_visual_context"):
		layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
		passed = passed and _assert_equal(layer.flow_state.size(), 2, "PipeVfxLayer should store flow state")
		passed = passed and _assert_equal(layer.geometry_by_cell.size(), 2, "PipeVfxLayer should store geometry map")
		passed = passed and _assert_vec2_close(layer.grid_offset, Vector2(10, 20), "PipeVfxLayer should store grid offset")
		passed = passed and _assert_float_close(layer.cell_size, 100.0, "PipeVfxLayer should store cell size")

	if layer.has_method("set_vfx_enabled"):
		layer.set_vfx_enabled(false)
		passed = passed and _assert_equal(layer.vfx_enabled, false, "PipeVfxLayer should disable VFX")
		layer.set_vfx_enabled(true)
		passed = passed and _assert_equal(layer.vfx_enabled, true, "PipeVfxLayer should enable VFX")

	if layer.has_method("set_debug_visible"):
		layer.set_debug_visible(true)
		passed = passed and _assert_equal(layer.debug_visible, true, "PipeVfxLayer should enable debug draw")

	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)
		passed = passed and _assert_equal(layer.vfx_enabled, theme.vfx_enabled, "PipeVfxLayer should read enabled state from theme")
		passed = passed and _assert_equal(layer.debug_visible, theme.vfx_debug_visible, "PipeVfxLayer should read debug state from theme")
		passed = passed and _assert_equal(layer.debug_line_color, theme.vfx_debug_line_color, "PipeVfxLayer should read debug color from theme")
		passed = passed and _assert_float_close(layer.debug_line_width, 100.0 * theme.vfx_debug_line_width_ratio, "PipeVfxLayer should scale debug width from theme")
		layer.set_debug_visible(true)

	if layer.has_method("get_debug_segments"):
		var segments: Array = layer.get_debug_segments()
		passed = passed and _assert_equal(segments.size(), 2, "PipeVfxLayer should build canonical route debug segments")
		if segments.size() >= 1:
			var first: Dictionary = segments[0]
			passed = passed and _assert_equal(first.get("cell_pos", Vector2i(-1, -1)), Vector2i(0, 0), "first segment should belong to source cell")
			passed = passed and _assert_equal(first.get("direction", -99), 1, "first segment should point east")
			passed = passed and _assert_true(first.get("from", Vector2.ZERO) is Vector2, "segment should include start point")
			passed = passed and _assert_true(first.get("to", Vector2.ZERO) is Vector2, "segment should include end point")

	layer.free()

	if passed:
		print("test_pipe_vfx_layer_contract: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_layer_contract: FAIL")
		quit(1)

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

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.01) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_float_close(actual: float, expected: float, message: String, epsilon: float = 0.01) -> bool:
	if abs(actual - expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
