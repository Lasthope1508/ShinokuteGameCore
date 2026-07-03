extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const BEFORE_PATH = "res://debug/gameplay_interaction_before.png"
const AFTER_PATH = "res://debug/gameplay_interaction_after.png"

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
		_capture_before()
		stage = 1
		frame_count = 0
		return
	if stage == 1:
		_rotate_middle_pipe()
		stage = 2
		frame_count = 0
		return
	if stage == 2:
		_capture_after()
		if passed:
			print("capture_gameplay_interaction_rotate: PASS")
			_cleanup()
			quit(0)
		else:
			print("capture_gameplay_interaction_rotate: FAIL")
			_cleanup()
			quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0
	call_deferred("_install_interaction_level")

func _install_interaction_level() -> void:
	var grid = PipeGridScript.new()
	grid.initialize(_make_interaction_level())
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 14
	scene.moves = 0
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.energy_flow_start_times = {"1,0": Time.get_ticks_msec() / 1000.0 - 1.0}
	scene.flow_visual_state = {Vector2i(1, 0): {"age": 1.0}}
	if scene.has_method("_recalculate_layout"):
		scene._recalculate_layout()
	if scene.has_method("_init_visual_rotations"):
		scene._init_visual_rotations()
	if scene.has_method("_sync_vfx_layer"):
		scene._sync_vfx_layer()
	if scene.has_method("_update_hud"):
		scene._update_hud()
	scene.queue_redraw()

func _capture_before() -> void:
	_assert_equal(scene.is_solved, false, "Before rotate should be unsolved")
	_assert_equal(scene.moves, 0, "Before rotate moves should be 0")
	_assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Source should stay top-left before rotate")
	_assert_equal(scene.grid.target_pos, Vector2i(2, 0), "Target should stay bottom-right before rotate")
	before_image = _capture(BEFORE_PATH)
	if before_image == null:
		_fail("Before image should capture")

func _rotate_middle_pipe() -> void:
	var rotated: bool = scene.try_rotate_cell(Vector2i(1, 0), false)
	_assert_equal(rotated, true, "Middle pipe should rotate through canonical interaction hook")
	_assert_equal(scene.moves, 1, "Rotate should increment moves")
	_assert_equal(scene.grid.get_tile_ports(1, 0), [false, true, false, true], "Middle pipe should become horizontal")
	_assert_equal(scene.energy_flow_start_times.size(), 0, "Rotate should reset energy animation starts")
	_assert_true(scene.flow_visual_state.has(Vector2i(2, 0)), "Rotate should refresh flow visual state")
	_assert_equal(scene.is_solved, true, "Rotate should solve the interaction fixture")

func _capture_after() -> void:
	var after_image: Image = _capture(AFTER_PATH)
	if after_image == null:
		_fail("After image should capture")
		return
	_assert_true(_images_differ(before_image, after_image), "Before/after rotate captures should differ")

func _capture(path: String) -> Image:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return null
	var err: Error = image.save_png(path)
	if err != OK:
		_fail("Failed to save %s: %s" % [path, str(err)])
		return null
	print("capture_gameplay_interaction_rotate: %s" % path)
	return image

func _make_interaction_level() -> Dictionary:
	return {
		"id": 14,
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, false, true]},
		"grid": [
			{"type": "I", "ports": [false, true, false, false], "rotation": 0},
			{"type": "I", "ports": [true, false, true, false], "rotation": 0},
			{"type": "I", "ports": [false, false, false, true], "rotation": 0}
		]
	}

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
