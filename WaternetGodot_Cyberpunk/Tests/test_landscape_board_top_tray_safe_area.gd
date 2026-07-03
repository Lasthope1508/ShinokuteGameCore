extends SceneTree

const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var scene: PackedScene = load(GAME_SCENE_PATH)
	var theme: ThemeConfig = load(THEME_PATH)
	passed = passed and _assert_true(scene != null, "GameScene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if scene != null and theme != null:
		var instance = scene.instantiate()
		instance.active_theme_override = theme
		root.add_child(instance)
		await process_frame
		instance._apply_generated_ui_assets(theme)
		var viewport_size: Vector2 = Vector2(1280.0, 720.0)
		instance._apply_top_tray_theme(theme, viewport_size)
		instance._recalculate_layout_for_safe_rect(Rect2(Vector2.ZERO, viewport_size))
		var board_rect: Rect2 = instance.get_board_rect()
		var icon_bottom: float = max(
			_get_visible_button_icon_bottom(instance.left_floating_menu),
			_get_visible_button_icon_bottom(instance.right_floating_replay)
		)
		var expected_gap: float = max(theme.ui_top_tray_board_gap, theme.ui_landscape_board_top_tray_gap)
		passed = passed and _assert_true(
			board_rect.position.y >= icon_bottom + expected_gap - 1.0,
			"Landscape board should sit below top tray icons board=%s icon_bottom=%s gap=%s" % [str(board_rect), str(icon_bottom), str(expected_gap)]
		)
		passed = passed and _assert_true(
			board_rect.end.y <= viewport_size.y - theme.ui_landscape_board_bottom_safe_margin + 1.0,
			"Landscape board should fit bottom safe margin board=%s viewport=%s margin=%s" % [str(board_rect), str(viewport_size), str(theme.ui_landscape_board_bottom_safe_margin)]
		)
		root.remove_child(instance)
		instance.free()
		var audio_manager := root.get_node_or_null("AudioManager")
		if audio_manager != null and audio_manager.has_method("stop_music"):
			audio_manager.stop_music()
			var music_player = audio_manager.get("_music_player")
			if music_player is AudioStreamPlayer:
				(music_player as AudioStreamPlayer).stream = null
		await process_frame
	if passed:
		print("test_landscape_board_top_tray_safe_area: PASS")
		quit(0)
	else:
		print("test_landscape_board_top_tray_safe_area: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _get_visible_button_icon_bottom(button: Button) -> float:
	if button == null:
		return 0.0
	var icon_rect := button.get_node_or_null("GeneratedButtonIcon") as Control
	if icon_rect != null and icon_rect.visible:
		return icon_rect.get_global_rect().end.y
	return button.get_global_rect().end.y
