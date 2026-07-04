extends SceneTree

const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const GAME_SCENE_SCRIPT := "res://Scenes/Gameplay/GameScene.gd"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var scene: PackedScene = load(GAME_SCENE_PATH)
	var base_theme: ThemeConfig = load(THEME_PATH)
	var source := FileAccess.get_file_as_string(GAME_SCENE_SCRIPT)
	passed = passed and _assert_true(scene != null, "GameScene should load")
	passed = passed and _assert_true(base_theme != null, "Cyber theme should load")
	passed = passed and _assert_true(source.contains("UI_MODE_SAVE_KEY"), "Theme mode setting should have one save key")
	passed = passed and _assert_true(source.contains("_on_settings_theme_mode_btn_pressed"), "Settings theme mode button should have a handler")
	passed = passed and _assert_true(source.contains("settings_theme_mode_btn"), "Settings theme mode button should have one script reference")
	if scene != null and base_theme != null:
		var theme: ThemeConfig = base_theme.duplicate(true)
		theme.ui_generated_asset_mode = "dark"
		var instance = scene.instantiate()
		instance.active_theme_override = theme
		root.add_child(instance)
		await process_frame

		var theme_button := instance.get_node_or_null("HUD/SettingsOverlay/MarginContainer/VBoxContainer/ThemeModeBtn") as Button
		passed = passed and _assert_true(theme_button != null, "Settings modal should include ThemeModeBtn")
		passed = passed and _assert_true(instance.has_method("_on_settings_theme_mode_btn_pressed"), "GameScene should expose theme mode toggle handler")
		if theme_button != null:
			passed = passed and _assert_signal_connected(theme_button, instance, "_on_settings_theme_mode_btn_pressed", "ThemeModeBtn pressed signal should connect to handler")

		if instance.has_method("_on_settings_theme_mode_btn_pressed"):
			instance._on_settings_theme_mode_btn_pressed()
			await process_frame
			passed = passed and _assert_equal(theme.ui_generated_asset_mode, "light", "Theme mode toggle should switch dark to light")
			passed = passed and _assert_true(theme_button == null or theme_button.text.to_upper().contains("LIGHT"), "Theme button label should show active light mode")
			instance._apply_generated_ui_assets(theme)
			instance._apply_top_tray_theme(theme, Vector2(1280, 720))
			instance._recalculate_layout_for_safe_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)))
			passed = passed and _assert_rect_close(instance.get_board_rect(), Rect2(422.176, 186.99984, 421.89312, 421.89312), 1.0, "Light landscape board rect should be active after toggle")
			instance._on_settings_theme_mode_btn_pressed()
			await process_frame
			passed = passed and _assert_equal(theme.ui_generated_asset_mode, "dark", "Theme mode toggle should switch light to dark")

		root.remove_child(instance)
		instance.free()
		await process_frame
		_stop_audio()

	if passed:
		print("test_settings_theme_mode_toggle: PASS")
		quit(0)
	else:
		print("test_settings_theme_mode_toggle: FAIL")
		quit(1)

func _assert_signal_connected(button: Button, target: Object, method_name: String, message: String) -> bool:
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable")
		if callable.get_object() == target and callable.get_method() == method_name:
			return true
	push_error("%s: expected pressed -> %s" % [message, method_name])
	return false

func _assert_rect_close(actual: Rect2, expected: Rect2, tolerance: float, message: String) -> bool:
	if actual.position.distance_to(expected.position) > tolerance or actual.size.distance_to(expected.size) > tolerance:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

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

func _stop_audio() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music()
		var music_player = audio_manager.get("_music_player")
		if music_player is AudioStreamPlayer:
			(music_player as AudioStreamPlayer).stream = null
