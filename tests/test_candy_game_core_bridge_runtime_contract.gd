extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

var _passed := true

class FakeLeaderboard:
	extends Node
	var submitted: Array = []

	func submit_score(score: int, mode: String = "classic") -> int:
		submitted.append({"score": score, "mode": mode})
		return OK

	func fetch_leaderboard(tab: String, mode: String = "classic") -> int:
		return OK

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene = load(MAIN_SCENE)
	_assert_true(packed_scene != null, "Main scene should load")
	var scene = packed_scene.instantiate() if packed_scene != null else null
	_assert_true(scene != null, "Main scene should instantiate")
	if scene == null:
		_finish()
		return

	var bridge = scene.get_node_or_null("CandyGameCore")
	_assert_true(bridge != null, "CandyGameCore bridge should exist")
	if bridge != null:
		bridge.save_path = "user://candy_sky_islands_core_bridge_test.cfg"
	_release_audio_streams(scene)
	root.add_child(scene)
	await process_frame

	if bridge != null:
		_assert_true(bridge.core != null, "Bridge should create GameCore")
		_assert_true(bridge.core.profile != null, "GameCore should expose core PlayerProfile")
		_assert_true(bridge.core.leaderboard != null, "GameCore should expose core LeaderboardClient")
		_assert_true(bridge.get_node_or_null("UsernamePromptOverlay") != null, "Bridge should show Candy username prompt when username is missing")
		var touch_controls = scene.get_node_or_null("HUD/MobileTouchControls")
		if touch_controls != null and touch_controls.has_method("set_touch_controls_visible"):
			touch_controls.set_touch_controls_visible(true)
			bridge._on_username_required()
			_assert_true(not touch_controls.visible, "Username prompt should hide mobile touch controls so Web touch events reach modal buttons")
		bridge._on_level_completed(2, null)
		_assert_eq(bridge.core.save_store.get_pending_score("classic"), 3, "Level completion should store pending score through core when username is missing")
		var fake := FakeLeaderboard.new()
		bridge.core.add_child(fake)
		bridge.core.leaderboard = fake
		_assert_true(bridge.core.profile.commit_username("CandyTester"), "Core profile should commit username")
		await process_frame
		_assert_eq(fake.submitted.size(), 1, "Core should flush pending score after username commit")
		if fake.submitted.size() == 1:
			_assert_eq(fake.submitted[0]["score"], 3, "Flushed score should match completed level score")
			_assert_eq(fake.submitted[0]["mode"], "classic", "Flushed score should use configured mode")
		var panel = scene.get_node_or_null("HUD/LeaderboardPanel")
		_assert_true(panel != null, "Leaderboard panel should exist")
		if panel != null:
			panel.show_leaderboard("world")
			bridge.leaderboard_loaded.emit("world", [{"username": "CandyTester", "score": 3, "score_label": "level"}], "classic")
			await process_frame
			var rows = panel.get_node_or_null("Margin/VBox/Rows")
			_assert_true(rows != null and rows.get_child_count() == 1, "Leaderboard panel should render core leaderboard rows")
			if rows != null and rows.get_child_count() == 1:
				var row_label := rows.get_child(0).get_node_or_null("Margin/Text") as Label
				_assert_true(row_label != null and String(row_label.text).contains("CandyTester"), "Rendered leaderboard row should show username")
		bridge.core.save_store.wipe_all()

	_release_audio_streams(scene)
	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish()

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
		print("test_candy_game_core_bridge_runtime_contract: PASS")
		quit(0)
	else:
		print("test_candy_game_core_bridge_runtime_contract: FAIL")
		quit(1)
