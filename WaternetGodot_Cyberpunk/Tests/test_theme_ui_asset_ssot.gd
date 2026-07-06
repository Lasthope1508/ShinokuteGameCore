extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const REQUIRED_KEYS := [
	"background_full_portrait",
	"background_full_landscape",
	"top_tray_layer",
	"logo_socket",
	"stats_capsule",
	"floating_menu_button_default",
	"floating_replay_button_default",
	"bottom_reserve_layer",
	"modal_frame",
	"profile_username_field_frame",
	"board_backplate"
]

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(_has_property(theme, "ui_generated_asset_paths"), "Theme should own generated UI asset paths")
	passed = passed and _assert_true(_has_property(theme, "ui_generated_asset_geometry"), "Theme should own generated UI asset geometry")
	passed = passed and _assert_true(_has_property(theme, "ui_hud_margin_top"), "Theme should own HUD top margin")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_landscape_width_height_ratio"), "Theme should own landscape tray width cap")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_generated_object_stretch"), "Theme should own generated UI object stretch policy")
	passed = passed and _assert_true(_has_property(theme, "ui_landscape_board_avoid_top_tray_enabled"), "Theme should own landscape top tray avoidance toggle")
	passed = passed and _assert_true(_has_property(theme, "ui_landscape_board_top_tray_gap"), "Theme should own landscape top tray board gap")
	passed = passed and _assert_true(_has_property(theme, "ui_landscape_board_bottom_safe_margin"), "Theme should own landscape board bottom safe margin")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_side_slot_width_ratio"), "Theme should own top tray side stat slot ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_center_slot_width_ratio"), "Theme should own top tray center stat slot ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_font_size"), "Theme should own top tray stat font size")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_min_font_size"), "Theme should own top tray dynamic stat minimum font size")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_line_height_ratio"), "Theme should own top tray dynamic stat line height ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_stat_fit_width_ratio"), "Theme should own top tray dynamic stat width fit ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_font_path"), "Theme should own top tray time font path")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_default_username"), "Theme should own top tray default username")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_best_wave_label_prefix"), "Theme should own top tray best wave label prefix")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_moves_label_prefix"), "Theme should own top tray moves label prefix")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_color"), "Theme should own top tray time color")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_outline_color"), "Theme should own top tray time outline color")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_shadow_color"), "Theme should own top tray time shadow color")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_outline_size"), "Theme should own top tray time outline size")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_time_fit_padding_ratio"), "Theme should own top tray time visual padding ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_logo_center_y_ratio"), "Theme should own top tray logo center Y ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_project_logo_alpha_bbox"), "Theme should own project logo alpha bbox")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_regions"), "Theme should own normalized top tray region coordinates")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_region_sets"), "Theme should own mode-specific top tray region coordinates")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_region_source_size"), "Theme should own top tray region source canvas size")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_region_source_sizes"), "Theme should own mode-specific top tray region source canvas sizes")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_region_pixel_rects"), "Theme should own top tray region pixel rectangles for audit")
	passed = passed and _assert_true(_has_property(theme, "ui_top_tray_region_pixel_rect_sets"), "Theme should own mode-specific top tray region pixel rectangles for audit")
	passed = passed and _assert_true(_has_property(theme, "ui_playboard_region_sets"), "Theme should own mode/orientation playboard region coordinates")
	passed = passed and _assert_true(_has_property(theme, "ui_playboard_region_source_sizes"), "Theme should own playboard region source viewport sizes")
	passed = passed and _assert_true(_has_property(theme, "ui_playboard_region_pixel_rect_sets"), "Theme should own playboard pixel rectangles for audit")
	passed = passed and _assert_true(_has_property(theme, "ui_bottom_reserve_width_ratio"), "Theme should own bottom reserve width ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_bottom_reserve_height_ratio"), "Theme should own bottom reserve height ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_bottom_reserve_bottom_margin_ratio"), "Theme should own bottom reserve bottom margin ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_modal_width_ratio"), "Theme should own modal width ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_modal_height_ratio"), "Theme should own modal height ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_modal_landscape_width_ratio"), "Theme should own landscape modal width ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_modal_landscape_height_ratio"), "Theme should own landscape modal height ratio")
	passed = passed and _assert_true(_has_property(theme, "ui_modal_close_button_padding"), "Theme should own modal close button padding")
	passed = passed and _assert_true(_has_property(theme, "ui_main_menu_secondary_button_height"), "Theme should own main menu secondary button height")
	passed = passed and _assert_true(_has_property(theme, "ui_profile_popup_score_font_size"), "Theme should own profile popup score font size")
	for screen_property in [
		"ui_main_menu_gap",
		"ui_main_menu_title_font_size",
		"ui_main_menu_subtitle_font_size",
		"ui_main_menu_primary_button_font_size",
		"ui_main_menu_secondary_button_font_size",
		"ui_main_menu_copyright_font_size",
		"ui_main_menu_logo_size",
		"ui_level_select_title_font_size",
		"ui_level_select_gap",
		"ui_level_select_pagination_gap",
		"ui_splash_gap",
		"ui_splash_studio_font_size",
		"ui_splash_presents_font_size",
		"ui_splash_fade_in_duration",
		"ui_splash_hold_duration",
		"ui_splash_fade_out_duration",
		"ui_modal_content_margin_x",
		"ui_modal_content_margin_top",
		"ui_modal_content_margin_bottom",
		"ui_modal_close_icon_color_by_mode",
		"ui_result_modal_width_ratio",
		"ui_result_modal_height_ratio",
		"ui_result_modal_landscape_width_ratio",
		"ui_result_modal_landscape_height_ratio",
		"ui_result_modal_action_button_width",
		"ui_result_modal_action_button_height",
		"ui_result_modal_content_gap",
		"ui_result_modal_content_margin_x",
		"ui_result_modal_content_margin_top",
		"ui_result_modal_content_margin_bottom",
		"ui_result_modal_title_font_size",
		"ui_result_modal_moves_font_size",
		"ui_result_modal_button_font_size",
		"ui_result_modal_outline_size_by_mode",
		"ui_result_modal_text_color_by_mode",
		"ui_result_modal_outline_color_by_mode",
		"ui_result_modal_button_text_color_by_mode",
		"ui_result_modal_button_bg_by_mode",
		"ui_profile_popup_content_margin_x",
		"ui_profile_popup_content_margin_top",
		"ui_profile_popup_content_margin_top_by_mode",
		"ui_profile_popup_content_margin_bottom",
		"ui_profile_popup_title_font_size",
		"ui_profile_popup_field_gap",
		"ui_profile_popup_list_gap",
		"ui_profile_popup_save_button_width",
		"ui_profile_popup_field_min_height",
		"ui_profile_popup_field_padding_x",
		"ui_profile_popup_field_padding_y",
		"ui_profile_popup_name_label_width",
		"ui_profile_popup_field_frame_asset_key",
		"ui_leaderboard_popup_content_margin_x",
		"ui_leaderboard_popup_content_margin_top",
		"ui_leaderboard_popup_content_margin_bottom",
		"ui_leaderboard_popup_title_font_size",
		"ui_leaderboard_popup_status_font_size",
		"ui_leaderboard_popup_list_gap"
	]:
		passed = passed and _assert_true(_has_property(theme, screen_property), "Theme should own %s" % screen_property)
	passed = passed and _assert_true(_has_property(theme, "ui_level_select_button_font_size"), "Theme should own level select button font size")
	passed = passed and _assert_true(_has_property(theme, "ui_level_select_locked_alpha"), "Theme should own level select locked alpha")
	passed = passed and _assert_true(_has_property(theme, "ui_level_select_pagination_button_width"), "Theme should own level select pagination button width")
	passed = passed and _assert_true(_has_property(theme, "ui_level_select_grid_h_separation"), "Theme should own level select horizontal grid separation")
	passed = passed and _assert_true(_has_property(theme, "ui_level_select_grid_v_separation"), "Theme should own level select vertical grid separation")
	passed = passed and _assert_true(theme.has_method("get_ui_generated_asset_path"), "Theme should expose generated UI asset path helper")
	passed = passed and _assert_true(theme.has_method("validate_ui_generated_assets"), "Theme should validate generated UI assets")

	if theme != null and _has_property(theme, "ui_generated_asset_paths"):
		if _has_property(theme, "ui_top_tray_stat_side_slot_width_ratio") and _has_property(theme, "ui_top_tray_stat_center_slot_width_ratio"):
			var side_ratio := float(theme.get("ui_top_tray_stat_side_slot_width_ratio"))
			var center_ratio := float(theme.get("ui_top_tray_stat_center_slot_width_ratio"))
			passed = passed and _assert_true(side_ratio > 0.0, "Top tray side stat slot ratio should be positive")
			passed = passed and _assert_true(center_ratio > 0.0, "Top tray center stat slot ratio should be positive")
			passed = passed and _assert_true(abs((side_ratio * 2.0 + center_ratio) - 1.0) <= 0.001, "Top tray stat slot ratios should fill the stats capsule exactly")
		if _has_property(theme, "ui_top_tray_logo_size") and _has_property(theme, "ui_top_tray_logo_center_y_ratio"):
			passed = passed and _assert_true(float(theme.get("ui_top_tray_logo_size")) >= 80.0, "Top tray logo should be large enough to read in the center socket")
			passed = passed and _assert_true(float(theme.get("ui_top_tray_logo_center_y_ratio")) >= 0.52, "Top tray logo center should sit inside the tray body, not hang on the top edge")
		if _has_property(theme, "ui_landscape_board_top_tray_gap") and _has_property(theme, "ui_landscape_board_bottom_safe_margin"):
			passed = passed and _assert_true(float(theme.get("ui_landscape_board_top_tray_gap")) >= 0.0, "Landscape top tray board gap should be non-negative")
			passed = passed and _assert_true(float(theme.get("ui_landscape_board_bottom_safe_margin")) >= 0.0, "Landscape board bottom safe margin should be non-negative")
		if _has_property(theme, "ui_top_tray_regions"):
			var regions: Dictionary = theme.get("ui_top_tray_regions")
			var source_size: Vector2 = theme.get("ui_top_tray_region_source_size") if _has_property(theme, "ui_top_tray_region_source_size") else Vector2.ZERO
			var pixel_rects: Dictionary = theme.get("ui_top_tray_region_pixel_rects") if _has_property(theme, "ui_top_tray_region_pixel_rects") else {}
			passed = passed and _assert_true(source_size.x > 0.0 and source_size.y > 0.0, "Top tray region source size should be positive")
			passed = passed and _assert_true(not regions.has("stats_readout"), "Top tray stats should be split into left_stats_readout and right_stats_readout, not one combined stats_readout")
			for region_key in ["left_stats_readout", "right_stats_readout", "logo_core", "left_floating_menu", "left_floating_menu_icon", "right_floating_replay", "right_floating_replay_icon", "total_play_time_readout"]:
				passed = passed and _assert_true(regions.has(region_key), "Top tray regions should include %s" % region_key)
				passed = passed and _assert_true(pixel_rects.has(region_key), "Top tray pixel rects should include %s" % region_key)
				if regions.has(region_key):
					var rect = regions[region_key]
					passed = passed and _assert_true(rect is Vector4, "%s region should be a Vector4" % region_key)
					if rect is Vector4:
						passed = passed and _assert_true(rect.z > 0.0 and rect.w > 0.0, "%s region size should be positive" % region_key)
						if pixel_rects.has(region_key) and source_size.x > 0.0 and source_size.y > 0.0:
							var pixel_rect = pixel_rects[region_key]
							passed = passed and _assert_true(pixel_rect is Vector4, "%s pixel rect should be a Vector4" % region_key)
							if pixel_rect is Vector4:
								var expected := Vector4(
									round(rect.x * source_size.x),
									round(rect.y * source_size.y),
									round(rect.z * source_size.x),
									round(rect.w * source_size.y)
								)
								passed = passed and _assert_equal(pixel_rect, expected, "%s pixel rect should match normalized SSOT and source canvas size" % region_key)
		if _has_property(theme, "ui_top_tray_region_sets"):
			var region_sets: Dictionary = theme.get("ui_top_tray_region_sets")
			var source_sizes: Dictionary = theme.get("ui_top_tray_region_source_sizes") if _has_property(theme, "ui_top_tray_region_source_sizes") else {}
			var pixel_rect_sets: Dictionary = theme.get("ui_top_tray_region_pixel_rect_sets") if _has_property(theme, "ui_top_tray_region_pixel_rect_sets") else {}
			for mode in ["dark", "light"]:
				passed = passed and _assert_true(region_sets.has(mode), "Top tray region sets should include %s" % mode)
				passed = passed and _assert_true(source_sizes.has(mode), "Top tray region source sizes should include %s" % mode)
				passed = passed and _assert_true(pixel_rect_sets.has(mode), "Top tray region pixel rect sets should include %s" % mode)
				if region_sets.has(mode) and source_sizes.has(mode) and pixel_rect_sets.has(mode):
					var mode_regions: Dictionary = region_sets[mode]
					var mode_source_size: Vector2 = source_sizes[mode]
					var mode_pixel_rects: Dictionary = pixel_rect_sets[mode]
					passed = passed and _assert_true(mode_source_size.x > 0.0 and mode_source_size.y > 0.0, "%s top tray region source size should be positive" % mode)
					for region_key in ["left_stats_readout", "right_stats_readout", "logo_core", "left_floating_menu", "left_floating_menu_icon", "right_floating_replay", "right_floating_replay_icon", "total_play_time_readout"]:
						passed = passed and _assert_true(mode_regions.has(region_key), "%s top tray regions should include %s" % [mode, region_key])
						passed = passed and _assert_true(mode_pixel_rects.has(region_key), "%s top tray pixel rects should include %s" % [mode, region_key])
						if mode_regions.has(region_key) and mode_pixel_rects.has(region_key):
							var mode_rect = mode_regions[region_key]
							var mode_pixel_rect = mode_pixel_rects[region_key]
							passed = passed and _assert_true(mode_rect is Vector4, "%s %s region should be a Vector4" % [mode, region_key])
							passed = passed and _assert_true(mode_pixel_rect is Vector4, "%s %s pixel rect should be a Vector4" % [mode, region_key])
							if mode_rect is Vector4 and mode_pixel_rect is Vector4:
								var expected_mode := Vector4(
									round(mode_rect.x * mode_source_size.x),
									round(mode_rect.y * mode_source_size.y),
									round(mode_rect.z * mode_source_size.x),
									round(mode_rect.w * mode_source_size.y)
								)
								passed = passed and _assert_equal(mode_pixel_rect, expected_mode, "%s %s pixel rect should match normalized SSOT and source canvas size" % [mode, region_key])
		if _has_property(theme, "ui_playboard_region_sets"):
			var playboard_region_sets: Dictionary = theme.get("ui_playboard_region_sets")
			var playboard_source_sizes: Dictionary = theme.get("ui_playboard_region_source_sizes") if _has_property(theme, "ui_playboard_region_source_sizes") else {}
			var playboard_pixel_rect_sets: Dictionary = theme.get("ui_playboard_region_pixel_rect_sets") if _has_property(theme, "ui_playboard_region_pixel_rect_sets") else {}
			for mode in ["dark", "light"]:
				passed = passed and _assert_true(playboard_region_sets.has(mode), "Playboard regions should include %s mode after owner approval" % mode)
				passed = passed and _assert_true(playboard_pixel_rect_sets.has(mode), "Playboard pixel rects should include %s mode after owner approval" % mode)
			passed = passed and _assert_true(playboard_source_sizes.has("landscape"), "Playboard source sizes should include landscape basis")
			passed = passed and _assert_true(playboard_source_sizes.has("portrait"), "Playboard source sizes should include portrait basis")
			for mode in ["dark", "light"]:
				if playboard_region_sets.has(mode) and playboard_pixel_rect_sets.has(mode):
					var mode_playboard: Dictionary = playboard_region_sets[mode]
					var mode_playboard_pixels: Dictionary = playboard_pixel_rect_sets[mode]
					for orientation in ["portrait", "landscape"]:
						passed = passed and _assert_true(playboard_source_sizes.has(orientation), "Playboard source sizes should include %s basis" % orientation)
						passed = passed and _assert_true(mode_playboard.has(orientation), "%s playboard regions should include %s" % [mode, orientation])
						passed = passed and _assert_true(mode_playboard_pixels.has(orientation), "%s playboard pixel rects should include %s" % [mode, orientation])
						if mode_playboard.has(orientation) and mode_playboard_pixels.has(orientation) and playboard_source_sizes.has(orientation):
							var orientation_regions: Dictionary = mode_playboard[orientation]
							var orientation_pixels: Dictionary = mode_playboard_pixels[orientation]
							var orientation_source: Vector2 = playboard_source_sizes[orientation]
							for region_key in ["board_backplate_rect", "playboard_rect"]:
								passed = passed and _assert_true(orientation_regions.has(region_key), "%s %s playboard regions should include %s" % [mode, orientation, region_key])
								passed = passed and _assert_true(orientation_pixels.has(region_key), "%s %s playboard pixel rects should include %s" % [mode, orientation, region_key])
								if orientation_regions.has(region_key) and orientation_pixels.has(region_key):
									var rect = orientation_regions[region_key]
									var pixel_rect = orientation_pixels[region_key]
									passed = passed and _assert_true(rect is Vector4, "%s %s %s should be a Vector4" % [mode, orientation, region_key])
									passed = passed and _assert_true(pixel_rect is Vector4, "%s %s %s pixel rect should be a Vector4" % [mode, orientation, region_key])
									if rect is Vector4 and pixel_rect is Vector4:
										var expected_playboard := Vector4(
											round(rect.x * orientation_source.x),
											round(rect.y * orientation_source.y),
											round(rect.z * orientation_source.x),
											round(rect.w * orientation_source.y)
										)
										passed = passed and _assert_equal(pixel_rect, expected_playboard, "%s %s %s pixel rect should match normalized SSOT and source viewport" % [mode, orientation, region_key])
		var paths: Dictionary = theme.get("ui_generated_asset_paths")
		for mode in ["dark", "light"]:
			passed = passed and _assert_true(paths.has(mode), "UI asset paths should include %s mode" % mode)
			var mode_paths: Dictionary = paths.get(mode, {})
			for key in REQUIRED_KEYS:
				passed = passed and _assert_true(mode_paths.has(key), "%s should define %s" % [mode, key])
				if mode_paths.has(key):
					var path := String(mode_paths[key])
					passed = passed and _assert_true(path.begins_with("res://Assets/UI/cyberpunk_theme/generated/production/%s/" % mode), "%s %s should use canonical generated UI root" % [mode, key])
					passed = passed and _assert_true(FileAccess.file_exists(path), "%s %s should exist at %s" % [mode, key, path])
					passed = passed and _assert_equal(theme.get_ui_generated_asset_path(mode, key), path, "%s %s helper should return SSOT path" % [mode, key])

	if theme != null and _has_property(theme, "ui_generated_asset_geometry"):
		if _has_property(theme, "ui_top_tray_time_font_path"):
			passed = passed and _assert_true(FileAccess.file_exists(String(theme.get("ui_top_tray_time_font_path"))), "Top tray time font path should exist")
		var geometry: Dictionary = theme.get("ui_generated_asset_geometry")
		for key in REQUIRED_KEYS:
			passed = passed and _assert_true(geometry.has(key), "UI geometry should define %s" % key)
			if geometry.has(key):
				var item: Dictionary = geometry[key]
				passed = passed and _assert_true(item.has("anchor"), "%s geometry should store anchor" % key)
				passed = passed and _assert_true(item.has("scale_policy"), "%s geometry should store scale policy" % key)
				if key != "background_full_portrait" and key != "background_full_landscape":
					passed = passed and _assert_true(item.has("alpha_bbox"), "%s geometry should store alpha bbox for object placement" % key)
				if key == "top_tray_layer":
					passed = passed and _assert_true(item.has("source_size"), "top_tray_layer geometry should store full source canvas size")
				if key == "floating_menu_button_default" or key == "floating_replay_button_default":
					passed = passed and _assert_equal(String(item.get("runtime_region", "")), "alpha_bbox", "%s should render the PhotoRoom-trimmed baked-icon PNG from its alpha bbox" % key)
					passed = passed and _assert_equal(String(item.get("icon_policy", "")), "baked_texture", "%s should own its icon inside the generated button texture" % key)
				if key == "modal_frame":
					passed = passed and _assert_true(item.has("runtime_stretch_mode"), "modal_frame geometry should store runtime stretch mode")
					passed = passed and _assert_equal(String(item.get("runtime_stretch_mode", "")), "scale", "modal_frame should scale until 9-slice slicing is implemented")
				if key == "profile_username_field_frame":
					passed = passed and _assert_equal(String(item.get("anchor", "")), "profile.username_field", "Username field frame should be profile-specific, not a top tray stats capsule")
					passed = passed and _assert_equal(String(item.get("runtime_region", "")), "alpha_bbox", "Username field frame should use a trimmed single-field crop")

	if theme != null and theme.has_method("validate_ui_generated_assets"):
		var errors: Array = theme.validate_ui_generated_assets()
		passed = passed and _assert_equal(errors, [], "Generated UI asset validation should pass")

	if passed:
		print("test_theme_ui_asset_ssot: PASS")
		quit(0)
	else:
		print("test_theme_ui_asset_ssot: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

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
