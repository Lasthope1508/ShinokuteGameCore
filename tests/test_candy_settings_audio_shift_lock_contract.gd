extends SceneTree

const THEME_SCRIPT := "res://Resources/QuantumThemeConfig.gd"
const THEME_CONFIG := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const CORE_CONFIG := "res://Resources/Data/Core/candy_sky_islands_game_core_config.tres"
const MAIN_SCENE := "res://scenes/main.tscn"
const BRIDGE_SCRIPT := "res://scripts/candy_game_core_bridge.gd"
const VIEW_SCRIPT := "res://scripts/view.gd"
const VIEW_CORE_SCRIPT := "res://addons/shinokute_game_core/controllers/follow_camera_3d.gd"
const AUDIO_SCRIPT := "res://scripts/audio.gd"
const PLAYER_SCENE := "res://objects/player.tscn"
const MANIFEST := "res://docs/asset_manifest.md"

const REQUIRED_AUDIO_EVENTS := {
	"jump": "res://sounds/candy_sky_islands/sfx_jump.ogg",
	"land": "res://sounds/candy_sky_islands/sfx_land.ogg",
	"coin": "res://sounds/candy_sky_islands/sfx_coin.ogg",
	"walking": "res://sounds/candy_sky_islands/sfx_walking.ogg",
	"break": "res://sounds/candy_sky_islands/sfx_break.ogg",
	"fall": "res://sounds/candy_sky_islands/sfx_fall.ogg"
}

func _init() -> void:
	var passed := true
	var theme_script := FileAccess.get_file_as_string(THEME_SCRIPT)
	var theme_config := FileAccess.get_file_as_string(THEME_CONFIG)
	var core_config := FileAccess.get_file_as_string(CORE_CONFIG)
	var main_scene := FileAccess.get_file_as_string(MAIN_SCENE)
	var bridge_script := FileAccess.get_file_as_string(BRIDGE_SCRIPT)
	var view_script := FileAccess.get_file_as_string(VIEW_SCRIPT)
	var view_core_script := FileAccess.get_file_as_string(VIEW_CORE_SCRIPT)
	var audio_script := FileAccess.get_file_as_string(AUDIO_SCRIPT)
	var player_scene := FileAccess.get_file_as_string(PLAYER_SCENE)
	var manifest := FileAccess.get_file_as_string(MANIFEST)

	passed = _assert_true(theme_script.contains("bgm_track_path"), "QuantumThemeConfig should expose bgm_track_path") and passed
	passed = _assert_true(theme_script.contains("ui_settings_panel_path"), "QuantumThemeConfig should expose settings panel asset path") and passed
	passed = _assert_true(theme_script.contains("ui_settings_row_path"), "QuantumThemeConfig should expose settings row asset path") and passed
	passed = _assert_true(theme_config.contains("bgm_track_path = \"res://sounds/candy_sky_islands/bgm_candy_island_main.ogg\""), "Candy theme should route processed BGM") and passed
	passed = _assert_true(core_config.contains("settings_defaults = {\"bgm_enabled\": true, \"sfx_enabled\": true, \"shift_lock_enabled\": false}"), "Candy core config should default BGM/SFX on and shift lock off") and passed

	for event_name in REQUIRED_AUDIO_EVENTS.keys():
		var path := String(REQUIRED_AUDIO_EVENTS[event_name])
		passed = _assert_true(theme_config.contains("\"%s\": \"%s\"" % [event_name, path]), "Candy theme should route %s to processed Candy SFX" % event_name) and passed
		passed = _assert_true(FileAccess.file_exists(path), "Candy SFX file should exist: %s" % path) and passed

	passed = _assert_true(FileAccess.file_exists("res://sounds/candy_sky_islands/bgm_candy_island_main.ogg"), "Processed combined Candy BGM should exist") and passed
	passed = _assert_true(audio_script.contains("func set_sfx_enabled"), "Audio autoload should expose SFX setting") and passed
	passed = _assert_true(audio_script.contains("func set_bgm_enabled"), "Audio autoload should expose BGM setting") and passed
	passed = _assert_true(audio_script.contains("func play_bgm"), "Audio autoload should play BGM from theme") and passed
	passed = _assert_true(player_scene.contains("res://sounds/candy_sky_islands/sfx_walking.ogg"), "Footstep stream should use Candy walking SFX") and passed

	passed = _assert_true(bridge_script.contains("settings_changed"), "Candy bridge should emit settings_changed") and passed
	passed = _assert_true(bridge_script.contains("set_shift_lock_enabled"), "Candy bridge should expose shift lock setter") and passed
	passed = _assert_true(view_script.contains(VIEW_CORE_SCRIPT), "Candy View should inherit Shinokute core follow camera") and passed
	passed = _assert_true(view_core_script.contains("set_shift_lock_enabled"), "Core follow camera should accept shift lock setting") and passed
	passed = _assert_true(view_core_script.contains("shift_lock_enabled"), "Core follow camera should store shift lock state") and passed
	passed = _assert_true(main_scene.contains("SettingsButton"), "Main HUD should contain settings button") and passed
	passed = _assert_true(main_scene.contains("CandySettingsPanel"), "Main HUD should contain Candy settings panel") and passed
	passed = _assert_true(main_scene.contains("res://scripts/candy_settings_panel.gd"), "Main scene should use Candy settings panel script") and passed

	for key in ["ui.settings.panel", "ui.settings.row", "ui.settings.toggle", "audio.bgm.candy_island_main"]:
		passed = _assert_true(manifest.contains("| %s |" % key), "Asset manifest should record %s" % key) and passed

	_finish(passed)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_candy_settings_audio_shift_lock_contract: PASS")
		quit(0)
	else:
		print("test_candy_settings_audio_shift_lock_contract: FAIL")
		quit(1)
