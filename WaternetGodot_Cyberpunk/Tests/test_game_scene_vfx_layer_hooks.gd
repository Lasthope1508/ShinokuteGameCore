extends SceneTree

const GAME_SCENE_SCRIPT = preload("res://Scenes/Gameplay/GameScene.gd")

func _init() -> void:
	var passed := true
	var scene = GAME_SCENE_SCRIPT.new()

	passed = passed and _assert_true(scene.has_method("_ensure_vfx_layer"), "GameScene should create a separate VFX layer")
	passed = passed and _assert_true(scene.has_method("_sync_vfx_layer"), "GameScene should sync VFX layer context")

	if scene.has_method("_ensure_vfx_layer"):
		scene._ensure_vfx_layer()
		passed = passed and _assert_true(scene.pipe_vfx_layer != null, "GameScene should hold PipeVfxLayer reference")
		passed = passed and _assert_true(scene.pipe_vfx_layer.get_parent() == scene, "PipeVfxLayer should be a child overlay")
		passed = passed and _assert_true(scene.pipe_vfx_layer.z_index > 0, "PipeVfxLayer should draw above base board")

	if scene.has_method("_sync_vfx_layer") and scene.pipe_vfx_layer != null:
		scene.flow_visual_state = {Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [], "age": 0.0}}
		scene.CELL_SIZE = 88.0
		scene.GRID_OFFSET = Vector2(14, 28)
		scene._sync_vfx_layer()
		passed = passed and _assert_equal(scene.pipe_vfx_layer.flow_state.size(), 1, "GameScene should pass flow state into VFX layer")
		passed = passed and _assert_float_close(scene.pipe_vfx_layer.cell_size, 88.0, "GameScene should pass cell size into VFX layer")
		passed = passed and _assert_equal(scene.pipe_vfx_layer.grid_offset, Vector2(14, 28), "GameScene should pass grid offset into VFX layer")

	scene.free()

	if passed:
		print("test_game_scene_vfx_layer_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_vfx_layer_hooks: FAIL")
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
