extends SceneTree

const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const FlowVisualState = preload("res://Scripts/flow_visual_state.gd")

func _init() -> void:
	var passed := true
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

	var state: Dictionary = FlowVisualState.build(grid, {}, 10.0)
	passed = passed and _assert_equal(state.size(), 3, "straight path should produce three watered flow entries")

	var source: Dictionary = state.get(Vector2i(0, 0), {})
	var middle: Dictionary = state.get(Vector2i(1, 0), {})
	var target: Dictionary = state.get(Vector2i(2, 0), {})

	passed = passed and _assert_equal(source.get("order", -1), 0, "source order should be zero")
	passed = passed and _assert_equal(source.get("input_dir", -2), -1, "source should have no input direction")
	passed = passed and _assert_equal(source.get("output_dirs", []), [1], "source should output east")
	passed = passed and _assert_equal(source.get("flow_mask", 0), 2, "source flow mask should include east")

	passed = passed and _assert_equal(middle.get("order", -1), 1, "middle order should follow source")
	passed = passed and _assert_equal(middle.get("input_dir", -1), 3, "middle should receive from west")
	passed = passed and _assert_equal(middle.get("output_dirs", []), [1], "middle should output east")
	passed = passed and _assert_equal(middle.get("flow_mask", 0), 10, "middle flow mask should include west and east")

	passed = passed and _assert_equal(target.get("order", -1), 2, "target order should be last")
	passed = passed and _assert_equal(target.get("input_dir", -1), 3, "target should receive from west")
	passed = passed and _assert_equal(target.get("output_dirs", []), [], "target should have no output")
	passed = passed and _assert_equal(target.get("flow_mask", 0), 8, "target flow mask should include west")

	var timed_state: Dictionary = FlowVisualState.build(grid, {"1,0": 7.5}, 10.0)
	var timed_middle: Dictionary = timed_state.get(Vector2i(1, 0), {})
	passed = passed and _assert_float_close(timed_middle.get("age", -1.0), 2.5, "middle age should derive from energy start time")

	var branch_grid = PipeGridScript.new()
	branch_grid.initialize({
		"width": 2,
		"height": 2,
		"source": {"x": 0, "y": 0, "ports": [false, true, true, false]},
		"target": {"x": 1, "y": 1, "ports": [false, false, false, true]},
		"grid": [
			{"type": "T", "ports": [false, true, true, false], "rotation": 0},
			{"type": "I", "ports": [false, false, false, true], "rotation": 270},
			{"type": "L", "ports": [true, true, false, false], "rotation": 0},
			{"type": "I", "ports": [false, false, false, true], "rotation": 270}
		]
	})
	var branch_state: Dictionary = FlowVisualState.build(branch_grid, {}, 0.0)
	var branch_source: Dictionary = branch_state.get(Vector2i(0, 0), {})
	var branch_leaf: Dictionary = branch_state.get(Vector2i(1, 0), {})
	var branch_turn: Dictionary = branch_state.get(Vector2i(0, 1), {})
	passed = passed and _assert_equal(branch_source.get("output_dirs", []), [1, 2], "branch source should output east then south")
	passed = passed and _assert_equal(branch_leaf.get("input_dir", -1), 3, "east branch leaf should receive from west")
	passed = passed and _assert_equal(branch_turn.get("input_dir", -1), 0, "south branch turn should receive from north")
	passed = passed and _assert_equal(branch_turn.get("output_dirs", []), [1], "south branch turn should output east")

	if passed:
		print("test_flow_visual_state: PASS")
		quit(0)
	else:
		print("test_flow_visual_state: FAIL")
		quit(1)

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
