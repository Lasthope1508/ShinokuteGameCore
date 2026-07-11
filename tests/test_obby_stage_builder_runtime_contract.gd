extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var config = load(CONFIG_PATH)
	_assert_true(config != null, "Progression config should load")
	var first_level = config.get_level(0) if config != null else null
	_assert_true(first_level != null, "First level should load")

	var packed_scene = load(MAIN_SCENE)
	_assert_true(packed_scene != null, "Main scene should load")
	var main = packed_scene.instantiate() if packed_scene != null else null
	_assert_true(main != null, "Main scene should instantiate")
	if main != null:
		_release_audio_streams(main)
		root.add_child(main)
		await process_frame
		var world = main.get_node_or_null("World")
		_assert_true(world != null, "World should exist")
		if world != null:
			_assert_eq(world.get_child_count(), 1, "World should not keep static hand-placed gameplay nodes")
			var generated = world.get_node_or_null("GeneratedStage")
			_assert_true(generated != null, "World should create GeneratedStage")
			if generated != null and first_level != null:
				var minimum_children: int = first_level.stage_segments.size() + first_level.environment_segments.size()
				_assert_true(generated.get_child_count() >= minimum_children, "GeneratedStage should contain route and environment nodes")
				_assert_true(_has_child_name_part(generated, "_goal"), "GeneratedStage should contain generated goal")
				_assert_true(_has_child_name_part(generated, "env_brick"), "GeneratedStage should contain generated brick terrain")
				_assert_true(_has_child_name_part(generated, "env_cloud"), "GeneratedStage should contain generated cloud decor")
		_release_audio_streams(main)
		root.remove_child(main)
		main.free()
		main = null
		packed_scene = null
		first_level = null
		config = null
		await process_frame

	if _passed:
		print("test_obby_stage_builder_runtime_contract: PASS")
		quit(0)
	else:
		print("test_obby_stage_builder_runtime_contract: FAIL")
		quit(1)

func _has_child_name_part(parent: Node, needle: String) -> bool:
	for child in parent.get_children():
		if String(child.name).contains(needle):
			return true
	return false

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
