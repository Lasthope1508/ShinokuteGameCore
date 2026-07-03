extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")

var scene = null
var theme = null
var frame_count := 0

func _init() -> void:
	root.size = Vector2i(720, 720)

func _process(_delta: float):
	frame_count += 1
	if scene == null:
		theme = load(THEME_PATH).duplicate(true)
		theme.ui_generated_asset_mode = "dark"
		scene = load(GAME_SCENE_PATH).instantiate()
		scene.active_theme_override = theme
		root.add_child(scene)
		return
	if frame_count == 4:
		var test_grid = PipeGridScript.new()
		test_grid.initialize({
			"width": 5,
			"height": 5,
			"source": {"x": 0, "y": 0, "ports": [false, false, false, false]},
			"target": {"x": 4, "y": 4, "ports": [false, false, false, false]},
			"grid": []
		})
		scene.grid = test_grid
		scene.CELL_SIZE = 96.0
		scene.GRID_OFFSET = Vector2(120.0, 120.0)
		scene.queue_redraw()
	if frame_count < 12:
		return
	var image := root.get_texture().get_image()
	if image == null:
		_assert_cell_texture_not_white(theme, scene)
		return
	var sample := image.get_pixel(168, 168)
	var is_white := sample.r > 0.92 and sample.g > 0.92 and sample.b > 0.92
	if is_white:
		print("test_game_scene_cell_texture_visible: FAIL sample=%s white_cells=%s has_textures=%s path=%s" % [
			str(sample),
			str(scene.debug_white_cells),
			str(scene.debug_last_cell_has_textures),
			str(scene.debug_last_cell_texture_path)
		])
		quit(1)
	else:
		print("test_game_scene_cell_texture_visible: PASS sample=%s white_cells=%s has_textures=%s path=%s" % [
			str(sample),
			str(scene.debug_white_cells),
			str(scene.debug_last_cell_has_textures),
			str(scene.debug_last_cell_texture_path)
		])
		quit(0)

func _assert_cell_texture_not_white(active_theme: ThemeConfig, active_scene: Node) -> void:
	var texture := active_theme.get_cell_bg_texture_for_mode("dark") if active_theme != null else null
	var image := texture.get_image() if texture != null else null
	if image == null:
		print("test_game_scene_cell_texture_visible: FAIL headless texture image missing path=%s" % [
			str(active_theme.get_cell_bg_texture_path("dark") if active_theme != null else "")
		])
		quit(1)
		return
	var sample := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
	var is_white := sample.r > 0.92 and sample.g > 0.92 and sample.b > 0.92
	if is_white:
		print("test_game_scene_cell_texture_visible: FAIL headless sample=%s path=%s" % [
			str(sample),
			str(active_theme.get_cell_bg_texture_path("dark") if active_theme != null else "")
		])
		quit(1)
	else:
		print("test_game_scene_cell_texture_visible: PASS headless sample=%s has_textures=%s path=%s" % [
			str(sample),
			str(active_scene.debug_last_cell_has_textures if active_scene != null else false),
			str(active_theme.get_cell_bg_texture_path("dark") if active_theme != null else "")
		])
		quit(0)
