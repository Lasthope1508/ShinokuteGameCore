extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const OUTPUT_DIR = "res://debug/fake3d_size_sweep"
const LEVELS := [1, 6, 9, 12, 15, 16]

var level_index := -1
var frame_count := 0
var scene = null
var passed := true

func _init() -> void:
	root.size = Vector2i(720, 1280)

func _process(_delta):
	frame_count += 1
	if scene == null:
		_start_next_level()
		return
	if frame_count < 8:
		if scene != null:
			scene.queue_redraw()
		return
	_capture_current_level()
	_finish_current_level()

func _start_next_level() -> void:
	level_index += 1
	if level_index >= LEVELS.size():
		if passed:
			print("capture_fake3d_size_sweep: PASS")
			quit(0)
		else:
			print("capture_fake3d_size_sweep: FAIL")
			quit(1)
		return

	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")

	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level_id = LEVELS[level_index]

	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0

func _capture_current_level() -> void:
	var level_id: int = LEVELS[level_index]
	if scene.grid == null:
		_fail("level %d grid should exist" % level_id)
		return

	var expected_target := Vector2i(scene.grid.width - 1, scene.grid.height - 1)
	if scene.grid.source_pos != Vector2i(0, 0):
		_fail("level %d source should stay top-left, got %s" % [level_id, str(scene.grid.source_pos)])
	if scene.grid.target_pos != expected_target:
		_fail("level %d target should stay bottom-right, got %s" % [level_id, str(scene.grid.target_pos)])

	var dir = DirAccess.open("res://")
	if dir == null or dir.make_dir_recursive("debug/fake3d_size_sweep") != OK:
		_fail("failed to create fake3d_size_sweep output directory")
		return

	var image := root.get_texture().get_image()
	if image == null:
		_fail("level %d viewport image is null" % level_id)
		return
	if not _image_has_variation(image):
		_fail("level %d screenshot should not be blank" % level_id)
		return

	var output_path := "%s/level_%02d.png" % [OUTPUT_DIR, level_id]
	var err := image.save_png(output_path)
	if err != OK:
		_fail("failed to save %s: %s" % [output_path, str(err)])
		return
	print("capture_fake3d_size_sweep: saved %s" % output_path)

func _finish_current_level() -> void:
	if scene != null:
		scene.queue_free()
		scene = null
	frame_count = 0

func _image_has_variation(image: Image) -> bool:
	var base := image.get_pixel(0, 0)
	var step_x: int = max(1, image.get_width() / 12)
	var step_y: int = max(1, image.get_height() / 12)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if _color_distance(base, image.get_pixel(x, y)) > 0.02:
				return true
	return false

func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a)

func _fail(message: String) -> void:
	passed = false
	push_error(message)
