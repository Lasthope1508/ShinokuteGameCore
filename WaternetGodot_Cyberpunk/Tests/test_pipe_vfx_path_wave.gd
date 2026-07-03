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
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 2},
		Vector2i(3, 0): {"cell_pos": Vector2i(3, 0), "input_dir": 3, "output_dirs": [], "age": 2.0, "flow_mask": 8, "order": 3}
	}
	var geometry_by_cell := {
		Vector2i(0, 0): theme.get_asset_geometry("source"),
		Vector2i(1, 0): theme.get_asset_geometry("I"),
		Vector2i(2, 0): theme.get_asset_geometry("I"),
		Vector2i(3, 0): theme.get_asset_geometry("target")
	}

	passed = passed and _assert_true(layer.has_method("get_path_waves"), "PipeVfxLayer should expose continuous path wave data")
	passed = passed and _assert_true(layer.has_method("_get_path_wave_particle_count_for_order"), "PipeVfxLayer should expose order-based path wave particle count helper")
	for property_name in ["vfx_path_wave_color", "vfx_path_wave_period", "vfx_path_wave_segment_ratio", "vfx_path_wave_width_ratio", "vfx_path_wave_alpha", "vfx_path_wave_max_effects", "vfx_path_wave_min_particles_per_output", "vfx_path_wave_max_particles_per_output", "vfx_path_wave_density_curve", "vfx_path_wave_order_phase_offset"]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)

	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	if layer.has_method("get_path_waves"):
		var early: Array = layer.get_path_waves(0.0)
		var later: Array = layer.get_path_waves(float(theme.get("vfx_path_wave_period")) * 0.25)
		passed = passed and _assert_true(early.size() > 0, "Powered outputs should create path waves")
		passed = passed and _assert_true(early.size() <= int(theme.get("vfx_path_wave_max_effects")), "Path wave count should respect theme cap")
		if early.size() > 0 and later.size() > 0:
			passed = passed and _assert_true(float(early[0].get("head_progress", -1.0)) != float(later[0].get("head_progress", -1.0)), "Path wave should move over time")
			passed = passed and _assert_equal(early[0].get("color", Color.BLACK), theme.get("vfx_path_wave_color"), "Path wave color should come from theme")
		var counts_by_cell := _count_waves_by_cell(early)
		passed = passed and _assert_true(int(counts_by_cell.get(Vector2i(1, 0), 0)) >= int(counts_by_cell.get(Vector2i(0, 0), 0)), "Path wave count should not drop as flow moves toward target")
		passed = passed and _assert_true(int(counts_by_cell.get(Vector2i(2, 0), 0)) > int(counts_by_cell.get(Vector2i(0, 0), 0)), "Path wave count should increase near target")
		if layer.has_method("_get_path_wave_particle_count_for_order"):
			var max_order := 3
			passed = passed and _assert_equal(layer._get_path_wave_particle_count_for_order(0, max_order), int(theme.get("vfx_path_wave_min_particles_per_output")), "Source-side path wave count should use theme minimum")
			passed = passed and _assert_equal(layer._get_path_wave_particle_count_for_order(max_order, max_order), int(theme.get("vfx_path_wave_max_particles_per_output")), "Target-side path wave count should use theme maximum")

	layer.free()
	if passed:
		print("test_pipe_vfx_path_wave: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_path_wave: FAIL")
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

func _count_waves_by_cell(waves: Array) -> Dictionary:
	var counts := {}
	for wave in waves:
		var cell_pos: Vector2i = wave.get("cell_pos", Vector2i(-1, -1))
		counts[cell_pos] = int(counts.get(cell_pos, 0)) + 1
	return counts
