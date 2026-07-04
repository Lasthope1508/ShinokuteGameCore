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
		var cases := [
			{
				"mode": "dark",
				"size": Vector2(720, 1280),
				"board": Rect2(34.00016, 288.0, 651.99968, 651.99968),
				"backplate": Rect2(0.0, 265.99936, 720.0, 696.0)
			},
			{
				"mode": "dark",
				"size": Vector2(1280, 720),
				"board": Rect2(416.99968, 164.99976, 447.0, 447.0),
				"backplate": Rect2(390.00064, 149.99976, 500.99968, 477.0)
			},
			{
				"mode": "light",
				"size": Vector2(720, 1280),
				"board": Rect2(20.00016, 288.0, 679.99968, 679.99968),
				"backplate": Rect2(0.0, 266.24, 720.0, 723.52)
			},
			{
				"mode": "light",
				"size": Vector2(1280, 720),
				"board": Rect2(422.176, 186.99984, 421.89312, 421.89312),
				"backplate": Rect2(408.67456, 174.00024, 448.89472, 448.8948)
			}
		]
		for playboard_case in cases:
			theme.ui_generated_asset_mode = String(playboard_case["mode"])
			root.size = playboard_case["size"]
			var instance = scene.instantiate()
			instance.active_theme_override = theme
			root.add_child(instance)
			await process_frame
			instance._apply_generated_ui_assets(theme)
			instance._apply_top_tray_theme(theme, playboard_case["size"])
			instance._recalculate_layout_for_safe_rect(Rect2(Vector2.ZERO, playboard_case["size"]))
			var label := "%s %s" % [String(playboard_case["mode"]), "landscape" if playboard_case["size"].x > playboard_case["size"].y else "portrait"]
			passed = passed and _assert_rect_close(instance.get_board_rect(), playboard_case["board"], 1.0, "%s board rect should use owner-approved playboard SSOT" % label)
			passed = passed and _assert_rect_close(instance.get_board_backplate_rect(), playboard_case["backplate"], 1.0, "%s backplate rect should use owner-approved backplate SSOT" % label)
			root.remove_child(instance)
			instance.free()
			await process_frame
		_stop_audio()
	if passed:
		print("test_playboard_region_ssot: PASS")
		quit(0)
	else:
		print("test_playboard_region_ssot: FAIL")
		quit(1)

func _assert_rect_close(actual: Rect2, expected: Rect2, tolerance: float, message: String) -> bool:
	if actual.position.distance_to(expected.position) > tolerance or actual.size.distance_to(expected.size) > tolerance:
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
