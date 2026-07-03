extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const ThemeConfigScript = preload("res://Resources/Classes/ThemeConfig.gd")
const GameSceneScript = preload("res://Scenes/Gameplay/GameScene.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)

	passed = passed and _assert_true(theme.has_method("get_required_asset_keys"), "Theme should expose canonical required asset keys")
	passed = passed and _assert_true(theme.has_method("validate_geometry_manifest"), "Theme should validate skin geometry before scene draw")

	if theme.has_method("get_required_asset_keys"):
		passed = passed and _assert_equal(theme.get_required_asset_keys(), ["cell", "source", "target", "cap", "I", "L", "T", "X"], "Required asset keys should be canonical and ordered")

	if theme.has_method("validate_geometry_manifest"):
		var errors: Array = theme.validate_geometry_manifest()
		passed = passed and _assert_equal(errors.size(), 0, "Cyber skin geometry manifest should validate cleanly")
		var broken_theme = ThemeConfigScript.new()
		broken_theme.cell_geometry = theme.cell_geometry
		broken_theme.source_geometry = theme.source_geometry
		errors = broken_theme.validate_geometry_manifest()
		passed = passed and _assert_true(errors.size() > 0, "Missing geometry should fail before a skin reaches GameScene")
		passed = passed and _assert_true(_errors_include(errors, "target"), "Validation errors should name missing target geometry")

	var scene = GameSceneScript.new()
	scene.grid = PipeGridScript.new()
	scene.grid.initialize({
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, false, true]},
		"grid": [
			{"type": "I", "ports": [false, true, false, false], "rotation": 90},
			{"type": "I", "ports": [false, true, false, true], "rotation": 90},
			{"type": "I", "ports": [false, false, false, true], "rotation": 270}
		]
	})
	scene.solver = ConnectionSolverScript.new()

	var source_info: Dictionary = scene._get_tile_texture_and_rotation(0, 0, theme)
	var pipe_info: Dictionary = scene._get_tile_texture_and_rotation(1, 0, theme)
	var target_info: Dictionary = scene._get_tile_texture_and_rotation(2, 0, theme)
	passed = passed and _assert_equal(source_info.get("geometry", null), theme.get_asset_geometry("source"), "GameScene should read source geometry through theme lookup")
	passed = passed and _assert_equal(pipe_info.get("geometry", null), theme.get_asset_geometry("I"), "GameScene should read pipe geometry through theme lookup")
	passed = passed and _assert_equal(target_info.get("geometry", null), theme.get_asset_geometry("target"), "GameScene should read target geometry through theme lookup")
	scene.free()

	if passed:
		print("test_skin_geometry_pipeline_contract: PASS")
		quit(0)
	else:
		print("test_skin_geometry_pipeline_contract: FAIL")
		quit(1)

func _errors_include(errors: Array, needle: String) -> bool:
	for error in errors:
		if String(error).find(needle) >= 0:
			return true
	return false

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
