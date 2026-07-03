extends SceneTree

const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayerScript.new()
	layer.apply_theme_config(theme, 100.0)
	layer.set_visual_context(
		{},
		{Vector2i(0, 0): theme.get_asset_geometry("source")},
		Vector2.ZERO,
		100.0
	)

	passed = passed and _assert_true(layer.has_method("set_transition_state"), "PipeVfxLayer should accept transition state")
	passed = passed and _assert_true(layer.has_method("get_error_sparks"), "PipeVfxLayer should expose error spark data")
	if layer.has_method("set_transition_state") and layer.has_method("get_error_sparks"):
		layer.set_transition_state({
			"lost_contacts": [
				{"cell_pos": Vector2i(0, 0), "direction": 1, "neighbor_pos": Vector2i(1, 0)}
			],
			"event_time": Time.get_ticks_msec() / 1000.0 - 0.03
		})
		var sparks: Array = layer.get_error_sparks()
		passed = passed and _assert_equal(sparks.size(), 1, "One lost contact should produce one error spark")
		if sparks.size() == 1:
			var spark: Dictionary = sparks[0]
			passed = passed and _assert_equal(spark.get("cell_pos", Vector2i(-1, -1)), Vector2i(0, 0), "Spark should belong to contact cell")
			passed = passed and _assert_equal(int(spark.get("direction", -1)), 1, "Spark should store lost direction")
			passed = passed and _assert_vec2_close(spark.get("position", Vector2.ZERO), Vector2(100.0, 50.0), "Spark should use east port anchor")
			passed = passed and _assert_equal(spark.get("color", Color.BLACK), theme.vfx_error_spark_color, "Spark color should come from theme")

	layer.free()
	if passed:
		print("test_pipe_vfx_error_spark: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_error_spark: FAIL")
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

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String) -> bool:
	if actual.distance_to(expected) > 0.01:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
