extends SceneTree

const DOC_PATH := "res://docs/reskin_core_skin_boundary.md"
const README_PATH := "res://README.md"
const ADDON_README_PATH := "res://addons/shinokute_game_core/README.md"

var _passed := true

func _init() -> void:
	var doctrine := FileAccess.get_file_as_string(DOC_PATH)
	var readme := FileAccess.get_file_as_string(README_PATH)
	var addon_readme := FileAccess.get_file_as_string(ADDON_README_PATH)

	_assert_true(not doctrine.is_empty(), "reskin doctrine doc should exist")
	_assert_true(doctrine.contains("MUST READ BEFORE RESKIN"), "doctrine should be mandatory")
	_assert_true(doctrine.contains("Core = behavior"), "doctrine should define core boundary")
	_assert_true(doctrine.contains("Game skin ="), "doctrine should define game skin boundary")
	_assert_true(doctrine.contains("Function skin ="), "doctrine should define function skin boundary")
	_assert_true(doctrine.contains("No fallback"), "doctrine should preserve no-fallback rule")
	_assert_true(readme.contains("reskin_core_skin_boundary.md"), "root README should link doctrine")
	_assert_true(addon_readme.contains("reskin_core_skin_boundary.md"), "addon README should link doctrine")
	_report("test_reskin_boundary_doctrine")

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
