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

	var settings_button := scene.get_node_or_null("HUD/SettingsButton") as Button
	var leaderboard_button := scene.get_node_or_null("HUD/LeaderboardButton") as Button
	var settings_panel := scene.get_node_or_null("HUD/CandySettingsPanel") as PanelContainer
	var leaderboard_panel := scene.get_node_or_null("HUD/LeaderboardPanel") as PanelContainer
	passed = _assert_true(settings_button != null, "Settings button should exist") and passed
	passed = _assert_true(leaderboard_button != null, "Leaderboard button should exist") and passed
	passed = _assert_true(settings_panel != null, "Settings panel should exist") and passed
	passed = _assert_true(leaderboard_panel != null, "Leaderboard panel should exist") and passed

	if settings_button != null and leaderboard_button != null and settings_panel != null and leaderboard_panel != null:
		for button in [
			settings_button,
			leaderboard_button,
			settings_panel.get_node("Margin/VBox/Header/CloseButton"),
			settings_panel.get_node("Margin/VBox/SfxRow/Margin/Line/Toggle"),
			settings_panel.get_node("Margin/VBox/BgmRow/Margin/Line/Toggle"),
			settings_panel.get_node("Margin/VBox/ShiftLockRow/Margin/Line/Toggle"),
			leaderboard_panel.get_node("Margin/VBox/Header/CloseButton"),
			leaderboard_panel.get_node("Margin/VBox/Tabs/WorldButton"),
			leaderboard_panel.get_node("Margin/VBox/Tabs/CountryButton")
		]:
			passed = _assert_true((button as Button).focus_mode == Control.FOCUS_NONE, "%s should not keep keyboard focus and steal Space jump" % button.name) and passed

		settings_button.pressed.emit()
		await process_frame
		passed = _assert_true(settings_panel.visible, "Settings should open from HUD button") and passed
		passed = _assert_true(not leaderboard_panel.visible, "Leaderboard should stay closed when Settings opens") and passed

		leaderboard_button.pressed.emit()
		await process_frame
		passed = _assert_true(leaderboard_panel.visible, "Leaderboard should open from HUD button") and passed
		passed = _assert_true(not settings_panel.visible, "Settings should close when Leaderboard opens") and passed

		settings_button.pressed.emit()
		await process_frame
		passed = _assert_true(settings_panel.visible, "Settings should open from HUD button after Leaderboard") and passed
		passed = _assert_true(not leaderboard_panel.visible, "Leaderboard should close when Settings opens") and passed

		settings_button.pressed.emit()
		await process_frame
		passed = _assert_true(not settings_panel.visible, "Settings button should close Settings when pressed again") and passed
		passed = _assert_true(get_root().gui_get_focus_owner() == null, "Closing Settings should release UI keyboard focus so Space stays gameplay input") and passed

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
		print("test_candy_function_overlay_contract: PASS")
		quit(0)
	else:
		print("test_candy_function_overlay_contract: FAIL")
		quit(1)
