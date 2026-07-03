extends SceneTree

const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const OUTPUT_PATH = "res://debug/vfx_debug_overlay.png"

var frame_count := 0
var layer = null
var passed := true

func _init() -> void:
	root.size = Vector2i(480, 320)

func _process(_delta):
	frame_count += 1
	if layer == null:
		_setup_layer()
		return
	if frame_count < 8:
		layer.queue_redraw()
		return
	_capture()
	if passed:
		print("capture_vfx_debug_overlay: PASS")
		_cleanup()
		quit(0)
	else:
		print("capture_vfx_debug_overlay: FAIL")
		_cleanup()
		quit(1)

func _setup_layer() -> void:
	var theme = load(THEME_PATH)
	layer = PipeVfxLayerScript.new()
	root.add_child(layer)
	layer.apply_theme_config(theme, 100.0)
	layer.set_debug_visible(true)
	layer.set_visual_context(
		{
			Vector2i(1, 0): {
				"cell_pos": Vector2i(1, 0),
				"order": 2,
				"input_dir": 3,
				"output_dirs": [1],
				"flow_mask": 10,
				"age": 0.1
			}
		},
		{Vector2i(1, 0): theme.get_asset_geometry("I")},
		Vector2(80.0, 80.0),
		100.0
	)
	_assert_true(layer.get_debug_anchors().size() == 1, "Debug overlay should expose anchor data")
	frame_count = 0

func _capture() -> void:
	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null for %s" % OUTPUT_PATH)
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Failed to save %s: %s" % [OUTPUT_PATH, str(err)])
	print("capture_vfx_debug_overlay: %s" % OUTPUT_PATH)

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail("%s: expected true" % message)

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if layer != null:
		layer.queue_free()
		layer = null
