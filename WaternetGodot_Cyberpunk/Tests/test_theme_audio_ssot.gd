extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const REQUIRED_EVENTS := [
	"ui_button",
	"ui_popup",
	"pipe_rotate",
	"invalid_rotate",
	"energy_enter_tile",
	"energy_connect_segment",
	"disconnect",
	"target_reached",
	"win",
	"reset",
	"timeout",
	"gameover"
]

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	for property_name in [
		"bgm_path",
		"bgm_manifest_path",
		"bgm_mobile_sample_rate",
		"bgm_mobile_channels",
		"bgm_vorbis_quality",
		"sfx_event_paths",
		"sfx_event_volume_offsets",
		"sfx_event_pitch_variation"
	]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)

	if theme != null and _has_property(theme, "bgm_path"):
		passed = passed and _assert_equal(theme.get("bgm_path"), "res://Audio/Music/cyberpunk_theme/Gameplay.ogg", "Cyber BGM should use canonical theme path")
		passed = passed and _assert_true(ResourceLoader.exists(theme.get("bgm_path")), "Cyber BGM file should exist")
		passed = passed and _assert_equal(int(theme.get("bgm_mobile_sample_rate")), 44100, "Cyber BGM should be mobile 44.1kHz")
		passed = passed and _assert_equal(int(theme.get("bgm_mobile_channels")), 1, "Cyber BGM should use mobile publish mono")
		passed = passed and _assert_equal(int(theme.get("bgm_vorbis_quality")), 0, "Cyber BGM should use mobile publish Vorbis quality 0")
		passed = passed and _assert_true(FileAccess.file_exists(theme.get("bgm_manifest_path")), "Cyber BGM manifest should exist")
		passed = passed and _assert_true(_manifest_matches_mobile_contract(theme.get("bgm_manifest_path")), "BGM manifest should record mobile encode and source order")

	if theme != null and _has_property(theme, "sfx_event_paths"):
		var sfx_paths: Dictionary = theme.get("sfx_event_paths")
		for event_name in REQUIRED_EVENTS:
			passed = passed and _assert_true(sfx_paths.has(event_name), "Cyber SFX map should include %s" % event_name)
			if sfx_paths.has(event_name):
				var path := String(sfx_paths[event_name])
				passed = passed and _assert_true(path.begins_with("res://Audio/Sfx/cyberpunk_theme/"), "%s should use canonical cyber SFX root" % event_name)
				passed = passed and _assert_true(ResourceLoader.exists(path), "%s SFX should exist at %s" % [event_name, path])

	if passed:
		print("test_theme_audio_ssot: PASS")
		quit(0)
	else:
		print("test_theme_audio_ssot: FAIL")
		quit(1)

func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

func _manifest_matches_mobile_contract(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var bgm: Dictionary = parsed.get("bgm", {})
	var source_order: Array = bgm.get("source_order", [])
	return String(bgm.get("output", "")) == "res://Audio/Music/cyberpunk_theme/Gameplay.ogg" \
		and String(bgm.get("codec", "")) == "ogg_vorbis" \
		and int(bgm.get("sample_rate", 0)) == 44100 \
		and int(bgm.get("channels", 0)) == 1 \
		and int(bgm.get("vorbis_quality", -1)) == 0 \
		and bool(bgm.get("silence_trim", {}).has("stop_threshold_db")) \
		and source_order == ["Neon_Surge_Loop_1.wav", "Neon_Surge_Loop_1_Alt.wav", "Neon_Surge_Loop_2.wav", "Neon_Surge_Loop_2_Alt.wav"]

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
