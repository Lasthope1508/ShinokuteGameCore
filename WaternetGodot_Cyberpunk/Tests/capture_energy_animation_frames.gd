extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const OUTPUT_PATH = "res://debug/energy_animation_frames.png"

var frame_count := 0
var board: Node2D

class EnergyFrameBoard:
	extends Node2D

	var theme: ThemeConfig
	var helper: Node2D
	var cell_size := 128.0
	var positions := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]

	func _draw() -> void:
		var geometry: Resource = theme.get_asset_geometry("I")
		var base_texture: Texture2D = theme.pipe_i_texture
		var texture_draw_rect: Rect2 = geometry.get_draw_rect()
		var draw_scale: Vector2 = geometry.get_frame_scale(cell_size)
		for i in range(positions.size()):
			var cell_pos: Vector2i = positions[i]
			var center := Vector2(180.0 + float(i) * 180.0, 360.0)
			draw_rect(Rect2(center - Vector2(cell_size, cell_size) / 2.0, Vector2(cell_size, cell_size)), Color(0.06, 0.08, 0.09, 1.0))
			draw_set_transform(center, PI / 2.0, draw_scale)
			draw_texture_rect(base_texture, texture_draw_rect, false, Color.WHITE)
			var overlay: Texture2D = helper._get_energy_overlay_texture_for_draw(base_texture, cell_pos, true, geometry)
			if overlay != null:
				draw_texture_rect(overlay, helper._get_energy_draw_rect_for_geometry(geometry), false, Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _init() -> void:
	root.size = Vector2i(720, 720)

func _process(_delta: float) -> bool:
	frame_count += 1
	if board == null:
		_setup_board()
		return false
	if frame_count < 4:
		board.queue_redraw()
		return false
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Viewport image is null for energy animation capture")
		quit(1)
		return true
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Failed to save %s: %s" % [OUTPUT_PATH, str(err)])
		_cleanup()
		quit(1)
		return true
	print("capture_energy_animation_frames: %s" % OUTPUT_PATH)
	print("capture_energy_animation_frames: PASS")
	_cleanup()
	quit(0)
	return true

func _setup_board() -> void:
	var theme: ThemeConfig = load(THEME_PATH)
	var helper = GameSceneScript.new()
	helper.active_theme_override = theme
	helper.flow_visual_state = {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "age": 0.0, "input_dir": 3, "output_dirs": [1], "flow_mask": 10, "order": 0},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "age": theme.energy_default_frame_duration * 3.1, "input_dir": 3, "output_dirs": [1], "flow_mask": 10, "order": 1},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "age": theme.energy_default_frame_duration * 99.0, "input_dir": 3, "output_dirs": [1], "flow_mask": 10, "order": 2}
	}
	board = EnergyFrameBoard.new()
	board.theme = theme
	board.helper = helper
	root.add_child(board)
	frame_count = 0

func _cleanup() -> void:
	if board != null:
		if board.helper != null:
			board.helper.energy_sheet_texture_cache.clear()
			board.helper.energy_frame_texture_cache.clear()
			board.helper.free()
			board.helper = null
		board.queue_free()
		board = null
