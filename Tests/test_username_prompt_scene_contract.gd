extends SceneTree

const ScenePath := "res://addons/shinokute_game_core/ui/username_prompt_overlay.tscn"

var _passed := true

func _init() -> void:
	var packed := load(ScenePath) as PackedScene
	_assert_true(packed != null, "username prompt scene loads")
	if packed != null:
		var inst = packed.instantiate()
		_assert_true(inst.has_signal("username_submitted"), "scene has username_submitted signal")
		_assert_true(inst.has_signal("username_skipped"), "scene has username_skipped signal")
		_assert_true(inst.has_method("configure"), "scene exposes configure")
		_assert_true(inst.get_node_or_null("Panel/Margin/VBox/NameEdit") is LineEdit, "scene owns LineEdit")
		_assert_true(inst.get_node_or_null("Panel/Margin/VBox/Buttons/ConfirmButton") is Button, "scene owns confirm button")
		_assert_true(inst.get_node_or_null("Panel/Margin/VBox/Buttons/SkipButton") is Button, "scene owns skip button")
		inst.queue_free()
	_report("test_username_prompt_scene_contract")

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
