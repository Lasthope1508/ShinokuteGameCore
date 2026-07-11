extends SceneTree

const THEME_SCRIPT := "res://Resources/QuantumThemeConfig.gd"
const THEME_CONFIG := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const CORE_CONFIG := "res://Resources/Data/Core/candy_sky_islands_game_core_config.tres"
const MAIN_SCENE := "res://scenes/main.tscn"
const ASSET_MANIFEST := "res://docs/asset_manifest.md"
const USERNAME_SCENE := "res://scenes/ui/candy_username_prompt_overlay.tscn"

const REQUIRED_UI_KEYS := [
	"ui.leaderboard.button",
	"ui.leaderboard.panel",
	"ui.leaderboard.row",
	"ui.leaderboard.tab",
	"ui.leaderboard.close",
	"ui.username.panel",
	"ui.username.input",
	"ui.button.primary",
	"ui.button.secondary"
]

const REQUIRED_THEME_FIELDS := [
	"ui_leaderboard_button_path",
	"ui_leaderboard_panel_path",
	"ui_leaderboard_row_path",
	"ui_leaderboard_tab_path",
	"ui_leaderboard_close_path",
	"ui_username_panel_path",
	"ui_username_input_path",
	"ui_button_primary_path",
	"ui_button_secondary_path"
]

func _init() -> void:
	var passed := true
	var theme_script := FileAccess.get_file_as_string(THEME_SCRIPT)
	var theme_config := FileAccess.get_file_as_string(THEME_CONFIG)
	var core_config := FileAccess.get_file_as_string(CORE_CONFIG)
	var main_scene := FileAccess.get_file_as_string(MAIN_SCENE)
	var manifest := FileAccess.get_file_as_string(ASSET_MANIFEST)

	for field in REQUIRED_THEME_FIELDS:
		passed = _assert_true(theme_script.contains(field), "QuantumThemeConfig should expose %s" % field) and passed
		passed = _assert_true(theme_config.contains(field + " = \"res://assets/themes/candy_sky_islands/ui/"), "Candy theme config should set %s to a Candy UI asset" % field) and passed

	for key in REQUIRED_UI_KEYS:
		passed = _assert_true(manifest.contains("| %s |" % key), "Asset manifest should record %s" % key) and passed

	passed = _assert_true(ResourceLoader.exists(USERNAME_SCENE), "Candy should own a username prompt scene") and passed
	passed = _assert_true(core_config.contains("\"username\": \"res://scenes/ui/candy_username_prompt_overlay.tscn\""), "GameCoreConfig username overlay should point to Candy UI scene") and passed
	passed = _assert_true(main_scene.contains("res://scenes/ui/candy_username_prompt_overlay.tscn"), "Main scene should preload Candy username prompt") and passed
	passed = _assert_true(not main_scene.contains("res://addons/shinokute_game_core/ui/username_prompt_overlay.tscn"), "Main scene should not use core demo username prompt as production UI") and passed
	passed = _assert_true(main_scene.contains("ui_leaderboard_panel.png"), "Leaderboard panel should use generated Candy UI art") and passed
	passed = _assert_true(main_scene.contains("ui_leaderboard_button.png"), "Leaderboard button should use generated Candy UI art") and passed
	passed = _assert_true(main_scene.contains("ui_leaderboard_row.png"), "Leaderboard rows should use generated Candy UI art") and passed

	if passed:
		print("test_candy_function_skin_ui_assets_contract: PASS")
		quit(0)
	else:
		print("test_candy_function_skin_ui_assets_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
