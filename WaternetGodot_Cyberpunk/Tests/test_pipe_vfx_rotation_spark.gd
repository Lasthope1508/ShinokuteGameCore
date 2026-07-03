extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayer.new()

	passed = passed and _assert_true(layer.has_method("set_rotation_event"), "PipeVfxLayer should accept rotation event")
	passed = passed and _assert_true(layer.has_method("get_rotation_sparks"), "PipeVfxLayer should expose rotation sparks")
	passed = passed and _assert_true(layer.has_method("clear_runtime_events"), "PipeVfxLayer should clear runtime events")
	for property_name in ["vfx_rotation_spark_color", "vfx_rotation_spark_duration", "vfx_rotation_spark_radius_ratio", "vfx_rotation_spark_ray_count", "vfx_rotation_spark_width_ratio"]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)

	layer.set_visual_context({}, {Vector2i(1, 0): theme.get_asset_geometry("I")}, Vector2(10, 20), 100.0)
	layer.apply_theme_config(theme, 100.0)
	if layer.has_method("set_rotation_event") and layer.has_method("get_rotation_sparks"):
		layer.set_rotation_event(Vector2i(1, 0), 2.0)
		var sparks: Array = layer.get_rotation_sparks(2.05)
		passed = passed and _assert_equal(sparks.size(), 1, "Active rotation should produce one spark envelope")
		if sparks.size() == 1:
			var spark: Dictionary = sparks[0]
			passed = passed and _assert_equal(spark.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Spark should belong to rotated cell")
			passed = passed and _assert_equal(spark.get("color", Color.BLACK), theme.get("vfx_rotation_spark_color"), "Spark color should come from theme")
			passed = passed and _assert_equal(int(spark.get("ray_count", 0)), int(theme.get("vfx_rotation_spark_ray_count")), "Spark ray count should come from theme")
			passed = passed and _assert_vec2_close(spark.get("position", Vector2.ZERO), Vector2(160.0, 70.0), "Spark should use geometry energy center")
		passed = passed and _assert_equal(layer.get_rotation_sparks(3.0).size(), 0, "Expired rotation spark should disappear")
		layer.clear_runtime_events()
		passed = passed and _assert_equal(layer.get_rotation_sparks(2.05).size(), 0, "Cleared runtime events should remove rotation spark")

	layer.free()
	if passed:
		print("test_pipe_vfx_rotation_spark: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_rotation_spark: FAIL")
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
