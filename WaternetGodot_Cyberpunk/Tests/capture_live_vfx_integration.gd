extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")

const BEFORE_PATH = "res://debug/live_vfx_before.png"
const CONNECTED_PATH = "res://debug/live_vfx_connected.png"
const DISCONNECTED_PATH = "res://debug/live_vfx_disconnected.png"

var frame_count := 0
var stage := 0
var scene = null
var passed := true

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
		_connect_path()
		stage = 2
		frame_count = 0
		return
	if stage == 2:
		_capture_connected()
		stage = 3
		frame_count = 0
		return
	if stage == 3:
		_disconnect_path()
		stage = 4
		frame_count = 0
		return
	if stage == 4:
		_capture_disconnected()
		if passed:
			print("capture_live_vfx_integration: PASS")
			_cleanup()
			quit(0)
		else:
			print("capture_live_vfx_integration: FAIL")
			_cleanup()
			quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0
	call_deferred("_install_level")

func _install_level() -> void:
	var grid = PipeGridScript.new()
	grid.initialize(_make_level())
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 17
	scene.moves = 0
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.energy_flow_start_times = {}
	scene.flow_visual_state = FlowVisualStateScript.build(scene.grid, scene.energy_flow_start_times, Time.get_ticks_msec() / 1000.0)
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
	_assert_equal(scene.is_solved, false, "Fixture should start unsolved")
	_capture(BEFORE_PATH)

func _connect_path() -> void:
	_assert_equal(scene.try_rotate_cell(Vector2i(1, 0), false), true, "Middle pipe should connect live powered path")
	_assert_equal(scene.is_solved, false, "Fixture should stay unsolved so disconnect can be tested")
	var transition: Dictionary = scene.pipe_vfx_layer.get_transition_state()
	_assert_true(transition.get("entered_cells", []).has(Vector2i(1, 0)), "Transition should include entered middle cell")
	_assert_true(scene.pipe_vfx_layer.get_directional_trails().size() > 0, "Connected state should expose directional trails")
	_assert_true(scene.pipe_vfx_layer.get_contact_sparks().size() > 0, "Connected state should expose contact sparks")

func _capture_connected() -> void:
	_capture(CONNECTED_PATH)

func _disconnect_path() -> void:
	_assert_equal(scene.try_rotate_cell(Vector2i(0, 0), false), true, "Source rotate should disconnect live powered path")
	var transition: Dictionary = scene.pipe_vfx_layer.get_transition_state()
	_assert_true(transition.get("lost_cells", []).has(Vector2i(1, 0)), "Transition should include lost middle cell")
	_assert_true(scene.pipe_vfx_layer.get_disconnect_decays().size() > 0, "Disconnected state should expose decays")
	_assert_true(scene.pipe_vfx_layer.get_error_sparks().size() > 0, "Disconnected state should expose error sparks")

func _capture_disconnected() -> void:
	_capture(DISCONNECTED_PATH)

func _capture(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null for %s" % path)
		return
	var err := image.save_png(path)
	if err != OK:
		_fail("Failed to save %s: %s" % [path, str(err)])
	print("capture_live_vfx_integration: %s" % path)

func _make_level() -> Dictionary:
	return {
		"id": 17,
		"width": 3,
		"height": 2,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 1, "ports": [true, false, false, false]},
		"grid": [
			{"type": "source", "ports": [false, true, false, false], "rotation": 0},
			{"type": "I", "ports": [true, false, true, false], "rotation": 0},
			{"type": "cap", "ports": [false, false, false, true], "rotation": 0},
			{"type": "cap", "ports": [true, false, false, false], "rotation": 0},
			{"type": "cap", "ports": [true, false, false, false], "rotation": 0},
			{"type": "target", "ports": [true, false, false, false], "rotation": 0}
		]
	}

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail("%s: expected true" % message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		scene.queue_free()
		scene = null
