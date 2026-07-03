extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")
const OUTPUT_A = "res://debug/vfx_idle_hum_motion_a.png"
const OUTPUT_B = "res://debug/vfx_idle_hum_motion_b.png"

var frame_count := 0
var stage := 0
var layer: Node2D = null
var first_image: Image = null

func _init() -> void:
	root.size = Vector2i(720, 360)

func _process(_delta):
	frame_count += 1
	if layer == null:
		_setup_layer()
		return
	if stage == 0 and frame_count >= 6:
		first_image = _capture(OUTPUT_A)
		if first_image == null:
			quit(1)
			return
		stage = 1
		frame_count = 0
		return
	if stage == 1 and frame_count >= 22:
		var second_image := _capture(OUTPUT_B)
		if second_image == null:
			quit(1)
			return
		if not _images_differ(first_image, second_image):
			push_error("Idle hum motion frames should differ")
			quit(1)
			return
		print("capture_vfx_idle_hum_motion: %s" % OUTPUT_A)
		print("capture_vfx_idle_hum_motion: %s" % OUTPUT_B)
		print("capture_vfx_idle_hum_motion: PASS")
		quit(0)

func _setup_layer() -> void:
	var theme = load(THEME_PATH)
	layer = PipeVfxLayer.new()
	root.add_child(layer)
	var flow_state := {
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 4.0,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(2, 0): {
			"cell_pos": Vector2i(2, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 4.0,
			"flow_mask": 10,
			"order": 2
		}
	}
	var geometry_by_cell := {
		Vector2i(1, 0): theme.get_asset_geometry("I"),
		Vector2i(2, 0): theme.get_asset_geometry("I")
	}
	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(120, 120), 120.0)
	layer.apply_theme_config(theme, 120.0)
	frame_count = 0

func _capture(path: String) -> Image:
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Viewport image is null for %s" % path)
		return null
	var err := image.save_png(path)
	if err != OK:
		push_error("Failed to save %s: %s" % [path, str(err)])
		return null
	return image

func _images_differ(a: Image, b: Image) -> bool:
	if a == null or b == null or a.get_size() != b.get_size():
		return true
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			if _color_distance(a.get_pixel(x, y), b.get_pixel(x, y)) > 0.03:
				return true
	return false

func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a)
