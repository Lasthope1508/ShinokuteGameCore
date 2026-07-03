extends SceneTree

const RUNBOOK_PATH = "res://docs/godot_debug_runbook.md"

func _init() -> void:
	var passed := true
	var required_terms := [
		"Godot Debug Runbook",
		"GoPeak",
		"run-project",
		"--headless",
		"visible debug",
		"9090",
		"7777",
		"GameScene.tscn",
		"Godot_v4.3-stable_win64_console.exe"
	]
	passed = passed and _assert_true(FileAccess.file_exists(RUNBOOK_PATH), "Godot debug runbook should exist")
	var text := ""
	if FileAccess.file_exists(RUNBOOK_PATH):
		var file := FileAccess.open(RUNBOOK_PATH, FileAccess.READ)
		text = file.get_as_text() if file != null else ""
	for term in required_terms:
		passed = passed and _assert_true(text.find(term) >= 0, "Runbook should mention %s" % term)

	if passed:
		print("test_godot_debug_runbook: PASS")
		quit(0)
	else:
		print("test_godot_debug_runbook: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
