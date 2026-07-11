extends SceneTree

const APPLIER := "res://scripts/theme_applier.gd"
const MAIN_SCRIPT := "res://scripts/main.gd"
const MAIN_SCENE := "res://scenes/main.tscn"

func _init() -> void:
	var passed := true
	passed = passed and _assert_file_contains(APPLIER, "func apply_theme", "Theme applier should expose apply_theme")
	passed = passed and _assert_file_contains(APPLIER, "hud_text_owner_rect", "Theme applier should use HUD owner rect")
	passed = passed and _assert_file_contains(APPLIER, "func _apply_player_materials", "Theme applier should apply player materials")
	passed = passed and _assert_file_contains(APPLIER, "player_body_material_color", "Theme applier should use player body material token")
	passed = passed and _assert_file_contains(APPLIER, "player_root_asset_path", "Theme applier should keep root asset reference in contract")
	passed = passed and _assert_file_contains(APPLIER, "collectible_star_body_color", "Theme applier should use collectible star body token")
	passed = passed and _assert_file_contains(APPLIER, "platform_top_material_color", "Theme applier should use platform top token")
	passed = passed and _assert_file_contains(APPLIER, "platform_edge_material_color", "Theme applier should use platform edge token")
	passed = passed and _assert_file_contains(APPLIER, "obstacle_wafer_material_color", "Theme applier should use obstacle wafer token")
	passed = passed and _assert_file_contains(APPLIER, "goal_pennant_material_color", "Theme applier should use goal pennant token")
	passed = passed and _assert_file_contains(MAIN_SCRIPT, "theme_config", "Main script should expose theme config")
	passed = passed and _assert_file_not_contains(MAIN_SCRIPT, "RenderingServer.get_current_rendering_method", "Main script should avoid Godot 4.6-only renderer API")
	passed = passed and _assert_file_contains(MAIN_SCENE, "candy_sky_islands/theme_runtime_export.tres", "Main scene should reference sanitized Candy runtime theme")
	passed = passed and _assert_file_not_contains(MAIN_SCENE, "models/candy_sky_islands", "Main scene should not introduce unapproved GLB replacement")
	if passed:
		print("test_theme_applier_contract: PASS")
		quit(0)
	else:
		print("test_theme_applier_contract: FAIL")
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

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains(needle):
		push_error("%s: found '%s'" % [message, needle])
		return false
	return true
