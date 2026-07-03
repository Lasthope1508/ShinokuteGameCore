extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()

	var required_theme_fields := [
		"vfx_lightning_enabled",
		"vfx_lightning_texture",
		"vfx_lightning_frame_size",
		"vfx_lightning_columns",
		"vfx_lightning_rows",
		"vfx_lightning_frame_count",
		"vfx_lightning_period",
		"vfx_lightning_contact_period",
		"vfx_lightning_color",
		"vfx_lightning_alpha",
		"vfx_lightning_scale_ratio",
		"vfx_lightning_max_arcs",
		"vfx_lightning_cell_stride",
		"vfx_lightning_min_order_progress",
		"vfx_lightning_contact_bias"
	]
	for property_name in required_theme_fields:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)
	var lightning_texture = theme.get("vfx_lightning_texture")
	if lightning_texture != null:
		var frame_size = theme.get("vfx_lightning_frame_size")
		passed = passed and _assert_equal(lightning_texture.get_width(), int(theme.get("vfx_lightning_columns")) * frame_size.x, "Lightning atlas width should match columns and frame size")
		passed = passed and _assert_equal(lightning_texture.get_height(), int(theme.get("vfx_lightning_rows")) * frame_size.y, "Lightning atlas height should match rows and frame size")

	passed = passed and _assert_true(layer.has_method("get_lightning_arcs"), "PipeVfxLayer should expose lightning arc data")

	var flow_state := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [1], "age": 2.0, "flow_mask": 2, "order": 0},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 1},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 2},
		Vector2i(3, 0): {"cell_pos": Vector2i(3, 0), "input_dir": 3, "output_dirs": [], "age": 2.0, "flow_mask": 8, "order": 3}
	}
	var geometry_by_cell := {
		Vector2i(0, 0): theme.get_asset_geometry("source"),
		Vector2i(1, 0): theme.get_asset_geometry("I"),
		Vector2i(2, 0): theme.get_asset_geometry("I"),
		Vector2i(3, 0): theme.get_asset_geometry("target")
	}

	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	layer.lightning_cell_stride = 1

	if layer.has_method("get_lightning_arcs") and _has_property(theme, "vfx_lightning_max_arcs"):
		var arcs: Array = layer.get_lightning_arcs(1.30)
		passed = passed and _assert_true(arcs.size() > 0, "Powered flow should create sparse lightning arcs")
		passed = passed and _assert_true(arcs.size() <= int(theme.get("vfx_lightning_max_arcs")), "Lightning arcs should respect theme cap")
		passed = passed and _assert_true(_all_contact_keys_unique(arcs), "Shared contacts should use unique canonical keys")
		if arcs.size() > 0:
			var first: Dictionary = arcs[0]
			passed = passed and _assert_true(first.has("contact_key"), "Arc should expose canonical contact key")
			passed = passed and _assert_true(first.has("frame_index"), "Arc should expose sprite frame index")
			passed = passed and _assert_true(first.has("position"), "Arc should expose draw position")
			passed = passed and _assert_true(first.has("rotation"), "Arc should expose draw rotation")
			passed = passed and _assert_true(first.has("scale"), "Arc should expose draw scale")
			passed = passed and _assert_equal(first.get("color", Color.BLACK), theme.get("vfx_lightning_color"), "Arc color should come from theme")
			var total_frames := int(theme.get("vfx_lightning_frame_count"))
			var sheet_frame_step := float(theme.get("vfx_lightning_period")) / float(total_frames)
			var next_arcs: Array = layer.get_lightning_arcs(1.30 + sheet_frame_step * 1.2)
			passed = passed and _assert_true(not next_arcs.is_empty(), "Lightning should keep drawing during a sheet frame step")
			if not next_arcs.is_empty():
				passed = passed and _assert_equal(next_arcs[0].get("contact_key", ""), first.get("contact_key", ""), "Lightning contact should stay stable while sprite frame advances")
				passed = passed and _assert_not_equal(next_arcs[0].get("frame_index", -1), first.get("frame_index", -1), "Lightning sprite should advance inside one sheet frame step")
				passed = passed and _assert_true(int(next_arcs[0].get("frame_index", -1)) < total_frames, "Lightning frame index should stay inside explicit frame count")
			passed = passed and _assert_equal(total_frames, 250, "Lightning should use every 60 FPS source frame")
			passed = passed and _assert_equal(roundf(float(theme.get("vfx_lightning_period")) * 60.0), 250.0, "Lightning cycle period should match source frames at 60 FPS")

	layer.free()
	if passed:
		print("test_pipe_vfx_lightning_arcs: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_lightning_arcs: FAIL")
		quit(1)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

func _all_contact_keys_unique(arcs: Array) -> bool:
	var seen := {}
	for arc in arcs:
		var key := String(arc.get("contact_key", ""))
		if key.is_empty():
			return false
		if seen.has(key):
			return false
		seen[key] = true
	return true

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

func _assert_not_equal(actual, unexpected, message: String) -> bool:
	if actual == unexpected:
		push_error("%s: expected value different from %s" % [message, str(unexpected)])
		return false
	return true
