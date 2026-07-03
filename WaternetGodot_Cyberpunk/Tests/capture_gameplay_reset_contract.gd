extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const BEFORE_PATH = "res://debug/gameplay_reset_before.png"
const AFTER_PATH = "res://debug/gameplay_reset_after.png"

var frame_count: int = 0
var stage: int = 0
var scene = null
var before_image: Image = null
var passed: bool = true

func _init() -> void:
	root.size = Vector2i(720, 1280)

func _process(_delta):
	frame_count += 1
	if scene == null:
		_setup_scene()
		return
	if frame_count < 8:
		scene.queue_redraw()
		return
	if stage == 0:
		_dirty_current_level()
		before_image = _capture(BEFORE_PATH)
		stage = 1
		frame_count = 0
		return
	if stage == 1:
		_reset_level()
		stage = 2
		frame_count = 0
		return
	if stage == 2:
		var after_image: Image = _capture(AFTER_PATH)
		if after_image != null:
			_assert_true(_images_differ(before_image, after_image), "Reset before/after captures should differ")
		if passed:
			print("capture_gameplay_reset_contract: PASS")
			_cleanup()
			quit(0)
		else:
			print("capture_gameplay_reset_contract: FAIL")
			_cleanup()
			quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level_id = 6
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0

func _dirty_current_level() -> void:
	scene.moves = 9
	scene.energy_flow_start_times = {"1,0": Time.get_ticks_msec() / 1000.0 - 1.0}
	scene.flow_visual_state = {Vector2i(1, 0): {"age": 1.0}}
	if scene.grid != null and scene.grid.is_valid_pos(Vector2i(1, 0)):
		scene.grid.rotate_tile(1, 0)
	if scene.has_method("_update_hud"):
		scene._update_hud()
	if scene.has_method("_sync_vfx_layer"):
		scene._sync_vfx_layer()
	scene.queue_redraw()

func _reset_level() -> void:
	_assert_equal(scene.reset_current_level(false), true, "Reset hook should succeed")
	_assert_equal(scene.moves, 0, "Reset should clear moves")
	_assert_equal(scene.energy_flow_start_times.size(), 0, "Reset should clear energy starts")
	_assert_equal(scene.flow_visual_state.size(), 0, "Reset should clear flow state")
	_assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Reset source should stay top-left")
	_assert_equal(scene.grid.target_pos, Vector2i(scene.grid.width - 1, scene.grid.height - 1), "Reset target should stay bottom-right")
	_assert_equal(scene.visual_rotations.size(), scene.grid.height, "Reset should rebuild visual rows")

func _capture(path: String) -> Image:
	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null for %s" % path)
		return null
	var err: Error = image.save_png(path)
	if err != OK:
		_fail("Failed to save %s: %s" % [path, str(err)])
		return null
	print("capture_gameplay_reset_contract: %s" % path)
	return image

func _images_differ(a: Image, b: Image) -> bool:
	if a == null or b == null or a.get_size() != b.get_size():
		return true
	var step_x: int = max(1, a.get_width() / 16)
	var step_y: int = max(1, a.get_height() / 16)
	for y in range(0, a.get_height(), step_y):
		for x in range(0, a.get_width(), step_x):
			if _color_distance(a.get_pixel(x, y), b.get_pixel(x, y)) > 0.08:
				return true
	return false

func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a)

func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail("%s: expected true" % message)

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		scene.queue_free()
		scene = null
