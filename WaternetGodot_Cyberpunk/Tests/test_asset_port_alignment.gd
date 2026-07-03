extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var geometries := [
		theme.cell_geometry,
		theme.source_geometry,
		theme.target_geometry,
		theme.pipe_cap_geometry,
		theme.pipe_i_geometry,
		theme.pipe_l_geometry,
		theme.pipe_t_geometry,
		theme.pipe_x_geometry
	]
	var expected_edges := [
		Vector2(0.0, -1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(-1.0, 0.0)
	]

	for geometry in geometries:
		passed = passed and _assert_true(geometry.has_method("get_rotated_port_offset"), "%s should expose rotated port offset" % geometry.asset_key)
		if not geometry.has_method("get_rotated_port_offset"):
			continue
		for cell_size in [48.0, 96.0, 144.0]:
			var half: float = float(cell_size) / 2.0
			for rotation_index in range(4):
				for local_direction in range(4):
					var actual: Vector2 = geometry.get_rotated_port_offset(local_direction, rotation_index, cell_size)
					var expected_direction: int = (local_direction + rotation_index) % 4
					var expected: Vector2 = expected_edges[expected_direction] * half
					passed = passed and _assert_vec2_close(actual, expected, "%s local port %d rotated %d should land on cell edge at %s" % [geometry.asset_key, local_direction, rotation_index, str(cell_size)])

	if passed:
		print("test_asset_port_alignment: PASS")
		quit(0)
	else:
		print("test_asset_port_alignment: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.01) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
