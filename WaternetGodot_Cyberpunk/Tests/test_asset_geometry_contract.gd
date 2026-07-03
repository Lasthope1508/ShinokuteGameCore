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

	for geometry in geometries:
		passed = passed and _assert_true(geometry.has_method("get_frame_scale"), "%s should provide frame scale" % geometry.asset_key)
		passed = passed and _assert_true(geometry.has_method("get_draw_rect"), "%s should provide draw rect" % geometry.asset_key)
		passed = passed and _assert_true(geometry.has_method("get_scaled_content_rect"), "%s should provide scaled content rect" % geometry.asset_key)
		passed = passed and _assert_true(geometry.has_method("get_scaled_energy_rect"), "%s should provide scaled energy rect" % geometry.asset_key)
		passed = passed and _assert_true(geometry.has_method("get_route_junction_offset"), "%s should provide route junction offset" % geometry.asset_key)
		passed = passed and _assert_true(geometry.has_method("get_port_offset"), "%s should provide scaled port offsets" % geometry.asset_key)

		if geometry.has_method("get_frame_scale"):
			for cell_size in [48.0, 72.0, 120.0]:
				var scale: Vector2 = geometry.get_frame_scale(cell_size)
				passed = passed and _assert_vec2_close(scale, Vector2(cell_size / 512.0, cell_size / 512.0), "%s scale should follow frame size at %s" % [geometry.asset_key, str(cell_size)])

		if geometry.has_method("get_draw_rect"):
			var rect: Rect2 = geometry.get_draw_rect()
			passed = passed and _assert_equal(rect, Rect2(Vector2(-256.0, -256.0), Vector2(512.0, 512.0)), "%s draw rect should use configured origin" % geometry.asset_key)

		if geometry.has_method("get_scaled_content_rect"):
			var content_rect: Rect2 = geometry.get_scaled_content_rect(96.0)
			var draw_rect := Rect2(Vector2(-48.0, -48.0), Vector2(96.0, 96.0))
			passed = passed and _assert_true(draw_rect.encloses(content_rect), "%s scaled content rect should stay inside frame" % geometry.asset_key)

		if geometry.has_method("get_scaled_energy_rect"):
			var energy_rect: Rect2 = geometry.get_scaled_energy_rect(96.0)
			var draw_rect := Rect2(Vector2(-48.0, -48.0), Vector2(96.0, 96.0))
			passed = passed and _assert_true(draw_rect.encloses(energy_rect), "%s scaled energy rect should stay inside frame" % geometry.asset_key)

		if geometry.has_method("get_route_junction_offset"):
			passed = passed and _assert_vec2_close(geometry.get_route_junction_offset(96.0), Vector2.ZERO, "%s route junction should default to cell center" % geometry.asset_key)

		if geometry.has_method("get_port_offset"):
			passed = passed and _assert_vec2_close(geometry.get_port_offset(0, 96.0), Vector2(0.0, -48.0), "%s north port should land on cell edge" % geometry.asset_key)
			passed = passed and _assert_vec2_close(geometry.get_port_offset(1, 96.0), Vector2(48.0, 0.0), "%s east port should land on cell edge" % geometry.asset_key)
			passed = passed and _assert_vec2_close(geometry.get_port_offset(2, 96.0), Vector2(0.0, 48.0), "%s south port should land on cell edge" % geometry.asset_key)
			passed = passed and _assert_vec2_close(geometry.get_port_offset(3, 96.0), Vector2(-48.0, 0.0), "%s west port should land on cell edge" % geometry.asset_key)

	if passed:
		print("test_asset_geometry_contract: PASS")
		quit(0)
	else:
		print("test_asset_geometry_contract: FAIL")
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

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.01) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
