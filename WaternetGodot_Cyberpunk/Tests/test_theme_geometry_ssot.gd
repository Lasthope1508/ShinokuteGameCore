extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var expected_keys: Array = ["cell", "source", "target", "cap", "I", "L", "T", "X"]
	if theme.has_method("get_required_asset_keys"):
		expected_keys = theme.get_required_asset_keys()

	passed = passed and _assert_true(theme.has_method("get_required_asset_keys"), "Theme should expose required geometry keys")
	passed = passed and _assert_true(theme.has_method("get_all_asset_geometries"), "Theme should expose geometry manifest")
	passed = passed and _assert_true(theme.has_method("get_asset_geometry"), "Theme should expose geometry lookup")
	passed = passed and _assert_true(theme.has_method("validate_geometry_manifest"), "Theme should validate geometry manifest")

	if theme.has_method("get_all_asset_geometries"):
		var manifest: Dictionary = theme.get_all_asset_geometries()
		passed = passed and _assert_equal(manifest.size(), expected_keys.size(), "Cyber geometry manifest should include every asset")
		for key in expected_keys:
			passed = passed and _assert_true(manifest.has(key), "Cyber geometry manifest should include %s" % key)
			if manifest.has(key):
				passed = passed and _assert_equal(manifest[key].asset_key, key, "%s geometry asset_key should match manifest key" % key)

	if theme.has_method("get_asset_geometry"):
		passed = passed and _assert_equal(theme.get_asset_geometry("cell"), theme.cell_geometry, "cell lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("source"), theme.source_geometry, "source lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("target"), theme.target_geometry, "target lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("cap"), theme.pipe_cap_geometry, "cap lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("I"), theme.pipe_i_geometry, "I lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("L"), theme.pipe_l_geometry, "L lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("T"), theme.pipe_t_geometry, "T lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("X"), theme.pipe_x_geometry, "X lookup should use theme SSOT")
		passed = passed and _assert_equal(theme.get_asset_geometry("missing"), null, "missing lookup should return null")

	if theme.has_method("validate_geometry_manifest"):
		passed = passed and _assert_equal(theme.validate_geometry_manifest().size(), 0, "Cyber geometry manifest should be valid")

	if theme.pipe_l_geometry != null:
		passed = passed and _assert_equal(theme.pipe_l_geometry.frame_size, Vector2(512, 512), "L frame size should be stored in geometry SSOT")
		passed = passed and _assert_equal(theme.pipe_l_geometry.content_rect, Rect2(176, 0, 336, 336), "L content rect should be stored in geometry SSOT")
		passed = passed and _assert_equal(theme.pipe_l_geometry.energy_rect, Rect2(190, 0, 322, 322), "L energy rect should be stored in geometry SSOT")

	if passed:
		print("test_theme_geometry_ssot: PASS")
		quit(0)
	else:
		print("test_theme_geometry_ssot: FAIL")
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
