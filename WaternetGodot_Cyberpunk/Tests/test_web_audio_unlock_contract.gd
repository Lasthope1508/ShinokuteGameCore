extends SceneTree

func _init() -> void:
	var passed := true
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var audio_doc := FileAccess.get_file_as_string("res://docs/audio_pipeline.md")
	var audio_manager := FileAccess.get_file_as_string("res://Resources/Globals/AudioManager.gd")
	var web_shell := FileAccess.get_file_as_string("res://Resources/Web/glyphflow_web_shell.html")
	passed = passed and _assert_true(export_presets.contains("html/head_include=\"\""), "Web export should not inject an AudioContext wrapper")
	passed = passed and _assert_true(not export_presets.contains("__glyphflowAudioUnlockState"), "Web export should not shadow Godot WebAudio internals")
	passed = passed and _assert_true(export_presets.contains("html/custom_html_shell=\"\""), "Web export should use the Godot default HTML shell like the working Bloxchain export")
	passed = passed and _assert_true(not web_shell.contains("TAP TO ENABLE AUDIO"), "Archived custom shell should not keep a blocking audio gate")
	passed = passed and _assert_true(not audio_manager.contains("__glyphflowAudioUnlockState"), "AudioManager should not call removed Web audio wrapper hooks")
	passed = passed and _assert_true(not audio_manager.contains("_resume_web_audio_context"), "AudioManager should not own custom Web audio resume hooks")
	passed = passed and _assert_true(audio_manager.contains("func _input(event: InputEvent)"), "AudioManager should receive first Web user gesture")
	passed = passed and _assert_true(audio_manager.contains("OS.has_feature(\"web\")"), "AudioManager Web unlock should be web-only")
	passed = passed and _assert_true(audio_manager.contains("_unlock_web_audio_after_user_gesture"), "AudioManager should restart BGM from the first Web user gesture")
	passed = passed and _assert_true(audio_manager.contains("web_audio_unlock_attempted"), "AudioManager debug state should expose Web audio unlock state")
	passed = passed and _assert_true(audio_doc.contains("Godot default HTML shell"), "Audio pipeline doc should record the Godot default shell policy")
	passed = passed and _assert_true(audio_doc.contains("do not wrap AudioContext"), "Audio pipeline doc should forbid AudioContext wrappers")

	if passed:
		print("test_web_audio_unlock_contract: PASS")
		quit(0)
	else:
		print("test_web_audio_unlock_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
