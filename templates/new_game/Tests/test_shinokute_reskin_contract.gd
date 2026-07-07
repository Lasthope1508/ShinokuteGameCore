extends SceneTree

const CORE_CONFIG_PATH := "res://Resources/Data/example_game_core_config.tres"
const THEME_CONFIG_PATH := "res://Resources/Data/example_theme_config.tres"
const RULES_PATH := "res://Scripts/ExampleRules.gd"
const SCREENSHOT_CHECKLIST_PATH := "res://docs/screenshot_verification_checklist.md"

var _passed := true

func _init() -> void:
	var core_config = load(CORE_CONFIG_PATH)
	var theme_config = load(THEME_CONFIG_PATH)
	var rules_script = load(RULES_PATH)
	var screenshot_checklist := FileAccess.get_file_as_string(SCREENSHOT_CHECKLIST_PATH)

	_assert_true(core_config != null, "GameCoreConfig should load")
	_assert_true(core_config is GameCoreConfig, "GameCoreConfig should use Shinokute core config class")
	_assert_true(core_config.game_id.strip_edges() != "", "game_id should be filled")
	_assert_true(not core_config.leaderboard_collections.is_empty(), "leaderboard collections should be configured")
	_assert_true(not core_config.scene_routes.is_empty(), "scene routes should be configured")
	_assert_true(not core_config.overlay_scenes.is_empty(), "overlay scenes should be configured")

	_assert_true(theme_config != null, "ShinokuteThemeConfig should load")
	_assert_true(theme_config is ShinokuteThemeConfig, "theme config should use ShinokuteThemeConfig")
	_assert_true(not theme_config.colors.is_empty(), "theme colors should be configured")
	_assert_true(not theme_config.asset_paths.is_empty(), "theme asset paths should be configured")
	_assert_true(theme_config.ui_metrics.has("button_owner_rect"), "theme should define button owner rect")

	_assert_true(rules_script != null, "rules script should load")
	var rules = rules_script.new()
	_assert_true(rules is GameRulesAdapter, "rules should extend GameRulesAdapter")
	_assert_true(rules.has_method("can_make_move"), "rules should expose can_make_move")
	_assert_true(rules.has_method("apply_move"), "rules should expose apply_move")

	_assert_true(screenshot_checklist.contains("All labels fit inside their owner regions"), "All labels fit inside their owner regions evidence should exist")
	_assert_true(screenshot_checklist.contains("Screen still reads as a game screen"), "game-context screenshot evidence should exist")
	_report("test_shinokute_reskin_contract")

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
