extends SceneTree

const PROJECT_PATH := "res://project.godot"
const GAME_CORE_MANAGER_PATH := "res://Resources/Globals/GameCoreManager.gd"
const MAIN_MENU_SCRIPT := "res://Scenes/Main/MainMenu.gd"
const LEADERBOARD_POPUP_SCRIPT := "res://Scenes/Common/LeaderboardPopup.gd"
const PROFILE_POPUP_SCRIPT := "res://Scenes/Common/ProfilePopup.gd"
const LEADERBOARD_MANAGER_SCRIPT := "res://Scripts/LeaderboardManager.gd"
const LEADERBOARD_CLIENT_SCRIPT := "res://shared/ShinokuteGameCore/addons/shinokute_game_core/core/leaderboard_client.gd"

func _init() -> void:
	var passed := true
	var project_source := FileAccess.get_file_as_string(PROJECT_PATH)
	var core_source := FileAccess.get_file_as_string(GAME_CORE_MANAGER_PATH)
	var main_menu_source := FileAccess.get_file_as_string(MAIN_MENU_SCRIPT)
	var leaderboard_popup_source := FileAccess.get_file_as_string(LEADERBOARD_POPUP_SCRIPT)
	var profile_popup_source := FileAccess.get_file_as_string(PROFILE_POPUP_SCRIPT)
	var leaderboard_manager_source := FileAccess.get_file_as_string(LEADERBOARD_MANAGER_SCRIPT)
	var leaderboard_client_source := FileAccess.get_file_as_string(LEADERBOARD_CLIENT_SCRIPT)

	passed = passed and _assert_true(project_source.contains("GameCoreManager=\"*res://Resources/Globals/GameCoreManager.gd\""), "project should autoload GameCoreManager")
	passed = passed and _assert_true(core_source.contains("GameCoreScript"), "GameCoreManager should instantiate shared GameCore")
	passed = passed and _assert_true(core_source.contains("glyphflow_game_core_config.tres"), "GameCoreManager should load Glyphflow GameCoreConfig")
	passed = passed and _assert_true(core_source.contains("user://save.cfg"), "GameCoreManager should use existing game save path")
	passed = passed and _assert_true(core_source.contains("ensure_profile_ready"), "GameCoreManager should expose first-launch username readiness")

	passed = passed and _assert_true(main_menu_source.contains("UiModalPresenter"), "MainMenu should use canonical modal presenter")
	passed = passed and _assert_true(main_menu_source.contains("show_leaderboard_modal"), "MainMenu should show leaderboard through the same modal path as settings")
	passed = passed and _assert_true(main_menu_source.contains("GameCoreManager.ensure_profile_ready"), "MainMenu should trigger core username readiness")
	passed = passed and _assert_true(not main_menu_source.contains("add_child(inst)"), "MainMenu should not raw-add leaderboard popup without modal sizing")

	passed = passed and _assert_true(leaderboard_popup_source.contains("/root/GameCoreManager"), "LeaderboardPopup should read leaderboard through GameCoreManager")
	passed = passed and _assert_true(not leaderboard_popup_source.contains("/root/LeaderboardManager"), "LeaderboardPopup should not bind directly to legacy LeaderboardManager")
	passed = passed and _assert_true(profile_popup_source.contains("GameCoreManager.commit_username"), "ProfilePopup should commit username through core")
	passed = passed and _assert_true(not profile_popup_source.contains("SaveManager.set_username"), "ProfilePopup should not save username outside core")

	passed = passed and _assert_true(leaderboard_manager_source.contains("GameCoreManager.submit_score"), "LeaderboardManager should be a compatibility wrapper over GameCoreManager")
	passed = passed and _assert_true(not leaderboard_manager_source.contains("HTTPClient.METHOD_PATCH"), "LeaderboardManager should not own duplicate submit transport")
	passed = passed and _assert_true(not leaderboard_manager_source.contains("HTTPClient.METHOD_POST"), "LeaderboardManager should not own duplicate query transport")
	passed = passed and _assert_true(not leaderboard_client_source.contains("save_store.set_username(username)"), "LeaderboardClient should not auto-create username during submit")

	if passed:
		print("test_game_core_runtime_integration: PASS")
		quit(0)
	else:
		print("test_game_core_runtime_integration: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
