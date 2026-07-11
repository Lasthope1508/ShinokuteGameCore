extends SceneTree

const DOC := "res://docs/gameplay_progression_ssot.md"
const AGENTS := "res://AGENTS.md"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(DOC, "progression.level_catalog", "Doctrine should define level catalog SSOT") and passed
	passed = _assert_file_contains(DOC, "progression.completion_condition", "Doctrine should define completion condition") and passed
	passed = _assert_file_contains(DOC, "difficulty.curve", "Doctrine should define difficulty curve") and passed
	passed = _assert_file_contains(DOC, "rules_adapter", "Doctrine should bind gameplay specifics through rules adapter") and passed
	passed = _assert_file_contains(DOC, "3d_obby", "Doctrine should include 3D obby reference profile") and passed
	passed = _assert_file_contains(DOC, "genre_profiles", "Doctrine should generalize to other game genres") and passed
	passed = _assert_file_contains(AGENTS, "docs/gameplay_progression_ssot.md", "AGENTS should require progression doctrine before progression work") and passed
	if passed:
		print("test_gameplay_progression_doctrine: PASS")
		quit(0)
	else:
		print("test_gameplay_progression_doctrine: FAIL")
		quit(1)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
