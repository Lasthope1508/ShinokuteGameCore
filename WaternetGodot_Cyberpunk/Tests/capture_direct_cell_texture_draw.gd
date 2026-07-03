extends SceneTree

const TEXTURE_PATH = "res://Assets/Themes/cyberpunk_theme/cell_tiles/dark_floorplate_b.png"
const OUTPUT_PATH = "res://debug/direct_cell_texture_draw.png"

var node: Node2D
var frame_count := 0

func _init() -> void:
	root.size = Vector2i(720, 720)

func _process(_delta: float):
	frame_count += 1
	if node == null:
		node = DirectDrawNode.new()
		root.add_child(node)
		return
	if frame_count < 8:
		node.queue_redraw()
		return
	var image := root.get_texture().get_image()
	var err := image.save_png(OUTPUT_PATH)
	print("capture_direct_cell_texture_draw: save=%s path=%s" % [str(err), OUTPUT_PATH])
	quit(0 if err == OK else 1)

class DirectDrawNode extends Node2D:
	var texture: Texture2D

	func _ready() -> void:
		texture = load(TEXTURE_PATH)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(720, 720)), Color(0, 0, 0, 1))
		for y in range(5):
			for x in range(5):
				var rect := Rect2(Vector2(120 + x * 96, 120 + y * 96), Vector2(96, 96))
				draw_texture_rect(texture, rect, false)
				draw_rect(rect, Color(0.0, 1.0, 0.0, 1.0), false, 2.0)
