extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const BEFORE_PATH = "res://debug/endpoint_rotation_before.png"
const AFTER_PATH = "res://debug/endpoint_rotation_after.png"

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
		_rotate_endpoints()
		stage = 2
		frame_count = 0
		return
	if stage == 2:
		_capture_after()
		if passed:
			print("capture_endpoint_interaction_rotate: PASS")
			_cleanup()
			quit(0)
		else:
			print("capture_endpoint_interaction_rotate: FAIL")
			_cleanup()
			quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0
	call_deferred("_install_endpoint_level")

func _install_endpoint_level() -> void:
	var grid = PipeGridScript.new()
	grid.initialize(_make_endpoint_level())
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 16
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
	_assert_equal(scene.moves, 0, "Before endpoint rotate moves should be 0")
	_assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Source should stay top-left before endpoint rotate")
	_assert_equal(scene.grid.target_pos, Vector2i(2, 0), "Target should stay bottom-right before endpoint rotate")
	before_image = _capture(BEFORE_PATH)
	if before_image == null:
		_fail("Before endpoint image should capture")

func _rotate_endpoints() -> void:
	_assert_equal(scene.try_rotate_cell(Vector2i(0, 0), false), true, "Source should rotate through canonical interaction hook")
	_assert_equal(scene.try_rotate_cell(Vector2i(2, 0), false), true, "Target should rotate through canonical interaction hook")
	_assert_equal(scene.moves, 2, "Endpoint rotations should increment moves")
	_assert_equal(scene.grid.get_tile_ports(0, 0), [false, true, false, false], "Source should rotate from north to east")
	_assert_equal(scene.grid.get_tile_ports(2, 0), [false, false, false, true], "Target should rotate from south to west")
	_assert_float_close(scene.visual_rotations[0][0], PI / 2.0, "Source visual rotation should sync")
	_assert_float_close(scene.visual_rotations[0][2], 3.0 * PI / 2.0, "Target visual rotation should sync")
	_assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Source position should remain fixed after endpoint rotate")
	_assert_equal(scene.grid.target_pos, Vector2i(2, 0), "Target position should remain fixed after endpoint rotate")

func _capture_after() -> void:
	var after_image: Image = _capture(AFTER_PATH)
	if after_image == null:
		_fail("After endpoint image should capture")
		return
	_assert_true(_images_differ(before_image, after_image), "Before/after endpoint captures should differ")

func _capture(path: String) -> Image:
	var image: Image = root.get_texture().get_image()
	if image == null:
		return null
	var err: Error = image.save_png(path)
	if err != OK:
		_fail("Failed to save %s: %s" % [path, str(err)])
		return null
	print("capture_endpoint_interaction_rotate: %s" % path)
	return image

func _make_endpoint_level() -> Dictionary:
	return {
		"id": 16,
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [true, false, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, true, false]},
		"grid": [
			{"type": "source", "ports": [true, false, false, false], "rotation": 0},
			{"type": "I", "ports": [false, true, false, true], "rotation": 0},
			{"type": "target", "ports": [false, false, true, false], "rotation": 0}
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

func _assert_float_close(actual: float, expected: float, message: String) -> void:
	if abs(actual - expected) > 0.001:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		scene.queue_free()
		scene = null
