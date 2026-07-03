extends SceneTree

const GAME_SCENE_SCRIPT = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")

func _init() -> void:
	var passed := true
	var scene = GAME_SCENE_SCRIPT.new()
	var grid = PipeGridScript.new()
	grid.initialize({
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, false, true]},
		"grid": [
			{"type": "I", "ports": [false, true, false, false], "rotation": 90},
			{"type": "I", "ports": [false, true, false, true], "rotation": 90},
			{"type": "I", "ports": [false, false, false, true], "rotation": 270}
		]
	})
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.energy_flow_start_times = {"1,0": 4.0}

	passed = passed and _assert_true(scene.has_method("_update_flow_visual_state"), "GameScene should expose VFX flow state update hook")
	if scene.has_method("_update_flow_visual_state"):
		scene._update_flow_visual_state(6.0)
		var state: Dictionary = scene.flow_visual_state
		var middle: Dictionary = state.get(Vector2i(1, 0), {})
		passed = passed and _assert_equal(state.size(), 3, "GameScene VFX flow state should include watered path")
		passed = passed and _assert_equal(middle.get("input_dir", -1), 3, "GameScene VFX state should include input direction")
		passed = passed and _assert_equal(middle.get("output_dirs", []), [1], "GameScene VFX state should include output directions")
		passed = passed and _assert_float_close(middle.get("age", -1.0), 2.0, "GameScene VFX state should include age")

	scene.free()

	if passed:
		print("test_game_scene_vfx_data_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_vfx_data_hooks: FAIL")
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

func _assert_float_close(actual: float, expected: float, message: String, epsilon: float = 0.01) -> bool:
	if abs(actual - expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
