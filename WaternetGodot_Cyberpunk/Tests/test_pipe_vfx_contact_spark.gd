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
			"age": 0.02,
			"flow_mask": 2,
			"order": 0
		},
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.05,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 1.0,
			"flow_mask": 10,
			"order": 2
		}
	}
	var geometries := {
		Vector2i(0, 0): theme.source_geometry,
		Vector2i(1, 0): theme.pipe_i_geometry,
		Vector2i(2, 0): theme.pipe_i_geometry
	}

	passed = passed and _assert_true(layer.has_method("get_contact_sparks"), "PipeVfxLayer should expose contact spark data")
	passed = passed and _assert_true(_has_property(theme, "vfx_contact_spark_color"), "Theme should own contact spark color")
	passed = passed and _assert_true(_has_property(theme, "vfx_contact_spark_duration"), "Theme should own contact spark duration")
	passed = passed and _assert_true(_has_property(theme, "vfx_contact_spark_radius_ratio"), "Theme should own contact spark radius ratio")

	layer.set_visual_context(flow_state, geometries, Vector2(10, 20), 100.0)
	if layer.has_method("apply_theme_config"):
		layer.apply_theme_config(theme, 100.0)

	if layer.has_method("get_contact_sparks"):
		var sparks: Array = layer.get_contact_sparks()
		passed = passed and _assert_equal(sparks.size(), 1, "Only newly entered non-source tile should create contact spark")
		if sparks.size() == 1:
			var spark: Dictionary = sparks[0]
			passed = passed and _assert_equal(spark.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Spark should belong to newly entered tile")
			passed = passed and _assert_equal(spark.get("direction", -1), 3, "Spark should spawn at input direction")
			passed = passed and _assert_vec2_close(spark.get("position", Vector2.ZERO), Vector2(110, 70), "Spark position should use west port anchor")
			passed = passed and _assert_true(float(spark.get("radius", 0.0)) > 0.0, "Spark radius should be positive")
			passed = passed and _assert_true(float(spark.get("alpha", 0.0)) > 0.0 and float(spark.get("alpha", 0.0)) <= 1.0, "Spark alpha should be normalized")
			passed = passed and _assert_equal(spark.get("color", Color.BLACK), theme.vfx_contact_spark_color, "Spark color should come from theme")

	layer.free()

	if passed:
		print("test_pipe_vfx_contact_spark: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_contact_spark: FAIL")
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
