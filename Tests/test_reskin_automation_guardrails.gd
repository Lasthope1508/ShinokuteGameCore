extends SceneTree

const AUDIT_PATH := "res://tools/reskin_audit.ps1"
const TEMPLATE_README_PATH := "res://templates/new_game/README.md"
const TEMPLATE_CORE_CONFIG_PATH := "res://templates/new_game/Resources/Data/game_core_config.tres.template"
const TEMPLATE_THEME_CONFIG_PATH := "res://templates/new_game/Resources/Data/theme_config.tres.template"
const TEMPLATE_RULES_PATH := "res://templates/new_game/Scripts/ExampleRules.gd"
const TEMPLATE_CONTRACT_TEST_PATH := "res://templates/new_game/Tests/test_shinokute_reskin_contract.gd"
const TEMPLATE_SCREENSHOT_CHECKLIST_PATH := "res://templates/new_game/docs/screenshot_verification_checklist.md"
const AGENTS_PATH := "res://AGENTS.md"
const RUNBOOK_PATH := "res://docs/reskin_runbook.md"
const CHECKLIST_TEMPLATE_PATH := "res://docs/reskin_checklist_template.md"
const README_PATH := "res://README.md"

var _passed := true

func _init() -> void:
	var audit := FileAccess.get_file_as_string(AUDIT_PATH)
	var template_readme := FileAccess.get_file_as_string(TEMPLATE_README_PATH)
	var core_config := FileAccess.get_file_as_string(TEMPLATE_CORE_CONFIG_PATH)
	var theme_config := FileAccess.get_file_as_string(TEMPLATE_THEME_CONFIG_PATH)
	var rules := FileAccess.get_file_as_string(TEMPLATE_RULES_PATH)
	var contract_test := FileAccess.get_file_as_string(TEMPLATE_CONTRACT_TEST_PATH)
	var screenshot_checklist := FileAccess.get_file_as_string(TEMPLATE_SCREENSHOT_CHECKLIST_PATH)
	var agents := FileAccess.get_file_as_string(AGENTS_PATH)
	var runbook := FileAccess.get_file_as_string(RUNBOOK_PATH)
	var checklist := FileAccess.get_file_as_string(CHECKLIST_TEMPLATE_PATH)
	var readme := FileAccess.get_file_as_string(README_PATH)

	_assert_true(not audit.is_empty(), "reskin audit tool should exist")
	_assert_true(audit.contains("param("), "audit tool should be a runnable PowerShell script")
	_assert_true(audit.contains("GameCoreConfig"), "audit should check GameCoreConfig")
	_assert_true(audit.contains("ShinokuteThemeConfig"), "audit should check ShinokuteThemeConfig")
	_assert_true(audit.contains("GameRulesAdapter"), "audit should check rules adapter")
	_assert_true(audit.contains("HardcodedValueAudit"), "audit should include hardcoded value scan")
	_assert_true(audit.contains("TextFitEvidence"), "audit should require text-fit evidence")
	_assert_true(audit.contains("ScreenshotEvidence"), "audit should require screenshot evidence")
	_assert_true(audit.contains("FailOnWarnings"), "audit should support warning-as-failure mode")

	_assert_true(template_readme.contains("New Game Reskin Template"), "new game template readme should exist")
	_assert_true(core_config.contains("[resource]"), "core config template should be a Godot resource template")
	_assert_true(core_config.contains("game_id"), "core config template should include game id")
	_assert_true(theme_config.contains("colors"), "theme config template should include colors")
	_assert_true(theme_config.contains("asset_paths"), "theme config template should include asset paths")
	_assert_true(rules.contains("extends GameRulesAdapter"), "rules template should extend GameRulesAdapter")
	_assert_true(rules.contains("func can_make_move"), "rules template should define can_make_move")
	_assert_true(contract_test.contains("GameCoreConfig"), "contract test template should validate core config")
	_assert_true(contract_test.contains("ShinokuteThemeConfig"), "contract test template should validate theme config")
	_assert_true(contract_test.contains("All labels fit inside their owner regions"), "contract test should mention text fit evidence")
	_assert_true(screenshot_checklist.contains("Desktop viewport"), "screenshot checklist should include desktop viewport")
	_assert_true(screenshot_checklist.contains("Mobile viewport"), "screenshot checklist should include mobile viewport")
	_assert_true(screenshot_checklist.contains("Screen still reads as a game screen"), "screenshot checklist should guard game context")

	_assert_true(agents.contains("tools/reskin_audit.ps1"), "agents guide should require audit tool")
	_assert_true(agents.contains("templates/new_game"), "agents guide should link new game template")
	_assert_true(runbook.contains("tools/reskin_audit.ps1"), "runbook should require audit tool")
	_assert_true(runbook.contains("HardcodedValueAudit"), "runbook should name hardcoded value audit")
	_assert_true(checklist.contains("Reskin audit command"), "checklist should require audit command evidence")
	_assert_true(checklist.contains("Screenshot verification checklist"), "checklist should require screenshot checklist evidence")
	_assert_true(readme.contains("tools/reskin_audit.ps1"), "README should link reskin audit tool")
	_assert_true(readme.contains("templates/new_game"), "README should link new game template")
	_report("test_reskin_automation_guardrails")

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
