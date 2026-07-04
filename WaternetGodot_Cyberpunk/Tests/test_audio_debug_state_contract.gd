extends SceneTree

const AUDIO_MANAGER_PATH := "res://Resources/Globals/AudioManager.gd"

func _init() -> void:
	var passed := true
	var audio_source := FileAccess.get_file_as_string(AUDIO_MANAGER_PATH)
	passed = passed and _assert_true(audio_source.contains("func get_debug_state()"), "AudioManager should expose canonical debug state")
	passed = passed and _assert_true(audio_source.contains("_publish_web_debug_state"), "AudioManager should publish Web runtime audio state")
	passed = passed and _assert_true(audio_source.contains("glyphflowAudioDebug"), "Web debug state should use canonical DOM dataset key")
	passed = passed and _assert_true(audio_source.contains("music_playing"), "Debug state should include BGM player play state")
	passed = passed and _assert_true(audio_source.contains("music_stream_path"), "Debug state should include BGM stream path")
	passed = passed and _assert_true(audio_source.contains("music_bus_muted"), "Debug state should include Music bus mute state")
	passed = passed and _assert_true(audio_source.contains("sfx_bus_muted"), "Debug state should include SFX bus mute state")
	passed = passed and _assert_true(audio_source.contains("master_bus_muted"), "Debug state should include Master bus mute state")
	passed = passed and _assert_true(audio_source.contains("web_audio_unlock_attempted"), "Debug state should include Web audio unlock attempt state")
	passed = passed and _assert_true(audio_source.contains("web_audio_unlock_input_count"), "Debug state should include Web audio unlock input count")

	if passed:
		print("test_audio_debug_state_contract: PASS")
		quit(0)
	else:
		print("test_audio_debug_state_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
