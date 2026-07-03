extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const CAPTURES = [
	{
		"mode": "dark",
		"size": Vector2i(720, 1280),
		"path": "res://debug/generated_ui_layout_dark_portrait.png",
		"alias": "res://debug/generated_ui_layout_portrait.png"
	},
	{
		"mode": "dark",
		"size": Vector2i(1280, 720),
		"path": "res://debug/generated_ui_layout_dark_landscape.png",
		"alias": "res://debug/generated_ui_layout_landscape.png"
	},
	{
		"mode": "light",
		"size": Vector2i(720, 1280),
		"path": "res://debug/generated_ui_layout_light_portrait.png",
		"alias": ""
	},
	{
		"mode": "light",
		"size": Vector2i(1280, 720),
		"path": "res://debug/generated_ui_layout_light_landscape.png",
		"alias": ""
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
	if frame_count < 12:
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
				print("capture_generated_ui_layout_sweep: %s" % String(capture["path"]))
				if not String(capture["alias"]).is_empty():
					print("capture_generated_ui_layout_sweep: %s" % String(capture["alias"]))
			print("capture_generated_ui_layout_sweep: PASS")
			quit(0)
		else:
			print("capture_generated_ui_layout_sweep: FAIL")
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
		if scene.has_method("_recalculate_layout"):
			scene._recalculate_layout()
		scene.queue_redraw()
	frame_count = 0

func _capture_current() -> void:
	var capture: Dictionary = CAPTURES[capture_index]
	_capture(String(capture["path"]), String(capture["alias"]), String(capture["mode"]))

func _capture(path: String, alias_path: String, mode: String) -> void:
	if scene == null:
		_fail("Scene should exist")
		return
	var board_rect: Rect2 = scene.get_board_rect()
	var viewport_size: Vector2 = scene.get_viewport_rect().size
	var active_theme = scene._get_active_theme() if scene.has_method("_get_active_theme") else null
	print("capture_generated_ui_layout_sweep metrics mode=%s path=%s viewport=%s board=%s cell=%s grid=%sx%s top_margin=%s bottom_margin=%s" % [
		mode,
		path,
		str(viewport_size),
		str(board_rect),
		str(scene.CELL_SIZE),
		str(scene.grid.width if scene.grid != null else -1),
		str(scene.grid.height if scene.grid != null else -1),
		str(active_theme.game_top_margin if active_theme != null else -1),
		str(active_theme.game_bottom_margin if active_theme != null else -1)
	])
	_assert_true(board_rect.position.x >= 0.0 and board_rect.position.y >= 0.0, "Board should start inside viewport")
	_assert_true(board_rect.end.x <= viewport_size.x, "Board should fit viewport width")
	_assert_true(board_rect.end.y <= viewport_size.y, "Board should fit viewport height")
	var top_tray_layer = scene.get_node_or_null("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer")
	var stats_capsule = scene.get_node_or_null("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/StatsCapsule")
	var logo_core = scene.get_node_or_null("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LogoCore")
	var bottom_reserve_layer = scene.get_node_or_null("HUD/BottomReserveLayer")
	_assert_true(top_tray_layer != null and top_tray_layer.get_node_or_null("GeneratedTopTrayLayer") is TextureRect, "Top tray generated texture should exist")
	_assert_true(stats_capsule != null and stats_capsule.get_node_or_null("GeneratedStatsCapsule") == null, "Legacy stats capsule should not draw generated object children")
	_assert_true(top_tray_layer != null and top_tray_layer.get_node_or_null("GeneratedStatsCapsule") == null, "Stats capsule object should stay inactive unless enabled by top tray stack SSOT")
	_assert_true(top_tray_layer != null and top_tray_layer.get_node_or_null("GeneratedLogoSocket") == null, "Logo socket object should stay inactive unless enabled by top tray stack SSOT")
	_assert_true(bottom_reserve_layer != null and bottom_reserve_layer.get_node_or_null("GeneratedBottomReserveLayer") is TextureRect, "Bottom tray generated texture should exist")
	if bottom_reserve_layer is Control:
		var bottom_rect := (bottom_reserve_layer as Control).get_global_rect()
		_assert_true(board_rect.end.y <= bottom_rect.position.y - 2.0, "Board should not overlap generated bottom tray")
	_assert_true(logo_core != null and logo_core.visible and _uses_project_logo_texture(logo_core), "Top tray should render approved project logo")
	var image := root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null")
		return
	_assert_true(_image_has_variation(image), "Generated UI capture should not be blank")
	var err := image.save_png(path)
	if err != OK:
		_fail("Failed to save %s: %s" % [path, str(err)])
	if not alias_path.is_empty():
		var alias_err := image.save_png(alias_path)
		if alias_err != OK:
			_fail("Failed to save %s: %s" % [alias_path, str(alias_err)])

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

func _uses_project_logo_texture(texture_rect: TextureRect) -> bool:
	if texture_rect == null or texture_rect.texture == null:
		return false
	if texture_rect.texture.resource_path == "res://Assets/Icons/logo.png":
		return true
	if texture_rect.texture is AtlasTexture:
		var atlas := texture_rect.texture as AtlasTexture
		return atlas.atlas != null and atlas.atlas.resource_path == "res://Assets/Icons/logo.png" and atlas.region.size.x > 0.0 and atlas.region.size.y > 0.0
	return false

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
