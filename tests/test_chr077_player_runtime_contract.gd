extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var packed_scene := load(MAIN_SCENE) as PackedScene
	passed = _assert_true(packed_scene != null, "Main scene should load") and passed
	if packed_scene == null:
		_finish(false)
		return

	var scene := packed_scene.instantiate()
	_release_audio_streams(scene)
	root.add_child(scene)
	current_scene = scene

	var player := scene.get_node_or_null("Player")
	passed = _assert_true(player != null, "Player should exist") and passed
	if player != null:
		passed = _assert_true(player.get_node_or_null("Character/CHR077SkeletonMageSlot") != null, "CHR077 scale slot should exist under player Character") and passed
		passed = _assert_true(player.get_node_or_null("Character/CHR077SkeletonMageSlot/CHR077SkeletonMageVisual") != null, "CHR077 visual should exist under player Character scale slot") and passed
		var player_animation := player.get_node_or_null("Character/AnimationPlayer") as AnimationPlayer
		passed = _assert_true(player_animation != null, "Player should keep Character/AnimationPlayer") and passed
		if player_animation != null:
			for animation_name in ["idle", "walk", "jump", "run"]:
				passed = _assert_true(player_animation.has_animation(animation_name), "Player should keep %s animation" % animation_name) and passed

	current_scene = null
	_release_audio_streams(scene)
	root.remove_child(scene)
	scene.free()
	player = null
	packed_scene = null
	_finish(passed)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _release_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_release_audio_streams(child)

func _finish(passed: bool) -> void:
	if passed:
		print("test_chr077_player_runtime_contract: PASS")
		quit(0)
	else:
		print("test_chr077_player_runtime_contract: FAIL")
		quit(1)
