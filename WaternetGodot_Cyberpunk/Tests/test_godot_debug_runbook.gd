extends SceneTree

const RUNBOOK_PATH = "res://docs/godot_working_guide.md"
const LEGACY_RUNBOOK_PATH = "res://docs/godot_debug_runbook.md"

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
		"Godot_v4.3-stable_win64.exe",
		"Godot_v4.3-stable_win64_console.exe",
		"MainWindowHandle",
		"Start-Process",
		"run_project",
		"GDScript Compile Gate",
		"Warning-as-error",
		"Final Response Gate"
	]
	passed = passed and _assert_true(FileAccess.file_exists(RUNBOOK_PATH), "Canonical Godot working guide should exist")
	var text := ""
	if FileAccess.file_exists(RUNBOOK_PATH):
		var file := FileAccess.open(RUNBOOK_PATH, FileAccess.READ)
		text = file.get_as_text() if file != null else ""
	for term in required_terms:
		passed = passed and _assert_true(text.find(term) >= 0, "Godot working guide should mention %s" % term)
	var legacy_text := ""
	if FileAccess.file_exists(LEGACY_RUNBOOK_PATH):
		var legacy_file := FileAccess.open(LEGACY_RUNBOOK_PATH, FileAccess.READ)
		legacy_text = legacy_file.get_as_text() if legacy_file != null else ""
	passed = passed and _assert_true(legacy_text.find("godot_working_guide.md") >= 0, "Legacy debug runbook should point to canonical guide")

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
