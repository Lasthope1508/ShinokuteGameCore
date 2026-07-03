extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.gd"
const AUDIO_MANAGER_PATH = "res://Resources/Globals/AudioManager.gd"
const THEME_MANAGER_PATH = "res://Resources/Globals/ThemeManager.gd"

func _init() -> void:
	var passed := true
	var source := FileAccess.get_file_as_string(GAME_SCENE_PATH)
	var audio_source := FileAccess.get_file_as_string(AUDIO_MANAGER_PATH)
	var theme_source := FileAccess.get_file_as_string(THEME_MANAGER_PATH)
	passed = passed and _assert_true(not source.contains("energy_sheets_ai"), "GameScene should not reference AI fallback energy sheets")
	passed = passed and _assert_true(not source.contains("ENERGY_SHEET_AI_ROOT"), "GameScene should not keep fallback root constants")
	passed = passed and _assert_true(not source.contains("return frame_texture if frame_texture != null else base_texture"), "Energy texture helper should not fallback to base texture")
	passed = passed and _assert_true(not audio_source.contains("res://Audio/Music/Gameplay.ogg"), "AudioManager should not fallback to root BGM")
	passed = passed and _assert_true(not theme_source.contains("res://Audio/Sfx/default/"), "ThemeManager should not fallback to default SFX")

	if passed:
		print("test_no_runtime_fallback_contract: PASS")
		quit(0)
	else:
		print("test_no_runtime_fallback_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
