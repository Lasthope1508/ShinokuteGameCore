extends SceneTree

const EXPORT_PRESETS := "res://export_presets.cfg"
const PROJECT_CONFIG := "res://project.godot"
const MAIN_ENVIRONMENT := "res://scenes/main-environment.tres"

const REQUIRED_EXPORT_FILES := [
	"res://scenes/main.tscn",
	"res://scenes/ui/candy_username_prompt_overlay.tscn",
	"res://Resources/QuantumRuntimeThemeConfig.gd",
	"res://Resources/Data/Themes/candy_sky_islands/theme_runtime_export.tres",
	"res://Resources/Data/Core/candy_sky_islands_game_core_config.tres",
	"res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres",
	"res://addons/shinokute_game_core/core/progression_catalog.gd",
	"res://addons/shinokute_game_core/core/progression_level.gd",
	"res://scripts/theme_applier.gd",
	"res://scripts/obby_route_generator.gd",
	"res://scripts/candy_mobile_touch_controls.gd",
	"res://addons/shinokute_game_core/controllers/character_3d_controller.gd",
	"res://addons/shinokute_game_core/controllers/follow_camera_3d.gd",
	"res://addons/shinokute_game_core/controllers/mobile_touch_controls_3d.gd",
	"res://addons/shinokute_game_core/services/input_router.gd",
	"res://addons/shinokute_game_core/ui/function_overlay_group.gd",
	"res://assets/themes/candy_sky_islands/ui/ui_leaderboard_button.png",
	"res://assets/themes/candy_sky_islands/ui/ui_leaderboard_panel.png",
	"res://assets/themes/candy_sky_islands/ui/ui_leaderboard_row.png",
	"res://assets/themes/candy_sky_islands/ui/ui_leaderboard_tab.png",
	"res://assets/themes/candy_sky_islands/ui/ui_leaderboard_close.png",
	"res://assets/themes/candy_sky_islands/ui/ui_username_panel.png",
	"res://assets/themes/candy_sky_islands/ui/ui_username_input.png",
	"res://assets/themes/candy_sky_islands/ui/ui_button_primary.png",
	"res://assets/themes/candy_sky_islands/ui/ui_button_secondary.png",
	"res://sounds/candy_sky_islands/bgm_candy_island_main.ogg",
	"res://sounds/candy_sky_islands/sfx_jump.ogg",
	"res://sounds/candy_sky_islands/sfx_land.ogg",
	"res://sounds/candy_sky_islands/sfx_coin.ogg",
	"res://sounds/candy_sky_islands/sfx_walking.ogg",
	"res://sounds/candy_sky_islands/sfx_break.ogg",
	"res://sounds/candy_sky_islands/sfx_fall.ogg",
]

const FORBIDDEN_EXPORT_FILES := [
	"res://Resources/QuantumThemeConfig.gd",
	"res://Resources/QuantumAssetRole.gd",
	"res://Resources/GameProgressionConfig.gd",
	"res://Resources/GameLevelDefinition.gd",
	"res://Resources/Data/Themes/candy_sky_islands/theme_config.tres",
	"res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands_raw.png",
	"res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands_raw.png",
	"res://meshes/dust.res",
	"res://meshes/brick.res",
	"res://models/Textures/colormap.png",
]

const RUNTIME_THEME := "res://Resources/Data/Themes/candy_sky_islands/theme_runtime_export.tres"
const MAIN_SCENE := "res://scenes/main.tscn"
const USERNAME_SCENE := "res://scenes/ui/candy_username_prompt_overlay.tscn"
const CORE_CONFIG := "res://Resources/Data/Core/candy_sky_islands_game_core_config.tres"
const FORBIDDEN_RUNTIME_MARKERS := ["docs/", "debug/", "source/", "_raw.png", "candidate"]

const FORBIDDEN_INCLUDE_PATTERNS := [
	"*.png",
	"*.wav",
	"*.ogg",
	"*.tres",
	"assets/**",
	"Assets/**",
]

const AUTHORING_GDIGNORE_DIRS := [
	"res://docs",
	"res://debug",
	"res://output",
	"res://tools",
	"res://Export",
	"res://models",
	"res://meshes",
	"res://assets/themes/candy_sky_islands/source",
	"res://assets/themes/candy_sky_islands/source/branding_raw",
	"res://assets/themes/candy_sky_islands/source/model_candidates",
]

const FORBIDDEN_RUNTIME_FILES := [
	"res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands_raw.png",
	"res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands_raw.png",
	"res://assets/themes/candy_sky_islands/models/character_candy_marshmallow.glb",
	"res://assets/themes/candy_sky_islands/models/character_shinokute_human.glb",
	"res://assets/themes/candy_sky_islands/models/character_shinokute_human_shinokute_idle_sign_pose_clean_ref.png",
	"res://assets/themes/candy_sky_islands/models/cloud_candy.glb",
]

const ACTIVE_GLB_IMPORTS := [
	"res://assets/themes/candy_sky_islands/models/brick_candy_wafer.glb.import",
	"res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb.import",
	"res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb.import",
	"res://assets/themes/candy_sky_islands/models/goal_candy_pennant.glb.import",
	"res://assets/themes/candy_sky_islands/models/grass_candy.glb.import",
	"res://assets/themes/candy_sky_islands/models/grass_candy_small.glb.import",
	"res://assets/themes/candy_sky_islands/models/platform_candy_falling.glb.import",
	"res://assets/themes/candy_sky_islands/models/platform_candy_medium.glb.import",
	"res://assets/themes/candy_sky_islands/models/platform_candy_round_large.glb.import",
	"res://assets/themes/candy_sky_islands/models/platform_candy_small.glb.import",
	"res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb.import",
]

func _init() -> void:
	var passed := true
	if not FileAccess.file_exists(EXPORT_PRESETS):
		push_error("Web export preset should exist before HTML5 test export")
		_finish(false)
		return
	var text := FileAccess.get_file_as_string(EXPORT_PRESETS)
	var project_config := FileAccess.get_file_as_string(PROJECT_CONFIG)
	var environment_config := FileAccess.get_file_as_string(MAIN_ENVIRONMENT)
	var runtime_theme := FileAccess.get_file_as_string(RUNTIME_THEME)
	var main_scene := FileAccess.get_file_as_string(MAIN_SCENE)
	var username_scene := FileAccess.get_file_as_string(USERNAME_SCENE)
	var core_config := FileAccess.get_file_as_string(CORE_CONFIG)
	passed = _assert_contains(text, "name=\"Web\"", "Web export preset should be named Web") and passed
	passed = _assert_contains(text, "platform=\"Web\"", "Web export preset should target Web") and passed
	passed = _assert_contains(project_config, "renderer/rendering_method=\"gl_compatibility\"", "HTML5 export should use Godot Compatibility renderer") and passed
	passed = _assert_contains(project_config, "renderer/rendering_method.mobile=\"gl_compatibility\"", "HTML5/mobile export should use Godot Compatibility renderer") and passed
	passed = _assert_contains(text, "viewport-fit=cover", "Web export head include should opt into iOS safe-area/mobile viewport sizing") and passed
	passed = _assert_contains(text, "100dvh", "Web export head include should size the canvas to dynamic viewport height on iOS rotation") and passed
	passed = _assert_contains(text, "visualViewport", "Web export head include should listen for visualViewport resize on iOS Safari") and passed
	passed = _assert_contains(text, "orientationchange", "Web export head include should listen for orientation changes") and passed
	passed = _assert_contains(text, "touch-action:none", "Web export head include should prevent browser gestures from stealing game controls") and passed
	passed = _assert_not_contains(environment_config, "ssao_enabled = true", "HTML5 Compatibility export should not enable SSAO") and passed
	passed = _assert_contains(text, "export_filter=\"resources\"", "Web export should use selected resources, not all_resources") and passed
	passed = _assert_not_contains(text, "export_filter=\"all_resources\"", "Web export must not use all_resources") and passed
	for pattern in FORBIDDEN_INCLUDE_PATTERNS:
		passed = _assert_not_contains(text, "include_filter=\"%s" % pattern, "Web export include_filter must not use broad pattern %s" % pattern) and passed
		passed = _assert_not_contains(text, ",%s" % pattern, "Web export include_filter must not use broad pattern %s" % pattern) and passed
	for path in AUTHORING_GDIGNORE_DIRS:
		passed = _assert_true(FileAccess.file_exists("%s/.gdignore" % path), "Authoring/build dir should be hidden from Godot import: %s" % path) and passed
	for path in FORBIDDEN_RUNTIME_FILES:
		passed = _assert_true(not FileAccess.file_exists(path), "Authoring-only or rejected asset should live under ignored source, not runtime folders: %s" % path) and passed
	for path in ACTIVE_GLB_IMPORTS:
		passed = _assert_file_contains(path, "meshes/generate_lods=false", "Candy runtime GLB import should disable LOD generation to avoid non-finite-normal LOD warnings: %s" % path) and passed
	for path in REQUIRED_EXPORT_FILES:
		passed = _assert_contains(text, path, "Web export selected resources should include %s" % path) and passed
	for path in FORBIDDEN_EXPORT_FILES:
		passed = _assert_not_contains(text, path, "Web export selected resources should not include authoring-only %s" % path) and passed
	for marker in FORBIDDEN_RUNTIME_MARKERS:
		passed = _assert_not_contains(runtime_theme, marker, "Runtime theme should not carry publish-forbidden marker %s" % marker) and passed
	passed = _assert_contains(main_scene, "theme_runtime_export.tres", "Main scene should use sanitized runtime theme") and passed
	passed = _assert_contains(username_scene, "theme_runtime_export.tres", "Username scene should use sanitized runtime theme") and passed
	passed = _assert_contains(core_config, "theme_runtime_export.tres", "Game core config should use sanitized runtime theme") and passed
	_finish(passed)

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

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	return _assert_contains(text, needle, message)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_web_export_preset_contract: PASS")
		quit(0)
	else:
		print("test_web_export_preset_contract: FAIL")
		quit(1)
