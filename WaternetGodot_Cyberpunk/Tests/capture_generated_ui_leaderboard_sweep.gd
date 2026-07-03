extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const CAPTURES = [
	{
		"mode": "dark",
		"size": Vector2i(720, 1280),
		"path": "res://debug/generated_ui_leaderboard_dark_portrait.png"
	},
	{
		"mode": "dark",
		"size": Vector2i(1280, 720),
		"path": "res://debug/generated_ui_leaderboard_dark_landscape.png"
	},
	{
		"mode": "light",
		"size": Vector2i(720, 1280),
		"path": "res://debug/generated_ui_leaderboard_light_portrait.png"
	},
	{
		"mode": "light",
		"size": Vector2i(1280, 720),
		"path": "res://debug/generated_ui_leaderboard_light_landscape.png"
	}
]

var scene = null
var theme: ThemeConfig = null
var capture_index := 0
var frame_count := 0
var passed := true

func _init() -> void:
	root.size = CAPTURES[0]["size"]

func _process(_delta: float):
	frame_count += 1
	if scene == null:
		_setup_scene()
		_prepare_capture(0)
		return
	if frame_count < 18:
		if scene != null:
			if scene.has_method("_recalculate_layout"):
				scene._recalculate_layout()
			scene.queue_redraw()
		return
	_capture_current()
	capture_index += 1
	if capture_index >= CAPTURES.size():
		_cleanup()
		if passed:
			for capture in CAPTURES:
				print("capture_generated_ui_leaderboard_sweep: %s" % String(capture["path"]))
			print("capture_generated_ui_leaderboard_sweep: PASS")
			quit(0)
		else:
			print("capture_generated_ui_leaderboard_sweep: FAIL")
			quit(1)
		return
	_prepare_capture(capture_index)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level_id = 16
	theme = load(THEME_PATH).duplicate(true) as ThemeConfig
	scene = load(GAME_SCENE_PATH).instantiate()
	scene.active_theme_override = theme
	root.add_child(scene)

func _prepare_capture(index: int) -> void:
	var capture: Dictionary = CAPTURES[index]
	root.size = capture["size"]
	if theme != null:
		theme.ui_generated_asset_mode = String(capture["mode"])
	if scene != null:
		if scene.has_method("_apply_top_tray_theme"):
			scene._apply_top_tray_theme(theme)
		if scene.has_method("_apply_generated_ui_assets"):
			scene._apply_generated_ui_assets(theme)
		var leaderboard_root = scene.get_node_or_null("HUD/LeaderboardOverlayRoot")
		if leaderboard_root != null and leaderboard_root.get_child_count() == 0 and scene.has_method("_on_leaderboard_btn_pressed"):
			scene._on_leaderboard_btn_pressed()
		if leaderboard_root != null:
			leaderboard_root.visible = true
			if leaderboard_root.get_child_count() == 1 and scene.has_method("_configure_leaderboard_popup"):
				scene._configure_leaderboard_popup(leaderboard_root.get_child(0), theme)
		if scene.has_method("_recalculate_layout"):
			scene._recalculate_layout()
		scene.queue_redraw()
	frame_count = 0

func _capture_current() -> void:
	var capture: Dictionary = CAPTURES[capture_index]
	_capture(String(capture["path"]), String(capture["mode"]))

func _capture(path: String, mode: String) -> void:
	if scene == null:
		_fail("Scene should exist")
		return
	var leaderboard_root = scene.get_node_or_null("HUD/LeaderboardOverlayRoot")
	_assert_true(leaderboard_root != null, "Leaderboard root should exist")
	_assert_true(leaderboard_root != null and leaderboard_root.visible, "Leaderboard root should be visible")
	_assert_true(leaderboard_root != null and leaderboard_root.get_child_count() == 1, "Leaderboard root should contain one popup")
	if leaderboard_root != null and leaderboard_root.get_child_count() == 1:
		var popup = leaderboard_root.get_child(0)
		_assert_true(popup.get_node_or_null("GeneratedModalFrame") is TextureRect, "Leaderboard popup should use generated modal frame")
	var image := root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null")
		return
	_assert_true(_image_has_variation(image), "Generated leaderboard capture should not be blank")
	var err := image.save_png(path)
	if err != OK:
		_fail("Failed to save %s mode=%s: %s" % [path, mode, str(err)])

func _image_has_variation(image: Image) -> bool:
	var base := image.get_pixel(0, 0)
	for y in range(0, image.get_height(), max(1, image.get_height() / 10)):
		for x in range(0, image.get_width(), max(1, image.get_width() / 10)):
			if abs(base.r - image.get_pixel(x, y).r) + abs(base.g - image.get_pixel(x, y).g) + abs(base.b - image.get_pixel(x, y).b) > 0.05:
				return true
	return false

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail("%s: expected true" % message)

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		root.remove_child(scene)
		scene.free()
		scene = null
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music()
		var music_player = audio_manager.get("_music_player")
		if music_player is AudioStreamPlayer:
			(music_player as AudioStreamPlayer).stream = null
