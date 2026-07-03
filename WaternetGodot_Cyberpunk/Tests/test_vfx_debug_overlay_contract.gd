extends SceneTree

const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	for property_name in [
		"vfx_disconnect_decay_color",
		"vfx_disconnect_decay_duration",
		"vfx_disconnect_decay_alpha",
		"vfx_error_spark_color",
		"vfx_error_spark_duration",
		"vfx_error_spark_radius_ratio",
		"vfx_debug_anchor_color",
		"vfx_debug_input_color",
		"vfx_debug_output_color",
		"vfx_debug_order_color"
	]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)
	if passed:
		passed = passed and _assert_true(float(theme.get("vfx_disconnect_decay_duration")) > 0.0, "Disconnect decay duration should be positive")
		passed = passed and _assert_true(float(theme.get("vfx_error_spark_duration")) > 0.0, "Error spark duration should be positive")
		passed = passed and _assert_true(float(theme.get("vfx_disconnect_decay_alpha")) > 0.0, "Disconnect decay alpha should be positive")
	var layer = PipeVfxLayerScript.new()
	layer.apply_theme_config(theme, 100.0)
	layer.set_debug_visible(true)
	layer.set_visual_context(
		{
			Vector2i(1, 0): {
				"cell_pos": Vector2i(1, 0),
				"order": 2,
				"input_dir": 3,
				"output_dirs": [1],
				"flow_mask": 10,
				"age": 0.2
			}
		},
		{Vector2i(1, 0): theme.get_asset_geometry("I")},
		Vector2.ZERO,
		100.0
	)
	passed = passed and _assert_true(layer.has_method("get_debug_anchors"), "PipeVfxLayer should expose debug anchor data")
	if layer.has_method("get_debug_anchors"):
		var anchors: Array = layer.get_debug_anchors()
		passed = passed and _assert_equal(anchors.size(), 1, "One flow cell should produce one debug anchor entry")
		if anchors.size() == 1:
			var entry: Dictionary = anchors[0]
			passed = passed and _assert_equal(entry.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Debug entry should keep cell")
			passed = passed and _assert_equal(int(entry.get("order", -1)), 2, "Debug entry should keep flow order")
			passed = passed and _assert_equal(int(entry.get("input_dir", -1)), 3, "Debug entry should keep input direction")
			passed = passed and _assert_equal(entry.get("output_dirs", []), [1], "Debug entry should keep output directions")
			passed = passed and _assert_true(entry.get("anchors", {}).has("energy_center"), "Debug entry should expose anchors")
	layer.free()

	if passed:
		print("test_vfx_debug_overlay_contract: PASS")
		quit(0)
	else:
		print("test_vfx_debug_overlay_contract: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if String(info.get("name", "")) == property_name:
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
