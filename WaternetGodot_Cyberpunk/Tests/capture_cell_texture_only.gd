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
		var grid = PipeGridScript.new()
		grid.initialize({
			"width": 5,
			"height": 5,
			"source": {"x": 0, "y": 0, "ports": [false, false, false, false]},
			"target": {"x": 4, "y": 4, "ports": [false, false, false, false]},
			"grid": []
		})
		scene.grid = grid
		scene.CELL_SIZE = 96.0
		scene.GRID_OFFSET = Vector2(120.0, 120.0)
		scene.queue_redraw()
	if frame_count < 12:
		return
	var image := root.get_texture().get_image()
	var err := image.save_png("res://debug/cell_texture_only_dark.png")
	print("capture_cell_texture_only: mode=%s path=%s luma=%s has_textures=%s fallback=%s strict=%s white_cells=%s fake3d=%s inset=%s shadow=%s" % [
		str(scene.debug_last_cell_texture_mode),
		str(scene.debug_last_cell_texture_path),
		str(scene.debug_last_cell_texture_luminance),
		str(scene.debug_last_cell_has_textures),
		str(scene.debug_last_cell_fallback_color),
		str(theme.ui_cell_texture_strict_mode_paths),
		str(scene.debug_white_cells),
		str(theme.fake_3d_enabled),
		str(theme.cell_inset_ratio),
		str(theme.cell_shadow_color)
	])
	print("capture_cell_texture_only: save=%s path=res://debug/cell_texture_only_dark.png" % str(err))
	scene.queue_free()
	if err == OK:
		quit(0)
	else:
		quit(1)
