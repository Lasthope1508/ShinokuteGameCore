extends SceneTree

const MAPPER_PATH = "res://Scripts/pipe_visual_mapping.gd"

func _init() -> void:
	var passed = true

	passed = passed and _assert_true(
		ResourceLoader.exists(MAPPER_PATH),
		"Pipe visual mapper script should exist"
	)
	if ResourceLoader.exists(MAPPER_PATH):
		var mapper = load(MAPPER_PATH)
		passed = passed and _assert_equal(
			mapper.get_l_visual_rotation_index(0),
			0,
			"Logical L ports North-East should use native cyber asset rotation"
		)
		passed = passed and _assert_equal(
			mapper.get_l_local_flow_mask(3, 0),
			3,
			"North-East flow should map to native cyber L North-East slice"
		)
		passed = passed and _assert_true(
			mapper.has_method("get_l_visual_scale"),
			"Cyber L visual scale should be defined"
		)
		if mapper.has_method("get_l_visual_scale"):
			passed = passed and _assert_equal(
				mapper.get_l_visual_scale(),
				1.0,
				"Standardized cyber L slice should draw at full cell scale"
			)
		passed = passed and _assert_true(
			mapper.has_method("get_l_anchor_offset"),
			"Cyber L anchor offset should be defined"
		)
		if mapper.has_method("get_l_anchor_offset"):
			passed = passed and _assert_equal(
				mapper.get_l_anchor_offset([true, true, false, false], 100.0, 1.0),
				Vector2.ZERO,
				"Standardized North-East L should not need anchor correction"
			)

	var theme = load("res://Resources/Data/Themes/cyberpunk_theme.tres")
	var masks = []
	for slice in theme.l_slices:
		masks.append(slice.flow_mask)
	passed = passed and _assert_equal(
		masks,
		[0, 3, 1, 2],
		"Cyber L slice masks should match native North-East base art directions"
	)

	if passed:
		print("test_l_pipe_visual_mapping: PASS")
		quit(0)
	else:
		print("test_l_pipe_visual_mapping: FAIL")
		quit(1)

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
