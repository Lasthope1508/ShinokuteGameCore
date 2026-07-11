extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		passed = passed and _assert_equal(theme.theme_name, "candy_sky_islands", "Theme name should match")
		passed = passed and _assert_equal(theme.display_name, "Candy Sky Islands", "Display name should match")
		passed = passed and _assert_equal(theme.palette_sky.to_html(false), "79c7f2", "Sky color should match approval")
		passed = passed and _assert_equal(theme.palette_surface.to_html(false), "fff2c7", "Surface color should match approval")
		passed = passed and _assert_equal(theme.palette_primary.to_html(false), "ff6f61", "Primary color should match approval")
		passed = passed and _assert_equal(theme.palette_accent.to_html(false), "7be0ad", "Accent color should match approval")
		passed = passed and _assert_equal(theme.palette_text.to_html(false), "273043", "Text color should match approval")
		passed = passed and _assert_true(theme.hud_coin_icon_path == "res://assets/themes/candy_sky_islands/star_collectible.png", "HUD coin path should use extracted star collectible")
		passed = passed and _assert_true(theme.hud_font_path == "res://fonts/lilita_one_regular.ttf", "HUD font path should be explicit")
		passed = passed and _assert_true(theme.hud_text_owner_rect.size.x > 0.0, "HUD text owner width should be positive")
		passed = passed and _assert_true(theme.hud_text_owner_rect.size.y > 0.0, "HUD text owner height should be positive")
		passed = passed and _assert_equal(theme.get("player_root_asset_path"), "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png", "Player root asset path should match approved concept")
		passed = passed and _assert_equal(theme.get("hud_score_frame_path"), "res://assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png", "HUD score frame path should use 9Router reference-edited frame")
		passed = passed and _assert_equal(theme.get("candy_skybox_path"), "res://assets/themes/candy_sky_islands/sky_panel_islands.png", "Candy skybox path should use extracted sky panel")
		passed = passed and _assert_color_html(theme.get("player_body_material_color"), "fff2c7", "Player body should use cream marshmallow color")
		passed = passed and _assert_color_html(theme.get("player_cap_material_color"), "fff2c7", "Player cap should use whipped cream color")
		passed = passed and _assert_color_html(theme.get("player_left_glove_material_color"), "ff6f61", "Player left glove should use coral color")
		passed = passed and _assert_color_html(theme.get("player_right_glove_material_color"), "7be0ad", "Player right glove should use mint color")
		passed = passed and _assert_true(theme.validate().is_empty(), "Theme validation should pass")
	if passed:
		print("test_candy_theme_config: PASS")
		quit(0)
	else:
		print("test_candy_theme_config: FAIL")
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
