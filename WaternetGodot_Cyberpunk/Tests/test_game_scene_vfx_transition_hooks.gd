extends SceneTree

const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")
const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")

func _init() -> void:
	var passed := true
	var scene = GameSceneScript.new()
	scene.grid = _make_grid()
	scene.solver = ConnectionSolverScript.new()
	scene.pipe_vfx_layer = PipeVfxLayerScript.new()
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.flow_visual_state = FlowVisualStateScript.build(scene.grid, {}, 1.0)

	passed = passed and _assert_equal(scene.is_solved, false, "Fixture should start unsolved")
	passed = passed and _assert_true(scene.try_rotate_cell(Vector2i(1, 0), false), "Rotation should go through canonical hook")

	var transition: Dictionary = scene.pipe_vfx_layer.transition_state
	passed = passed and _assert_equal(transition.get("changed_cell", Vector2i(-1, -1)), Vector2i(1, 0), "Transition should store changed cell")
	passed = passed and _assert_true(transition.get("previous_flow_state", {}).has(Vector2i(0, 0)), "Transition should store previous flow")
	passed = passed and _assert_true(transition.get("current_flow_state", {}).has(Vector2i(2, 0)), "Transition should store current target flow")
	passed = passed and _assert_true(transition.get("entered_cells", []).has(Vector2i(1, 0)), "Transition should include entered middle cell")
	passed = passed and _assert_true(transition.get("entered_cells", []).has(Vector2i(2, 0)), "Transition should include entered target cell")
	passed = passed and _assert_true(_has_contact(transition.get("entered_contacts", []), Vector2i(0, 0), 1, Vector2i(1, 0)), "Transition should include entered source contact")

	scene.free()
	if passed:
		print("test_game_scene_vfx_transition_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_vfx_transition_hooks: FAIL")
		quit(1)

func _make_grid() -> RefCounted:
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

func _has_contact(contacts: Array, cell_pos: Vector2i, direction: int, neighbor_pos: Vector2i) -> bool:
	for contact in contacts:
		if contact.get("cell_pos") == cell_pos and int(contact.get("direction", -1)) == direction and contact.get("neighbor_pos") == neighbor_pos:
			return true
	return false

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
