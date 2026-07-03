extends SceneTree

const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")

func _init() -> void:
	var passed := true
	var scene = GameSceneScript.new()
	var grid = PipeGridScript.new()
	grid.initialize({
		"width": 5,
		"height": 5,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 4, "y": 4, "ports": [false, false, false, true]},
		"grid": []
	})
	scene.grid = grid
	scene.CELL_SIZE = 64.0
	scene.GRID_OFFSET = Vector2(32.0, 96.0)

	passed = passed and _assert_true(scene.has_method("get_board_rect"), "GameScene should expose board rect for visual QA")
	passed = passed and _assert_true(scene.has_method("get_cell_rect"), "GameScene should expose cell rect for visual QA")
	passed = passed and _assert_true(scene.has_method("get_endpoint_cell_positions"), "GameScene should expose endpoint positions for visual QA")

	if scene.has_method("get_board_rect"):
		passed = passed and _assert_equal(scene.get_board_rect(), Rect2(32.0, 96.0, 320.0, 320.0), "Board rect should derive from grid and layout SSOT")
	if scene.has_method("get_cell_rect"):
		passed = passed and _assert_equal(scene.get_cell_rect(Vector2i(0, 0)), Rect2(32.0, 96.0, 64.0, 64.0), "Source cell rect should derive from grid offset")
		passed = passed and _assert_equal(scene.get_cell_rect(Vector2i(4, 4)), Rect2(288.0, 352.0, 64.0, 64.0), "Target cell rect should derive from grid offset")
	if scene.has_method("get_endpoint_cell_positions"):
		var endpoints: Dictionary = scene.get_endpoint_cell_positions()
		passed = passed and _assert_equal(endpoints.get("source", Vector2i(-1, -1)), Vector2i(0, 0), "Source endpoint should stay top-left")
		passed = passed and _assert_equal(endpoints.get("target", Vector2i(-1, -1)), Vector2i(4, 4), "Target endpoint should stay bottom-right")

	scene.free()

	if passed:
		print("test_game_scene_visual_contract_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_visual_contract_hooks: FAIL")
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
