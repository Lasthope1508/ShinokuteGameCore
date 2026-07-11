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
	root.add_child(scene)
	await process_frame
	await process_frame

	var bridge := scene.get_node_or_null("CandyGameCore")
	var view := scene.get_node_or_null("View")
	var panel := scene.get_node_or_null("HUD/CandySettingsPanel")
	passed = _assert_true(bridge != null, "CandyGameCore bridge should exist") and passed
	passed = _assert_true(view != null, "View should exist") and passed
	passed = _assert_true(panel != null, "Candy settings panel should exist") and passed

	if bridge != null and view != null and panel != null:
		passed = _assert_true(bridge.is_sfx_enabled(), "SFX default should be on") and passed
		passed = _assert_true(bridge.is_bgm_enabled(), "BGM default should be on") and passed
		passed = _assert_true(not bridge.is_shift_lock_enabled(), "shift lock default should be off") and passed
		passed = _assert_true(not view.shift_lock_enabled, "View should receive default shift lock off") and passed
		passed = _assert_true(panel.get_node("Margin/VBox/SfxRow/Margin/Line/Toggle").text == "ON", "SFX toggle should render ON") and passed
		passed = _assert_true(panel.get_node("Margin/VBox/ShiftLockRow/Margin/Line/Toggle").text == "OFF", "Shift lock toggle should render OFF by default") and passed

		bridge.set_sfx_enabled(false)
		bridge.set_bgm_enabled(false)
		bridge.set_shift_lock_enabled(true)
		await process_frame
		var audio := root.get_node_or_null("Audio")
		passed = _assert_true(audio != null, "Audio autoload should exist") and passed
		if audio != null:
			passed = _assert_true(not audio.is_sfx_enabled(), "Audio SFX gate should turn off") and passed
			passed = _assert_true(not audio.is_bgm_enabled(), "Audio BGM gate should turn off") and passed
		passed = _assert_true(view.shift_lock_enabled, "View shift lock should turn on") and passed
		passed = _assert_true(panel.get_node("Margin/VBox/ShiftLockRow/Margin/Line/Toggle").text == "ON", "Shift lock toggle should render ON after enable") and passed

		bridge.set_sfx_enabled(true)
		bridge.set_bgm_enabled(true)
		bridge.set_shift_lock_enabled(false)

	_release_audio_streams(scene)
	var audio_root := root.get_node_or_null("Audio")
	if audio_root != null:
		_release_audio_streams(audio_root)
	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish(passed)

func _release_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for child in node.get_children():
		_release_audio_streams(child)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_candy_settings_runtime_contract: PASS")
		quit(0)
	else:
		print("test_candy_settings_runtime_contract: FAIL")
		quit(1)
