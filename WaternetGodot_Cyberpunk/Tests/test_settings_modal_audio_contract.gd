extends SceneTree

const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	passed = passed and _assert_true(AudioServer.get_bus_index("Music") >= 0, "AudioManager should provide canonical Music bus")
	passed = passed and _assert_true(AudioServer.get_bus_index("SFX") >= 0, "AudioManager should provide canonical SFX bus")
	var audio_manager = root.get_node_or_null("AudioManager")
	passed = passed and _assert_true(audio_manager != null, "AudioManager autoload should exist")
	if audio_manager != null:
		var music_player = audio_manager.get("_music_player")
		var bgm_player := music_player as AudioStreamPlayer
		passed = passed and _assert_true(bgm_player != null and bgm_player.bus == "Music", "BGM player should route to Music bus")
		var sfx_pool = audio_manager.get("_sfx_pool")
		passed = passed and _assert_true(not sfx_pool.is_empty(), "SFX pool should exist")
		if not sfx_pool.is_empty():
			var sfx_player := sfx_pool[0] as AudioStreamPlayer
			passed = passed and _assert_true(sfx_player != null and sfx_player.bus == "SFX", "SFX players should route to SFX bus")
		audio_manager.set_bus_volume("Music", 0.7)
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music bus should start unmuted")
		audio_manager.toggle_music_mute()
		passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music toggle should mute real Music bus")
		audio_manager.toggle_music_mute()
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music toggle should unmute real Music bus")
		audio_manager.set_bus_volume("SFX", 0.65)
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX bus should start unmuted")
		audio_manager.set_bus_volume("SFX", 0.0)
		passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX toggle path should mute real SFX bus")
		audio_manager.set_bus_volume("Music", 0.7)
		audio_manager.set_bus_volume("SFX", 0.65)
		audio_manager.set_bus_volume("Master", 0.0)
		audio_manager.apply_saved_volumes()
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Legacy hidden Master mute should not silence Music/SFX when settings show both enabled")
		audio_manager.toggle_master_mute()
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Global volume toggle should not use Master as a hidden output gate")
		passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Global volume toggle should mute Music bus")
		passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Global volume toggle should mute SFX bus")
		audio_manager.toggle_master_mute()
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Global volume toggle should restore Music bus")
		passed = passed and _assert_true(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Global volume toggle should restore SFX bus")

	var scene: PackedScene = load(GAME_SCENE_PATH)
	var theme: Resource = load(THEME_PATH)
	passed = passed and _assert_true(scene != null, "GameScene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if scene != null and theme != null:
		root.size = Vector2i(600, 920)
		var instance: Node = scene.instantiate()
		instance.active_theme_override = theme
		root.add_child(instance)
		await process_frame
		instance._apply_top_tray_theme(theme, Vector2(600, 920))
		instance._apply_generated_ui_assets(theme)
		instance._apply_modal_theme(theme, Vector2(600, 920))
		instance.settings_overlay.visible = true
		instance._update_settings_buttons()
		await process_frame
		var master_button := instance.get_node_or_null("HUD/SettingsOverlay/MarginContainer/VBoxContainer/MasterAudioBtn") as Button
		passed = passed and _assert_true(master_button != null, "Settings should expose Master Audio button")
		if master_button != null:
			passed = passed and _assert_true(master_button.text == "MASTER AUDIO ON", "Master Audio button should show ON when Music and SFX are enabled")
			instance._on_settings_master_audio_btn_pressed()
			await process_frame
			passed = passed and _assert_true(master_button.text == "MASTER AUDIO OFF", "Master Audio button should show OFF after global audio mute")
			passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Master Audio button should mute Music")
			passed = passed and _assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Master Audio button should mute SFX")
			instance._on_settings_master_audio_btn_pressed()
			await process_frame
			passed = passed and _assert_true(master_button.text == "MASTER AUDIO ON", "Master Audio button should show ON after global audio restore")
		var overlay_rect: Rect2 = instance.settings_overlay.get_global_rect()
		var option_paths := [
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/MasterAudioBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/MusicBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/SfxBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/ThemeModeBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/LeaderboardBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/RestartBtn",
			"HUD/SettingsOverlay/MarginContainer/VBoxContainer/LevelSelectBtn"
		]
		var expected_left := 1000000.0
		var expected_right := -1000000.0
		for path in option_paths:
			var button := instance.get_node_or_null(path) as Button
			passed = passed and _assert_true(button != null, "%s should exist" % path)
			if button == null:
				continue
			var rect: Rect2 = button.get_global_rect()
			expected_left = min(expected_left, rect.position.x)
			expected_right = max(expected_right, rect.end.x)
			passed = passed and _assert_true(button.get("icon") == null, "%s should be text-only so option text remains centered" % button.name)
			passed = passed and _assert_true(int(button.get("alignment")) == HORIZONTAL_ALIGNMENT_CENTER, "%s text should be centered" % button.name)
			passed = passed and _assert_true(rect.position.x >= overlay_rect.position.x + 4.0, "%s should stay inside modal left edge" % button.name)
			passed = passed and _assert_true(rect.end.x <= overlay_rect.end.x - 4.0, "%s should stay inside modal right edge" % button.name)
		for path in option_paths:
			var button := instance.get_node_or_null(path) as Button
			if button == null:
				continue
			var rect: Rect2 = button.get_global_rect()
			passed = passed and _assert_true(abs(rect.position.x - expected_left) <= 2.0 and abs(rect.end.x - expected_right) <= 2.0, "%s should share aligned option rails" % button.name)
		root.remove_child(instance)
		instance.free()
		await process_frame

	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music()
		for i in 4:
			await process_frame

	if passed:
		print("test_settings_modal_audio_contract: PASS")
		quit(0)
	else:
		print("test_settings_modal_audio_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
