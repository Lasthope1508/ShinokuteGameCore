extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

var _passed := true
var _failed_events := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene := load(MAIN_SCENE) as PackedScene
	_assert_true(packed_scene != null, "Main scene should load")
	if packed_scene == null:
		_finish()
		return

	var scene := packed_scene.instantiate()
	_release_audio_streams(scene)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame

	var progression := scene.get_node_or_null("GameProgression")
	var player := scene.get_node_or_null("Player") as Node3D
	var world := scene.get_node_or_null("World")
	_assert_true(progression != null, "GameProgression should exist")
	_assert_true(player != null, "Player should exist")
	_assert_true(world != null, "World should exist")
	if progression == null or player == null or world == null:
		_cleanup(scene)
		_finish()
		return

	progression.level_failed.connect(func(_level_index: int, _level: Resource) -> void:
		_failed_events += 1
	)

	var scene_instance_id := scene.get_instance_id()
	player.global_position.y = -50.0
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame

	_assert_eq(scene.get_instance_id(), scene_instance_id, "Death reset should keep the same main scene instance")
	_assert_eq(_failed_events, 1, "Death reset should emit one level_failed event")
	_assert_true(player.global_position.y > -5.0, "Player should reset above fall threshold after death")
	_assert_true("coins" in player and int(player.coins) == 0, "Player coins should reset after death")
	_assert_true(not bool(progression.get("_transition_in_progress")), "Progression transition guard should clear after reset")
	_assert_true(world.get_node_or_null("GeneratedStage") != null, "World should still have generated stage after death reset")

	_cleanup(scene)
	_finish()

func _cleanup(scene: Node) -> void:
	current_scene = null
	_release_audio_streams(scene)
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	scene.free()

func _release_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_release_audio_streams(child)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		_passed = false
		push_error(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [message, str(expected), str(actual)])

func _finish() -> void:
	if _passed:
		print("test_game_progression_runtime_reset: PASS")
		quit(0)
	else:
		print("test_game_progression_runtime_reset: FAIL")
		quit(1)
