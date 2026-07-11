extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		passed = _assert_equal(theme.get("asset_family_concept_sheet_path"), "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png", "Asset family concept sheet path should match") and passed
		passed = _assert_color_html(theme.get("collectible_star_body_color"), "ff6f61", "Collectible star body color should match") and passed
		passed = _assert_color_html(theme.get("collectible_star_rim_color"), "7be0ad", "Collectible star rim color should match") and passed
		passed = _assert_color_html(theme.get("platform_top_material_color"), "fff2c7", "Platform top material color should match") and passed
		passed = _assert_color_html(theme.get("platform_edge_material_color"), "ff6f61", "Platform edge material color should match") and passed
		passed = _assert_color_html(theme.get("hud_score_frame_color"), "fff2c7", "HUD score frame color should match") and passed
		passed = _assert_color_html(theme.get("skybox_tint_color"), "79c7f2", "Skybox tint color should match") and passed
		passed = _assert_color_html(theme.get("obstacle_wafer_material_color"), "ffb38c", "Obstacle wafer material color should match") and passed
		passed = _assert_color_html(theme.get("goal_pennant_material_color"), "7be0ad", "Goal pennant material color should match") and passed
	if passed:
		print("test_asset_family_theme_contract: PASS")
		quit(0)
	else:
		print("test_asset_family_theme_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_color_html(actual, expected: String, message: String) -> bool:
	if not actual is Color:
		push_error("%s: expected Color %s, got %s" % [message, expected, str(actual)])
		return false
	return _assert_equal(actual.to_html(false), expected, message)
