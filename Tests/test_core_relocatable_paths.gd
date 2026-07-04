extends SceneTree

const GAME_CORE_PATH := "res://addons/shinokute_game_core/core/game_core.gd"

var _passed := true

func _init() -> void:
	var source := FileAccess.get_file_as_string(GAME_CORE_PATH)
	_assert_true(not source.is_empty(), "GameCore source should exist")
	_assert_true(not source.contains("res://addons/shinokute_game_core/core"), "GameCore should use relative core preloads so submodule location can vary")
	_assert_true(source.contains('preload("local_save_store.gd")'), "GameCore should preload LocalSaveStore by relative path")
	_assert_true(source.contains('preload("player_profile.gd")'), "GameCore should preload PlayerProfile by relative path")
	_assert_true(source.contains('preload("leaderboard_client.gd")'), "GameCore should preload LeaderboardClient by relative path")
	_assert_true(source.contains('preload("geo_service.gd")'), "GameCore should preload GeoService by relative path")
	_report("test_core_relocatable_paths")

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
