extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const OUT_DIR := "res://docs/screenshots"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1280, 720)

	var packed := load(MAIN_SCENE) as PackedScene
	_assert_true(packed != null, "Main scene should load")
	if packed == null:
		_finish()
		return

	var scene := packed.instantiate()
	var bridge := scene.get_node_or_null("CandyGameCore")
	if bridge != null:
		bridge.save_path = "user://candy_function_ui_screenshot.cfg"
	root.add_child(scene)
	current_scene = scene
	await _settle_frames(16)

	var panel = scene.get_node_or_null("HUD/LeaderboardPanel")
	_assert_true(panel != null, "Leaderboard panel should exist")
	if panel != null:
		panel.show_leaderboard("world")
		if bridge != null and bridge.has_signal("leaderboard_loaded"):
			bridge.leaderboard_loaded.emit("world", [
				{"username": "CandyAce", "score": 7, "score_label": "level"},
				{"username": "MintStar", "score": 5, "score_label": "level"},
				{"username": "SkyRunner", "score": 3, "score_label": "level"}
			], "classic")
		await _settle_frames(8)
		await _save_viewport("candy_function_ui_leaderboard.png", Rect2i(760, 20, 500, 470))
		panel.visible = false

	var username_overlay := bridge.get_node_or_null("UsernamePromptOverlay") if bridge != null else null
	if username_overlay != null:
		username_overlay.visible = false

	var settings_panel = scene.get_node_or_null("HUD/CandySettingsPanel")
	_assert_true(settings_panel != null, "Candy settings panel should exist")
	if settings_panel != null:
		settings_panel.visible = true
		if settings_panel.has_method("_refresh"):
			settings_panel._refresh()
		await _settle_frames(8)
		await _save_viewport("candy_function_ui_settings.png", Rect2i(760, 20, 500, 390))
		settings_panel.visible = false

	_assert_true(username_overlay != null, "Candy username prompt should appear when profile is missing")
	if username_overlay != null:
		username_overlay.visible = true
		var name_edit := username_overlay.get_node_or_null("Panel/Margin/VBox/NameEdit") as LineEdit
		if name_edit != null:
			name_edit.grab_focus()
		await _settle_frames(8)
		await _save_viewport("candy_function_ui_username.png", Rect2i(380, 160, 520, 390))

	if bridge != null and bridge.core != null and bridge.core.save_store != null:
		bridge.core.save_store.wipe_all()
	var audio_root := root.get_node_or_null("Audio")
	if audio_root != null:
		_release_audio_streams(audio_root)
	scene.queue_free()
	await _settle_frames(8)
	_finish()

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _save_viewport(file_name: String, crop_rect: Rect2i) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if crop_rect.size.x > 0 and crop_rect.size.y > 0:
		image = image.get_region(crop_rect)
	var error := image.save_png("%s/%s" % [OUT_DIR, file_name])
	_assert_true(error == OK, "Screenshot should save: %s" % file_name)
	_assert_true(_is_nonblank(image), "Screenshot should be nonblank: %s" % file_name)

func _is_nonblank(image: Image) -> bool:
	if image.get_width() <= 0 or image.get_height() <= 0:
		return false
	var first := image.get_pixel(0, 0)
	for y in range(0, image.get_height(), max(1, image.get_height() / 10)):
		for x in range(0, image.get_width(), max(1, image.get_width() / 10)):
			if image.get_pixel(x, y) != first:
				return true
	return false

func _release_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for child in node.get_children():
		_release_audio_streams(child)

func _assert_true(value: bool, message: String) -> void:
	if not value:
		_passed = false
		push_error(message)

func _finish() -> void:
	if _passed:
		print("capture_candy_function_ui_screenshots: PASS")
		quit(0)
	else:
		print("capture_candy_function_ui_screenshots: FAIL")
		quit(1)
