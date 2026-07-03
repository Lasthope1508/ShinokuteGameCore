extends SceneTree

const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")

func _init() -> void:
	var passed := true
	var scene = GameSceneScript.new()
	scene.grid = PipeGridScript.new()
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 6
	scene.moves = 7
	scene.is_solved = false
	scene.energy_flow_start_times = {"1,0": 4.0, "2,0": 5.0}
	scene.flow_visual_state = {
		Vector2i(1, 0): {"age": 1.0},
		Vector2i(2, 0): {"age": 0.5}
	}

	passed = passed and _assert_true(scene.has_method("reset_current_level"), "GameScene should expose canonical reset hook")

	if scene.has_method("reset_current_level"):
		passed = passed and _assert_equal(scene.reset_current_level(false), true, "Reset hook should report success")
		passed = passed and _assert_equal(scene.moves, 0, "Reset should clear moves")
		passed = passed and _assert_equal(scene.energy_flow_start_times.size(), 0, "Reset should clear energy starts")
		passed = passed and _assert_equal(scene.flow_visual_state.size(), 0, "Reset should clear flow visual state")
		passed = passed and _assert_equal(scene.grid.width, 6, "Level 6 reset should use generator difficulty width")
		passed = passed and _assert_equal(scene.grid.height, 6, "Level 6 reset should use generator difficulty height")
		passed = passed and _assert_equal(scene.grid.source_pos, Vector2i(0, 0), "Reset source should stay top-left")
		passed = passed and _assert_equal(scene.grid.target_pos, Vector2i(5, 5), "Reset target should stay bottom-right")
		passed = passed and _assert_equal(scene.is_solved, scene.solver.check_connection(scene.grid), "Reset should refresh solver state")
		passed = passed and _assert_equal(scene.visual_rotations.size(), scene.grid.height, "Reset should rebuild visual rotation rows")
		if scene.visual_rotations.size() == scene.grid.height:
			passed = passed and _assert_equal(scene.visual_rotations[0].size(), scene.grid.width, "Reset should rebuild visual rotation columns")

	scene.free()

	if passed:
		print("test_gameplay_reset_contract: PASS")
		quit(0)
	else:
		print("test_gameplay_reset_contract: FAIL")
		quit(1)

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
