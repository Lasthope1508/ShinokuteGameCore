extends SceneTree

const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var scene = GameSceneScript.new()
	scene.grid = _make_grid()
	scene.solver = ConnectionSolverScript.new()
	scene.pipe_vfx_layer = PipeVfxLayerScript.new()
	scene.active_theme_override = load(THEME_PATH)
	scene._init_visual_rotations()
	scene.is_solved = scene.solver.check_connection(scene.grid)

	passed = passed and _assert_false(scene.is_solved, "Fixture should start unsolved")
	passed = passed and _assert_true(scene.try_rotate_cell(Vector2i(1, 0), false), "Rotation should solve fixture")
	passed = passed and _assert_true(scene.is_solved, "Fixture should solve after rotation")

	var rotation_state: Dictionary = _get_dict_property(scene.pipe_vfx_layer, "rotation_event_state")
	var win_state: Dictionary = _get_dict_property(scene.pipe_vfx_layer, "win_state")
	passed = passed and _assert_equal(rotation_state.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Rotation event should store changed cell")
	passed = passed and _assert_true(float(rotation_state.get("event_time", -1.0)) >= 0.0, "Rotation event should store event time")
	passed = passed and _assert_true(float(win_state.get("event_time", -1.0)) >= 0.0, "Solved rotation should trigger win state")

	scene.reset_current_level(false)
	rotation_state = _get_dict_property(scene.pipe_vfx_layer, "rotation_event_state")
	win_state = _get_dict_property(scene.pipe_vfx_layer, "win_state")
	passed = passed and _assert_equal(rotation_state.size(), 0, "Reset should clear rotation event")
	passed = passed and _assert_equal(win_state.size(), 0, "Reset should clear win event")

	scene.pipe_vfx_layer.free()
	scene.free()
	if passed:
		print("test_game_scene_vfx_polish_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_vfx_polish_hooks: FAIL")
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

func _get_dict_property(object: Object, property_name: String) -> Dictionary:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			var value = object.get(property_name)
			if typeof(value) == TYPE_DICTIONARY:
				return value
	return {}

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_false(condition: bool, message: String) -> bool:
	if condition:
		push_error("%s: expected false" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
