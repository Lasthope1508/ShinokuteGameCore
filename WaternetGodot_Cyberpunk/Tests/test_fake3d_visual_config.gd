extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const MAPPER_PATH = "res://Scripts/pipe_visual_mapping.gd"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var mapper = load(MAPPER_PATH)

	passed = passed and _assert_true(_has_property(theme, "fake_3d_enabled"), "Theme should own fake_3d_enabled")
	passed = passed and _assert_true(_has_property(theme, "texture_native_size"), "Theme should own texture_native_size")
	passed = passed and _assert_true(_has_property(theme, "pipe_shadow_offset_ratio"), "Theme should own pipe_shadow_offset_ratio")
	passed = passed and _assert_true(_has_property(theme, "pipe_shadow_alpha"), "Theme should own pipe_shadow_alpha")
	passed = passed and _assert_true(_has_property(theme, "pipe_dry_modulate"), "Theme should own pipe dry brightness")
	passed = passed and _assert_true(_has_property(theme, "cell_bevel_width_ratio"), "Theme should own cell_bevel_width_ratio")
	passed = passed and _assert_true(_has_property(theme, "cell_inset_ratio"), "Theme should own cell_inset_ratio")
	passed = passed and _assert_true(_has_property(theme, "cell_highlight_color"), "Theme should own cell_highlight_color")
	passed = passed and _assert_true(_has_property(theme, "cell_shadow_color"), "Theme should own cell_shadow_color")
	passed = passed and _assert_true(_has_property(theme, "cell_geometry"), "Theme should own cell geometry")
	passed = passed and _assert_true(_has_property(theme, "source_geometry"), "Theme should own source geometry")
	passed = passed and _assert_true(_has_property(theme, "target_geometry"), "Theme should own target geometry")
	passed = passed and _assert_true(_has_property(theme, "pipe_cap_geometry"), "Theme should own cap geometry")
	passed = passed and _assert_true(_has_property(theme, "pipe_i_geometry"), "Theme should own I geometry")
	passed = passed and _assert_true(_has_property(theme, "pipe_l_geometry"), "Theme should own L geometry")
	passed = passed and _assert_true(_has_property(theme, "pipe_t_geometry"), "Theme should own T geometry")
	passed = passed and _assert_true(_has_property(theme, "pipe_x_geometry"), "Theme should own X geometry")

	if _has_property(theme, "fake_3d_enabled"):
		passed = passed and _assert_equal(theme.fake_3d_enabled, true, "Cyber theme should enable fake3D")
	if _has_property(theme, "texture_native_size"):
		passed = passed and _assert_equal(theme.texture_native_size, Vector2(512.0, 512.0), "Cyber texture native size should match standardized atlas frames")
	if _has_property(theme, "pipe_shadow_offset_ratio"):
		passed = passed and _assert_equal(theme.pipe_shadow_offset_ratio, Vector2(0.045, 0.055), "Cyber pipe shadow offset should be theme-owned")
	if _has_property(theme, "pipe_shadow_alpha"):
		passed = passed and _assert_true(theme.pipe_shadow_alpha > 0.0, "Cyber pipe shadow alpha should be visible")
		passed = passed and _assert_true(theme.pipe_shadow_alpha <= 0.24, "Cyber pipe shadow should not crush brighter dry pipes")
	if _has_property(theme, "pipe_dry_modulate"):
		var dry_modulate: Color = theme.get("pipe_dry_modulate")
		passed = passed and _assert_true(dry_modulate.r >= 0.3 and dry_modulate.g >= 0.3 and dry_modulate.b >= 0.3, "Dry pipes should stay readable on dark/light floorplates")
		passed = passed and _assert_true(dry_modulate.r < 0.6 and dry_modulate.g < 0.6 and dry_modulate.b < 0.6, "Dry pipes should remain graphite, not powered-bright")
	if _has_property(theme, "cell_geometry"):
		for geometry in [
			theme.cell_geometry,
			theme.source_geometry,
			theme.target_geometry,
			theme.pipe_cap_geometry,
			theme.pipe_i_geometry,
			theme.pipe_l_geometry,
			theme.pipe_t_geometry,
			theme.pipe_x_geometry
		]:
			passed = passed and _assert_asset_geometry(geometry)

	passed = passed and _assert_true(mapper.has_method("get_local_flow_mask"), "Mapper should expose generic local flow mask")
	passed = passed and _assert_true(mapper.has_method("get_rotation_index_for_ports"), "Mapper should expose canonical rotation helper")
	passed = passed and _assert_true(mapper.has_method("get_tile_offset"), "Mapper should expose tile offset helper")
	if mapper.has_method("get_local_flow_mask"):
		passed = passed and _assert_equal(mapper.get_local_flow_mask(5, 0), 5, "No rotation should keep vertical flow mask")
		passed = passed and _assert_equal(mapper.get_local_flow_mask(10, 1), 5, "Horizontal global flow rotated into local vertical mask")
	if mapper.has_method("get_rotation_index_for_ports"):
		passed = passed and _assert_equal(mapper.get_rotation_index_for_ports([true, true, false, false]), 0, "North-East L should be canonical rotation 0")
		passed = passed and _assert_equal(mapper.get_rotation_index_for_ports([false, true, false, true]), 1, "East-West I should be canonical rotation 1")

	if passed:
		print("test_fake3d_visual_config: PASS")
		quit(0)
	else:
		print("test_fake3d_visual_config: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _assert_asset_geometry(geometry: Resource) -> bool:
	var passed := true
	passed = passed and _assert_true(geometry != null, "Asset geometry should be assigned")
	if geometry == null:
		return false
	passed = passed and _assert_equal(geometry.frame_size, Vector2(512.0, 512.0), "%s frame size should be 512x512" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.draw_origin, Vector2(256.0, 256.0), "%s draw origin should be centered" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.center, Vector2(256.0, 256.0), "%s center should be canonical" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.north_port, Vector2(256.0, 0.0), "%s north port should be canonical" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.east_port, Vector2(512.0, 256.0), "%s east port should be canonical" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.south_port, Vector2(256.0, 512.0), "%s south port should be canonical" % geometry.asset_key)
	passed = passed and _assert_equal(geometry.west_port, Vector2(0.0, 256.0), "%s west port should be canonical" % geometry.asset_key)
	passed = passed and _assert_true(geometry.content_rect.size.x > 0.0 and geometry.content_rect.size.y > 0.0, "%s content rect should be non-empty" % geometry.asset_key)
	passed = passed and _assert_true(geometry.energy_rect.size.x > 0.0 and geometry.energy_rect.size.y > 0.0, "%s energy rect should be non-empty" % geometry.asset_key)
	return passed

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
