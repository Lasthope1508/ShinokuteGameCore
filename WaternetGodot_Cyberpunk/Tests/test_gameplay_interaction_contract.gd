extends SceneTree

const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var scene = GameSceneScript.new()
	scene.grid = _make_interaction_grid()
	scene.solver = ConnectionSolverScript.new()
	scene.CELL_SIZE = 64.0
	scene.GRID_OFFSET = Vector2(32.0, 96.0)
	scene.active_theme_override = load(THEME_PATH)
	scene._init_visual_rotations()
	scene.moves = 0
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.energy_flow_start_times = {"1,0": 4.0}
	scene.flow_visual_state = {Vector2i(1, 0): {"age": 1.0}}

	passed = passed and _assert_true(scene.has_method("get_cell_at_screen_position"), "GameScene should expose screen-to-cell helper")
	passed = passed and _assert_true(scene.has_method("try_rotate_cell"), "GameScene should expose canonical rotate interaction hook")

	if scene.has_method("get_cell_at_screen_position"):
		passed = passed and _assert_equal(scene.get_cell_at_screen_position(Vector2(96.0, 128.0)), Vector2i(1, 0), "Screen point should map to middle cell")
		passed = passed and _assert_equal(scene.get_cell_at_screen_position(Vector2(4.0, 4.0)), Vector2i(-1, -1), "Outside screen point should map to invalid cell")

	if scene.has_method("try_rotate_cell"):
		passed = passed and _assert_equal(scene.try_rotate_cell(Vector2i(0, 0), false), true, "Source endpoint should rotate")
		passed = passed and _assert_equal(scene.grid.get_tile_ports(0, 0), [false, true, false, false], "Source ports should rotate clockwise")
		passed = passed and _assert_float_close(scene.visual_rotations[0][0], PI / 2.0, "Source visual rotation should sync without animation")
		passed = passed and _assert_equal(scene.grid.source_ports, [false, true, false, false], "Source port cache should stay synced")
		passed = passed and _assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Source position should stay fixed")
		passed = passed and _assert_equal(scene.moves, 1, "Source rotation should count as a move")
		scene.energy_flow_start_times = {"1,0": 4.0}
		scene.flow_visual_state = {Vector2i(1, 0): {"age": 1.0}}
		passed = passed and _assert_equal(scene.try_rotate_cell(Vector2i(2, 0), false), true, "Target endpoint should rotate")
		passed = passed and _assert_equal(scene.grid.get_tile_ports(2, 0), [false, false, false, true], "Target ports should rotate clockwise")
		passed = passed and _assert_float_close(scene.visual_rotations[0][2], 3.0 * PI / 2.0, "Target visual rotation should sync without animation")
		passed = passed and _assert_equal(scene.grid.target_ports, [false, false, false, true], "Target port cache should stay synced")
		passed = passed and _assert_equal(scene.grid.target_pos, Vector2i(2, 0), "Target position should stay fixed")
		passed = passed and _assert_equal(scene.moves, 2, "Target rotation should count as a move")
		passed = passed and _assert_equal(scene.energy_flow_start_times.size(), 0, "Endpoint rotation should reset energy starts")
		passed = passed and _assert_true(scene.flow_visual_state.has(Vector2i(2, 0)), "Endpoint rotation should refresh VFX flow state")
		passed = passed and _assert_equal(scene.is_solved, true, "Endpoint rotation should refresh solver win state")

		scene.free()
		scene = GameSceneScript.new()
		scene.grid = _make_middle_pipe_grid()
		scene.solver = ConnectionSolverScript.new()
		scene.active_theme_override = load(THEME_PATH)
		scene._init_visual_rotations()
		scene.moves = 0
		scene.is_solved = scene.solver.check_connection(scene.grid)
		scene.energy_flow_start_times = {"1,0": 4.0}
		scene.flow_visual_state = {Vector2i(1, 0): {"age": 1.0}}
		passed = passed and _assert_equal(scene.try_rotate_cell(Vector2i(1, 0), false), true, "Middle pipe should rotate")
		passed = passed and _assert_equal(scene.grid.get_tile_ports(1, 0), [false, true, false, true], "Middle pipe should rotate into horizontal connection")
		passed = passed and _assert_float_close(scene.visual_rotations[0][1], PI / 2.0, "Middle pipe visual rotation should sync without animation")
		passed = passed and _assert_equal(scene.moves, 1, "Pipe rotation should increment moves")
		passed = passed and _assert_equal(scene.energy_flow_start_times.size(), 0, "Pipe rotation should reset energy starts")
		passed = passed and _assert_true(scene.flow_visual_state.has(Vector2i(2, 0)), "Pipe rotation should refresh VFX flow state")
		passed = passed and _assert_equal(scene.is_solved, true, "Pipe rotation should refresh solver win state")

	scene.free()

	if passed:
		print("test_gameplay_interaction_contract: PASS")
		quit(0)
	else:
		print("test_gameplay_interaction_contract: FAIL")
		quit(1)

func _make_interaction_grid() -> RefCounted:
	var grid = PipeGridScript.new()
	grid.initialize({
		"width": 3,
			"height": 1,
		"source": {"x": 0, "y": 0, "ports": [true, false, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, true, false]},
		"grid": [
			{"type": "source", "ports": [true, false, false, false], "rotation": 0},
			{"type": "I", "ports": [false, true, false, true], "rotation": 0},
			{"type": "target", "ports": [false, false, true, false], "rotation": 0}
		]
	})
	return grid

func _make_middle_pipe_grid() -> RefCounted:
	var grid = PipeGridScript.new()
	grid.initialize({
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, false, true]},
		"grid": [
			{"type": "source", "ports": [false, true, false, false], "rotation": 0},
			{"type": "I", "ports": [true, false, true, false], "rotation": 0},
			{"type": "target", "ports": [false, false, false, true], "rotation": 0}
		]
	})
	return grid

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_float_close(actual: float, expected: float, message: String) -> bool:
	if abs(actual - expected) > 0.001:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
