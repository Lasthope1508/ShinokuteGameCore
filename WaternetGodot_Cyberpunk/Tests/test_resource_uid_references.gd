extends SceneTree

const MAIN_THEME_PATH = "res://Resources/Theme/main_theme.tres"
const PROJECT_PATH = "res://project.godot"
const SCENE_PATHS := [
	"res://Scenes/Gameplay/GameScene.tscn",
	"res://Scenes/Main/MainMenu.tscn",
	"res://Scenes/Main/LevelSelect.tscn",
	"res://Scenes/Common/ProfilePopup.tscn",
	"res://Scenes/Common/Splash.tscn"
]

func _init() -> void:
	var passed := true
	var expected_uid := _read_resource_uid(MAIN_THEME_PATH)
	passed = passed and _assert_true(expected_uid != "", "Main theme should declare a resource uid")
	for scene_path in SCENE_PATHS:
		var text := _read_text(scene_path)
		var uid := _read_main_theme_ext_uid(text)
		passed = passed and _assert_equal(uid, expected_uid, "%s should reference current main theme uid" % scene_path)
	var project_text := _read_text(PROJECT_PATH)
	passed = passed and _assert_true(project_text.find("buses/default_bus_layout=\"uid://") < 0, "Project audio bus layout should not reference an untracked uid")

	if passed:
		print("test_resource_uid_references: PASS")
		quit(0)
	else:
		print("test_resource_uid_references: FAIL")
		quit(1)

func _read_main_theme_ext_uid(text: String) -> String:
	for line in text.split("\n"):
		if line.find("res://Resources/Theme/main_theme.tres") >= 0 and line.find("uid=\"") >= 0:
			return _extract_uid(line)
	return ""

func _read_resource_uid(path: String) -> String:
	var text := _read_text(path)
	for line in text.split("\n"):
		if line.find("uid=\"") >= 0:
			return _extract_uid(line)
	return ""

func _extract_uid(line: String) -> String:
	var marker := "uid=\""
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
