extends SceneTree

const EXPORT_PRESETS := "res://export_presets.cfg"
const HANDOFF := "res://docs/packaging_handoff.md"
const VALIDATION_RUNBOOK := "res://docs/validation_runbook.md"
const AGENTS := "res://AGENTS.md"

const REQUIRED_ANDROID_EXPORT_FILES := [
	"res://scenes/main.tscn",
	"res://Resources/Data/Themes/candy_sky_islands/theme_runtime_export.tres",
	"res://Resources/Data/Core/candy_sky_islands_game_core_config.tres",
	"res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres",
	"res://addons/shinokute_game_core/services/input_router.gd",
	"res://addons/shinokute_game_core/controllers/mobile_touch_controls_3d.gd",
	"res://scripts/candy_mobile_touch_controls.gd",
	"res://sounds/candy_sky_islands/bgm_candy_island_main.ogg",
	"res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb",
]

const FORBIDDEN_INCLUDE_PATTERNS := [
	"*.png",
	"*.wav",
	"*.ogg",
	"*.tres",
	"assets/**",
	"Assets/**",
]

func _init() -> void:
	var passed := true
	var presets := _read_text(EXPORT_PRESETS)
	var handoff := _read_text(HANDOFF)
	var runbook := _read_text(VALIDATION_RUNBOOK)
	var agents := _read_text(AGENTS)
	var android_preset := _section_between(presets, "[preset.1]", "[preset.1.options]")
	var android_options := _section_after(presets, "[preset.1.options]")

	passed = _assert_contains(agents, "Candy Sky Islands has Web and Android source handoffs", "AGENTS should state Candy has Web and Android handoffs") and passed
	passed = _assert_contains(agents, "Android Packaging Reset Rule", "AGENTS should point Android packagers to the reset rule") and passed
	passed = _assert_contains(presets, "name=\"Android\"", "Android preset should exist") and passed
	passed = _assert_contains(presets, "platform=\"Android\"", "Android preset should target Android") and passed
	passed = _assert_contains(android_preset, "export_filter=\"resources\"", "Android export should use selected resources") and passed
	passed = _assert_not_contains(android_preset, "export_filter=\"all_resources\"", "Android export must not use all_resources") and passed
	passed = _assert_contains(android_preset, "Export_android/*", "Android export should exclude alternate Android output folders") and passed
	passed = _assert_contains(android_preset, ",android/*", "Android export should exclude Godot custom build workspace") and passed
	passed = _assert_contains(android_preset, "export_path=\"Export/candy_sky_islands.aab\"", "Android export path should be canonical Candy AAB") and passed
	passed = _assert_contains(android_options, "gradle_build/export_format=1", "Android export should produce AAB") and passed
	passed = _assert_contains(android_options, "architectures/arm64-v8a=true", "Android export should include 64-bit ARM") and passed
	passed = _assert_contains(android_options, "architectures/x86=false", "Android export should exclude emulator x86 from release preset") and passed
	passed = _assert_contains(android_options, "version/code=4", "Candy Android version code should reflect the latest Play upload attempt") and passed
	passed = _assert_contains(android_options, "version/name=\"1.0.3\"", "Candy Android version name should reflect the latest Play upload attempt") and passed
	passed = _assert_contains(android_options, "version/target_sdk=35", "Candy Android release must target SDK 35 for current Play upload policy") and passed
	passed = _assert_contains(android_options, "package/unique_name=\"com.shinokutestudio.candyskyislands\"", "Candy Android package id should be explicit") and passed
	passed = _assert_contains(android_options, "package/name=\"Candy Sky Islands\"", "Candy Android package name should be explicit") and passed
	passed = _assert_contains(android_options, "package/signed=true", "Android release preset should be signed") and passed
	passed = _assert_contains(android_options, "graphics/screen_orientation=1", "Android release should lock landscape until owner approves another orientation") and passed
	passed = _assert_contains(android_options, "keystore/release=\"C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands.keystore\"", "Candy release keystore path should be explicit") and passed
	passed = _assert_contains(android_options, "keystore/release_user=\"candy_sky_islands\"", "Candy release key alias should be explicit") and passed
	passed = _assert_contains(handoff, "Android preset name: `Android`", "Packaging handoff should name Android preset") and passed
	passed = _assert_contains(handoff, "Android Packaging Reset Rule", "Packaging handoff should include Android reset rule") and passed
	passed = _assert_contains(handoff, "Source handoff work must not install Java/JDK", "Android handoff should forbid source agents from installing release tooling") and passed
	passed = _assert_contains(handoff, "First compare the existing shipped patterns", "Android handoff should require checking BloxChain/Glyph patterns") and passed
	passed = _assert_contains(handoff, "Package id: `com.shinokutestudio.candyskyislands`", "Packaging handoff should name package id") and passed
	passed = _assert_contains(handoff, "AAB export path: `Export/candy_sky_islands.aab`", "Packaging handoff should name AAB path") and passed
	passed = _assert_contains(handoff, "candy_sky_islands_keystore_secrets.json", "Packaging handoff should name password source without embedding secrets") and passed
	passed = _assert_contains(handoff, "Gate 4C: Android Payload Hygiene", "Packaging handoff should require Android payload hygiene gate") and passed
	passed = _assert_contains(runbook, "Gate 4C: Android Payload Hygiene", "Validation runbook should include Android payload hygiene gate") and passed
	passed = _assert_not_contains(handoff, "Android blocked: no Android preset or signing handoff in source", "Old Android blocker should be removed after source handoff exists") and passed
	for path in REQUIRED_ANDROID_EXPORT_FILES:
		passed = _assert_contains(android_preset, path, "Android selected resources should include %s" % path) and passed
	for pattern in FORBIDDEN_INCLUDE_PATTERNS:
		passed = _assert_not_contains(android_preset, "include_filter=\"%s" % pattern, "Android include_filter must not use broad pattern %s" % pattern) and passed
		passed = _assert_not_contains(android_preset, ",%s" % pattern, "Android include_filter must not use broad pattern %s" % pattern) and passed
	_finish(passed)

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("Missing file: %s" % path)
		return ""
	return FileAccess.get_file_as_string(path)

func _section_between(text: String, start_marker: String, end_marker: String) -> String:
	var start := text.find(start_marker)
	if start == -1:
		return ""
	var end := text.find(end_marker, start)
	if end == -1:
		return text.substr(start)
	return text.substr(start, end - start)

func _section_after(text: String, start_marker: String) -> String:
	var start := text.find(start_marker)
	if start == -1:
		return ""
	return text.substr(start)

func _assert_contains(text: String, needle: String, message: String) -> bool:
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_not_contains(text: String, needle: String, message: String) -> bool:
	if text.contains(needle):
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_android_export_preset_contract: PASS")
		quit(0)
	else:
		print("test_android_export_preset_contract: FAIL")
		quit(1)
