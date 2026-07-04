extends SceneTree

const BUS_LAYOUT_PATH := "res://default_bus_layout.tres"

func _init() -> void:
	var passed := true
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var audio_manager := FileAccess.get_file_as_string("res://Resources/Globals/AudioManager.gd")

	passed = passed and _assert_true(FileAccess.file_exists(BUS_LAYOUT_PATH), "default audio bus layout should exist")
	passed = passed and _assert_true(project_text.contains("[audio]"), "project should declare audio settings")
	passed = passed and _assert_true(project_text.contains("buses/default_bus_layout=\"res://default_bus_layout.tres\""), "project should load canonical audio bus layout")
	passed = passed and _assert_true(export_presets.contains("\"res://default_bus_layout.tres\""), "Web/Android selected-resource export should include audio bus layout")
	passed = passed and _assert_true(audio_manager.contains("const BUS_MUSIC := \"Music\""), "AudioManager should use canonical Music bus")
	passed = passed and _assert_true(audio_manager.contains("const BUS_SFX := \"SFX\""), "AudioManager should use canonical SFX bus")
	passed = passed and _assert_true(AudioServer.get_bus_index("Music") >= 0, "Music bus should exist before AudioManager creates dynamic buses")
	passed = passed and _assert_true(AudioServer.get_bus_index("SFX") >= 0, "SFX bus should exist before AudioManager creates dynamic buses")

	if passed:
		print("test_audio_bus_layout_contract: PASS")
		quit(0)
	else:
		print("test_audio_bus_layout_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
