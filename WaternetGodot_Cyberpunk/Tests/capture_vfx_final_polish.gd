extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")
const OUTPUT_PATH = "res://debug/vfx_final_polish.png"

var frame_count := 0
var layer: Node2D = null

func _init() -> void:
	root.size = Vector2i(720, 420)

func _process(_delta):
	frame_count += 1
	if layer == null:
		_setup_layer()
		return
	if frame_count < 8:
		return
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Viewport image is null")
		quit(1)
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Failed to save %s: %s" % [OUTPUT_PATH, str(err)])
		quit(1)
		return
	if not _has_visible_pixels(image):
		push_error("Final polish capture should contain visible VFX pixels")
		quit(1)
		return
	print("capture_vfx_final_polish: %s" % OUTPUT_PATH)
	print("capture_vfx_final_polish: PASS")
	quit(0)

func _setup_layer() -> void:
	var theme = load(THEME_PATH)
	layer = PipeVfxLayer.new()
	root.add_child(layer)
	var flow_state := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [1], "age": 2.0, "flow_mask": 2, "order": 0},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 1},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [1], "age": 2.0, "flow_mask": 10, "order": 2},
		Vector2i(3, 0): {"cell_pos": Vector2i(3, 0), "input_dir": 3, "output_dirs": [], "age": 2.0, "flow_mask": 8, "order": 3}
	}
	var geometry_by_cell := {
		Vector2i(0, 0): theme.get_asset_geometry("source"),
		Vector2i(1, 0): theme.get_asset_geometry("I"),
		Vector2i(2, 0): theme.get_asset_geometry("I"),
		Vector2i(3, 0): theme.get_asset_geometry("target")
	}
	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(120, 160), 110.0)
	layer.apply_theme_config(theme, 110.0)
	var now := Time.get_ticks_msec() / 1000.0
	layer.set_rotation_event(Vector2i(2, 0), now - 0.08)
	layer.set_win_state({"event_time": now - 0.18})
	frame_count = 0

func _has_visible_pixels(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0 and (color.r + color.g + color.b) > 0.08:
				return true
	return false
