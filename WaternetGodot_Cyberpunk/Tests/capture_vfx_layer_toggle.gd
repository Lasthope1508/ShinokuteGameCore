extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")
const OUTPUT_DISABLED = "res://debug/vfx_layer_disabled.png"
const OUTPUT_ENABLED = "res://debug/vfx_layer_enabled.png"

var frame_count := 0
var layer: Node2D = null
var capture_stage := 0
var disabled_image: Image = null

func _init() -> void:
	root.size = Vector2i(720, 1280)

func _process(_delta):
	frame_count += 1
	if layer == null:
		_setup_layer()
		return
	if frame_count < 4:
		layer.queue_redraw()
		return
	if capture_stage == 0:
		layer.set_vfx_enabled(false)
		layer.set_debug_visible(true)
		layer.queue_redraw()
		capture_stage = 1
		frame_count = 0
		return
	if capture_stage == 1:
		disabled_image = _capture(OUTPUT_DISABLED)
		if disabled_image == null:
			quit(1)
			return
		layer.set_vfx_enabled(true)
		layer.set_debug_visible(true)
		layer.queue_redraw()
		capture_stage = 2
		frame_count = 0
		return
	if capture_stage == 2:
		var enabled_image := _capture(OUTPUT_ENABLED)
		if enabled_image == null:
			quit(1)
			return
		if not _images_differ(disabled_image, enabled_image):
			push_error("VFX enabled/disabled screenshots should differ")
			quit(1)
			return
		print("capture_vfx_layer_toggle: %s" % OUTPUT_DISABLED)
		print("capture_vfx_layer_toggle: %s" % OUTPUT_ENABLED)
		print("capture_vfx_layer_toggle: PASS")
		quit(0)

func _setup_layer() -> void:
	var theme = load(THEME_PATH)
	layer = PipeVfxLayer.new()
	root.add_child(layer)
	var flow_state := {
		Vector2i(1, 4): {
			"cell_pos": Vector2i(1, 4),
			"input_dir": -1,
			"output_dirs": [1],
			"age": 0.1,
			"flow_mask": 2,
			"order": 0
		},
		Vector2i(2, 4): {
			"cell_pos": Vector2i(2, 4),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 0.16,
			"flow_mask": 10,
			"order": 0
		},
		Vector2i(3, 4): {
			"cell_pos": Vector2i(3, 4),
			"input_dir": 3,
			"output_dirs": [1],
			"age": 1.2,
			"flow_mask": 10,
			"order": 1
		},
		Vector2i(4, 4): {
			"cell_pos": Vector2i(4, 4),
			"input_dir": 3,
			"output_dirs": [],
			"age": 0.12,
			"flow_mask": 8,
			"order": 2
		}
	}
	var geometry_by_cell := {
		Vector2i(1, 4): theme.source_geometry,
		Vector2i(2, 4): theme.pipe_i_geometry,
		Vector2i(3, 4): theme.pipe_i_geometry,
		Vector2i(4, 4): theme.target_geometry
	}
	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(80, 120), 96.0)
	layer.apply_theme_config(theme, 96.0)
	layer.debug_line_width = 6.0
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
			if _color_distance(a.get_pixel(x, y), b.get_pixel(x, y)) > 0.05:
				return true
	return false

func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a)
