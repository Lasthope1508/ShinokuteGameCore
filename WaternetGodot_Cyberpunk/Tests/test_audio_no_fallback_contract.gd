extends SceneTree

const AUDIO_MANAGER_PATH = "res://Resources/Globals/AudioManager.gd"
const THEME_MANAGER_PATH = "res://Resources/Globals/ThemeManager.gd"

func _init() -> void:
	var passed := true
	var audio_source := FileAccess.get_file_as_string(AUDIO_MANAGER_PATH)
	var theme_source := FileAccess.get_file_as_string(THEME_MANAGER_PATH)

	passed = passed and _assert_true(not audio_source.contains("res://Audio/Music/Gameplay.ogg"), "AudioManager should not fallback to root Gameplay.ogg")
	passed = passed and _assert_true(not audio_source.contains("MUSIC_PATH"), "AudioManager should not keep hardcoded music path constants")
	passed = passed and _assert_true(not audio_source.contains("const SFX_VOLUME_OFFSETS"), "AudioManager should not hardcode SFX volume offsets")
	passed = passed and _assert_true(not theme_source.contains("res://Audio/Sfx/default/"), "ThemeManager should not fallback to default SFX root")
	passed = passed and _assert_true(theme_source.contains("get_sfx_path"), "ThemeManager should resolve SFX through theme SSOT event map")
	passed = passed and _assert_true(audio_source.contains("bgm_path"), "AudioManager should resolve BGM through theme SSOT")

	if passed:
		print("test_audio_no_fallback_contract: PASS")
		quit(0)
	else:
		print("test_audio_no_fallback_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
