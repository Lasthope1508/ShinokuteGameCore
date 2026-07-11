extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const USERNAME_SCENE := "res://scenes/ui/candy_username_prompt_overlay.tscn"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_assert_true(packed != null, "Main scene should load")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate()
	var bridge := scene.get_node_or_null("CandyGameCore")
	if bridge != null:
		bridge.save_path = "user://candy_text_fit_contract.cfg"
	_release_audio_streams(scene)
	root.add_child(scene)
	await process_frame

	var panel = scene.get_node_or_null("HUD/LeaderboardPanel")
	_assert_true(panel != null, "Leaderboard panel should exist")
	if panel != null:
		panel.show_leaderboard("world")
		if bridge != null:
			bridge.leaderboard_loaded.emit("world", [{"username": "CandyAce", "score": 7, "score_label": "level"}], "classic")
		await process_frame
		_assert_button_text_safe(scene.get_node_or_null("HUD/LeaderboardButton"), "leaderboard button")
		_assert_button_text_safe(scene.get_node_or_null("HUD/SettingsButton"), "settings button")
		_assert_matching_hud_button_metrics(scene.get_node_or_null("HUD/LeaderboardButton"), scene.get_node_or_null("HUD/SettingsButton"))
		_assert_button_text_safe(panel.get_node_or_null("Margin/VBox/Tabs/WorldButton"), "world tab")
		_assert_button_text_safe(panel.get_node_or_null("Margin/VBox/Tabs/CountryButton"), "country tab")
		var row_panel := panel.get_node_or_null("Margin/VBox/Rows/Row01")
		_assert_true(row_panel is PanelContainer, "Leaderboard rows should use a panel owner for row art")
		if row_panel is PanelContainer:
			var row_margin := row_panel.get_node_or_null("Margin") as MarginContainer
			_assert_true(row_margin != null, "Leaderboard row should have a text-safe Margin")
			if row_margin != null:
				_assert_true(row_margin.get_theme_constant("margin_left") >= 56, "Leaderboard row text should clear left candy cap")
				_assert_true(row_margin.get_theme_constant("margin_right") >= 56, "Leaderboard row text should clear right candy cap")
			var row_label := row_panel.get_node_or_null("Margin/Text") as Label
			_assert_true(row_label != null, "Leaderboard row should contain Text label")
			if row_label != null:
				_assert_true(row_label.get_theme_font_size("font_size") <= 18, "Leaderboard row font should fit thin row art")

	var username_packed := load(USERNAME_SCENE) as PackedScene
	_assert_true(username_packed != null, "Username scene should load")
	if username_packed != null:
		var username_scene := username_packed.instantiate()
		root.add_child(username_scene)
		await process_frame
		var margin := username_scene.get_node_or_null("Panel/Margin") as MarginContainer
		_assert_true(margin != null, "Username prompt should have Margin container")
		if margin != null:
			_assert_true(margin.get_theme_constant("margin_top") >= 66, "Username prompt text should clear top star/trim art")
			_assert_true(margin.get_theme_constant("margin_left") >= 64, "Username prompt text should clear left star/trim art")
			_assert_true(margin.get_theme_constant("margin_right") >= 64, "Username prompt text should clear right star/trim art")
		for path in ["Panel/Margin/VBox/Title", "Panel/Margin/VBox/Prompt", "Panel/Margin/VBox/NameEdit", "Panel/Margin/VBox/Buttons/SkipButton", "Panel/Margin/VBox/Buttons/ConfirmButton"]:
			var control := username_scene.get_node_or_null(path) as Control
			_assert_true(control != null, "%s should exist" % path)
			if control != null:
				_assert_true(control.get_theme_font_size("font_size") <= 18, "%s font should fit owner art" % path)
		var name_edit := username_scene.get_node_or_null("Panel/Margin/VBox/NameEdit") as LineEdit
		_assert_true(name_edit != null, "Username input should exist")
		if name_edit != null:
			_assert_true(name_edit.placeholder_text == "CandyPlayer", "Username placeholder should be visible before focus")
			name_edit.grab_focus()
			await process_frame
			_assert_true(name_edit.has_focus(), "Username input should receive focus")
			_assert_true(name_edit.placeholder_text == "", "Username placeholder should disappear on focus")
			_assert_true(name_edit.caret_blink, "Username input should show a blinking caret when focused")
			name_edit.release_focus()
			await process_frame
			_assert_true(name_edit.placeholder_text == "CandyPlayer", "Username placeholder should return after blur when empty")
		username_scene.queue_free()

	if bridge != null and bridge.core != null and bridge.core.save_store != null:
		bridge.core.save_store.wipe_all()
	_release_audio_streams(scene)
	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish()

func _assert_button_text_safe(button: Button, label: String) -> void:
	_assert_true(button != null, "%s should exist" % label)
	if button == null:
		return
	_assert_true(button.get_theme_font_size("font_size") <= 16, "%s font should fit candy button art" % label)
	var style := button.get_theme_stylebox("normal") as StyleBox
	_assert_true(style != null, "%s should have themed stylebox" % label)
	if style != null:
		_assert_true(style.get_content_margin(SIDE_LEFT) >= 24, "%s should clear left decoration" % label)
		_assert_true(style.get_content_margin(SIDE_RIGHT) >= 24, "%s should clear right decoration" % label)
		_assert_true(style.get_content_margin(SIDE_TOP) >= 8, "%s should clear top trim" % label)
		_assert_true(style.get_content_margin(SIDE_BOTTOM) >= 8, "%s should clear bottom trim" % label)

func _assert_matching_hud_button_metrics(rank_button: Button, settings_button: Button) -> void:
	_assert_true(rank_button != null, "rank button should exist for settings comparison")
	_assert_true(settings_button != null, "settings button should exist for settings comparison")
	if rank_button == null or settings_button == null:
		return
	_assert_true(absf(settings_button.size.x - rank_button.size.x) <= 1.0, "Settings button width should match Rank button")
	_assert_true(absf(settings_button.size.y - rank_button.size.y) <= 1.0, "Settings button height should match Rank button")
	_assert_true(absf(settings_button.position.y - rank_button.position.y) <= 1.0, "Settings button top should align with Rank button")
	_assert_true(settings_button.get_theme_font_size("font_size") == rank_button.get_theme_font_size("font_size"), "Settings button font should match Rank button")

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

func _finish() -> void:
	if _passed:
		print("test_candy_function_skin_text_fit_contract: PASS")
		quit(0)
	else:
		print("test_candy_function_skin_text_fit_contract: FAIL")
		quit(1)
