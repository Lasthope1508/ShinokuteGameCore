extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const OUTPUT_PATH = "res://debug/fake3d_runtime_screenshot.png"

var frame_count = 0
var scene = null
var setup_done = false

func _init():
	root.size = Vector2i(720, 1280)

func _setup_scene():
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level_id = 7

	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	setup_done = true

func _process(_delta):
	frame_count += 1
	if not setup_done:
		if frame_count >= 2:
			_setup_scene()
		return
	if frame_count < 8:
		if scene != null:
			scene.queue_redraw()
		return
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Viewport image is null in headless renderer")
		quit(1)
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		push_error("Failed to save fake3D screenshot: %s" % str(err))
		quit(1)
		return

	print("capture_fake3d_screenshot: %s" % OUTPUT_PATH)
	quit(0)
