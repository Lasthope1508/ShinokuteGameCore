extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const EXPECTED_PATHS := {
	"dark": "res://Assets/Themes/cyberpunk_theme/cell_tiles/dark_floorplate_b.png",
	"light": "res://Assets/Themes/cyberpunk_theme/cell_tiles/light_floorplate_a.png"
}

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(_has_property(theme, "ui_cell_texture_paths"), "Theme should own mode-specific gameplay cell texture paths")
	passed = passed and _assert_true(_has_property(theme, "ui_cell_texture_strict_mode_paths"), "Theme should own strict gameplay cell texture mode toggle")
	passed = passed and _assert_true(theme.has_method("get_cell_bg_texture_path"), "Theme should expose gameplay cell texture path helper")
	passed = passed and _assert_true(theme.has_method("get_cell_bg_texture_for_mode"), "Theme should expose gameplay cell texture helper")

	if theme != null and _has_property(theme, "ui_cell_texture_paths"):
		var paths: Dictionary = theme.get("ui_cell_texture_paths")
		passed = passed and _assert_true(bool(theme.get("ui_cell_texture_strict_mode_paths")), "Cyber gameplay cell textures should be strict; no fallback mode")
		passed = passed and _assert_true(not paths.has("default"), "Cyber gameplay cell textures should not define a default fallback")
		for mode in EXPECTED_PATHS.keys():
			passed = passed and _assert_true(paths.has(mode), "Cell texture paths should include %s mode" % mode)
			if paths.has(mode):
				var expected_path := String(EXPECTED_PATHS[mode])
				var actual_path := String(paths[mode])
				passed = passed and _assert_equal(actual_path, expected_path, "%s cell texture path should use owner-approved candidate" % mode)
				passed = passed and _assert_true(FileAccess.file_exists(actual_path), "%s cell texture should exist at %s" % [mode, actual_path])
				passed = passed and _assert_equal(theme.get_cell_bg_texture_path(mode), expected_path, "%s helper should return owner-approved cell path" % mode)
				passed = passed and _assert_true(theme.get_cell_bg_texture_for_mode(mode) != null, "%s helper should load a texture" % mode)
		passed = passed and _assert_equal(theme.get_cell_bg_texture_path("missing_mode"), "", "Strict helper should not invent a fallback path")
		passed = passed and _assert_true(theme.get_cell_bg_texture_for_mode("missing_mode") == null, "Strict helper should not fall back to legacy cell texture")

	if passed:
		print("test_gameplay_cell_texture_ssot: PASS")
		quit(0)
	else:
		print("test_gameplay_cell_texture_ssot: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
