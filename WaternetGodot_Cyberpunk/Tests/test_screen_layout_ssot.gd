extends SceneTree

const LEVEL_SELECT_PATH := "res://Scenes/Main/LevelSelect.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var theme: ThemeConfig = load(THEME_PATH)
	var scene: PackedScene = load(LEVEL_SELECT_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(scene != null, "LevelSelect scene should load")
	if theme != null:
		for property_name in [
			"ui_level_select_button_font_size",
			"ui_level_select_locked_alpha",
			"ui_level_select_pagination_button_width",
			"ui_level_select_grid_h_separation",
			"ui_level_select_grid_v_separation"
		]:
			passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)

	var level_select_source := FileAccess.get_file_as_string("res://Scenes/Main/LevelSelect.gd")
	var main_menu_source := FileAccess.get_file_as_string("res://Scenes/Main/MainMenu.gd")
	var profile_popup_source := FileAccess.get_file_as_string("res://Scenes/Common/ProfilePopup.gd")
	var game_scene_source := FileAccess.get_file_as_string("res://Scenes/Gameplay/GameScene.gd")
	var splash_source := FileAccess.get_file_as_string("res://Scenes/Common/Splash.gd")
	passed = passed and _assert_true(not level_select_source.contains("font_size\", 24"), "LevelSelect button font size should come from ThemeConfig")
	passed = passed and _assert_true(not level_select_source.contains("modulate.a = 0.4"), "LevelSelect locked alpha should come from ThemeConfig")
	passed = passed and _assert_true(level_select_source.contains("ui_level_select_grid_h_separation"), "LevelSelect grid separation should use ThemeConfig")
	passed = passed and _assert_true(level_select_source.contains("ui_level_select_pagination_button_width"), "LevelSelect pagination size should use ThemeConfig")
	passed = passed and _assert_true(level_select_source.contains("ui_level_select_title_font_size"), "LevelSelect title font should use ThemeConfig")
	passed = passed and _assert_true(level_select_source.contains("ui_level_select_gap"), "LevelSelect container gap should use ThemeConfig")
	passed = passed and _assert_true(level_select_source.contains("ui_level_select_pagination_gap"), "LevelSelect pagination gap should use ThemeConfig")
	passed = passed and _assert_true(not main_menu_source.contains("play_button_height - 10.0"), "MainMenu secondary button height should come from ThemeConfig")
	passed = passed and _assert_true(main_menu_source.contains("ui_main_menu_secondary_button_height"), "MainMenu should use ThemeConfig secondary button height")
	passed = passed and _assert_true(main_menu_source.contains("ui_main_menu_title_font_size"), "MainMenu title font should use ThemeConfig")
	passed = passed and _assert_true(main_menu_source.contains("ui_main_menu_logo_size"), "MainMenu logo size should use ThemeConfig")
	passed = passed and _assert_true(main_menu_source.contains("ui_main_menu_gap"), "MainMenu gap should use ThemeConfig")
	passed = passed and _assert_true(not profile_popup_source.contains("font_size\", 18"), "ProfilePopup score font size should come from ThemeConfig")
	passed = passed and _assert_true(profile_popup_source.contains("ui_profile_popup_score_font_size"), "ProfilePopup should use ThemeConfig score font size")
	passed = passed and _assert_true(profile_popup_source.contains("ui_profile_popup_title_font_size"), "ProfilePopup title font should use ThemeConfig")
	passed = passed and _assert_true(profile_popup_source.contains("ui_profile_popup_content_margin_x"), "ProfilePopup content margins should use ThemeConfig")
	passed = passed and _assert_true(not profile_popup_source.contains(" - 8.0"), "ProfilePopup close padding should come from ThemeConfig")
	passed = passed and _assert_true(profile_popup_source.contains("ui_modal_close_button_padding"), "ProfilePopup should use ThemeConfig close padding")
	passed = passed and _assert_true(not game_scene_source.contains(" - 8.0"), "GameScene close padding should come from ThemeConfig")
	passed = passed and _assert_true(game_scene_source.contains("ui_modal_close_button_padding"), "GameScene should use ThemeConfig close padding")
	passed = passed and _assert_true(game_scene_source.contains("ui_modal_content_margin_x"), "GameScene modal content margins should use ThemeConfig")
	passed = passed and _assert_true(splash_source.contains("ui_splash_fade_in_duration"), "Splash fade in should use ThemeConfig")
	passed = passed and _assert_true(splash_source.contains("ui_splash_hold_duration"), "Splash hold duration should use ThemeConfig")
	passed = passed and _assert_true(splash_source.contains("ui_splash_fade_out_duration"), "Splash fade out should use ThemeConfig")
	passed = passed and _assert_true(splash_source.contains("ui_splash_studio_font_size"), "Splash studio font should use ThemeConfig")

	if scene != null and theme != null:
		for viewport_size in [Vector2i(1280, 720), Vector2i(720, 1280)]:
			root.size = viewport_size
			var instance := scene.instantiate()
			root.add_child(instance)
			await process_frame
			if instance.has_method("_on_theme_changed"):
				instance._on_theme_changed(theme.theme_name, theme)
			if instance.has_method("_populate_levels_grid"):
				instance._populate_levels_grid()
			await process_frame
			await process_frame
			var grid := instance.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/GridCenter/GridContainer") as GridContainer
			var pagination := instance.get_node_or_null("MarginContainer/VBoxContainer/HBoxPagination") as Control
			var back_btn := instance.get_node_or_null("MarginContainer/VBoxContainer/BackBtn") as Button
			var screen_rect := (instance as Control).get_global_rect()
			passed = passed and _assert_true(grid != null, "LevelSelect grid should live inside GridCenter")
			if grid != null:
				passed = passed and _assert_centered_x(grid.get_global_rect(), screen_rect, 4.0, "LevelSelect grid should be horizontally centered for %s" % str(viewport_size))
			if pagination != null:
				passed = passed and _assert_centered_x(pagination.get_global_rect(), screen_rect, 4.0, "LevelSelect pagination should be horizontally centered for %s" % str(viewport_size))
			if back_btn != null:
				passed = passed and _assert_centered_x(back_btn.get_global_rect(), screen_rect, 4.0, "LevelSelect back button should be horizontally centered for %s" % str(viewport_size))
			root.remove_child(instance)
			instance.free()
			await process_frame
		_stop_audio()

	if passed:
		print("test_screen_layout_ssot: PASS")
		quit(0)
	else:
		print("test_screen_layout_ssot: FAIL")
		quit(1)

func _assert_centered_x(rect: Rect2, screen_rect: Rect2, tolerance: float, message: String) -> bool:
	var expected_center := screen_rect.position.x + screen_rect.size.x * 0.5
	var actual_center := rect.position.x + rect.size.x * 0.5
	if abs(actual_center - expected_center) > tolerance:
		push_error("%s: expected center %s, got %s rect=%s" % [message, str(expected_center), str(actual_center), str(rect)])
		return false
	return true

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _stop_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music()
		var music_player = audio_manager.get("_music_player")
		if music_player is AudioStreamPlayer:
			(music_player as AudioStreamPlayer).stream = null
