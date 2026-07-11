extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const AUDIO_SCRIPT := "res://scripts/audio.gd"
const MAIN_SCRIPT := "res://scripts/main.gd"
const PLAYER_SCRIPT := "res://scripts/player.gd"
const PLAYER_CORE_SCRIPT := "res://addons/shinokute_game_core/controllers/character_3d_controller.gd"
const COIN_SCRIPT := "res://objects/coin.gd"
const BRICK_SCRIPT := "res://objects/brick.gd"
const PLATFORM_FALLING_SCRIPT := "res://objects/platform_falling.gd"

const REQUIRED_AUDIO_EVENTS := ["jump", "land", "coin", "walking", "break", "fall"]
const HARDCODED_SFX := [
	"res://sounds/jump.ogg",
	"res://sounds/land.ogg",
	"res://sounds/coin.ogg",
	"res://sounds/break.ogg",
	"res://sounds/fall.ogg"
]

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		var audio_event_paths = theme.get("audio_event_paths")
		passed = passed and _assert_true(audio_event_paths is Dictionary, "Theme should expose audio_event_paths")
		if audio_event_paths is Dictionary:
			for event_name in REQUIRED_AUDIO_EVENTS:
				passed = passed and _assert_true(audio_event_paths.has(event_name), "Theme audio_event_paths should include %s" % event_name)
				if audio_event_paths.has(event_name):
					passed = passed and _assert_true(ResourceLoader.exists(audio_event_paths[event_name]), "%s audio path should exist: %s" % [event_name, audio_event_paths[event_name]])
	passed = passed and _assert_file_contains(AUDIO_SCRIPT, "func configure_events", "Audio should expose configure_events")
	passed = passed and _assert_file_contains(AUDIO_SCRIPT, "func play_event", "Audio should expose play_event")
	passed = passed and _assert_file_contains(MAIN_SCRIPT, "has_method(\"configure_events\")", "Main should guard audio event configuration")
	passed = passed and _assert_file_contains(MAIN_SCRIPT, "Audio.configure_events(theme_config.audio_event_paths)", "Main should configure Audio from theme_config.audio_event_paths")
	passed = passed and _assert_file_contains(PLAYER_SCRIPT, PLAYER_CORE_SCRIPT, "Candy player should inherit core controller for player audio events")
	passed = passed and _assert_routes_event(PLAYER_CORE_SCRIPT, "land", "Core player should route land sound through Audio.play_event") and passed
	passed = passed and _assert_routes_event(PLAYER_CORE_SCRIPT, "jump", "Core player should route jump sound through Audio.play_event") and passed
	passed = passed and _assert_routes_event(COIN_SCRIPT, "coin", "Coin should route collect sound through Audio.play_event") and passed
	passed = passed and _assert_routes_event(BRICK_SCRIPT, "break", "Brick should route break sound through Audio.play_event") and passed
	passed = passed and _assert_routes_event(PLATFORM_FALLING_SCRIPT, "fall", "Falling platform should route fall sound through Audio.play_event") and passed
	for script_path in [PLAYER_SCRIPT, PLAYER_CORE_SCRIPT, COIN_SCRIPT, BRICK_SCRIPT, PLATFORM_FALLING_SCRIPT]:
		for sound_path in HARDCODED_SFX:
			passed = passed and _assert_file_not_contains(script_path, sound_path, "%s should not hardcode %s" % [script_path, sound_path])
	if passed:
		print("test_deep_reskin_audio_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_audio_contract: FAIL")
		quit(1)

func _assert_routes_event(path: String, event_name: String, message: String) -> bool:
	return _assert_file_contains(path, "Audio.play_event(\"%s\")" % event_name, message)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains(needle):
		push_error("%s: found '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
