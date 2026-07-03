extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const MANIFEST_PATH = "res://docs/ui_cyber_component_generation_manifest.json"
const EXPECTED_CUTOUT_COUNT := 30
const RUNTIME_OBJECT_KEYS := [
	"top_tray_layer",
	"logo_socket",
	"stats_capsule",
	"floating_menu_button_default",
	"floating_replay_button_default",
	"bottom_reserve_layer",
	"bottom_tray_layer",
	"modal_frame",
	"board_backplate"
]

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)

	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(not manifest_text.is_empty(), "PhotoRoom canonical manifest should exist")
	passed = passed and _assert_true(manifest_text.contains("photoroom_edge_qa_preview_r2"), "Manifest should record PhotoRoom QA preview R2 URL")
	passed = passed and _assert_true(not FileAccess.file_exists("res://debug/photoroom_cutout_edge_qa_preview.png"), "PhotoRoom QA preview should not be required as a local production debug file")

	if theme != null and _has_property(theme, "ui_generated_asset_paths"):
		var paths: Dictionary = theme.get("ui_generated_asset_paths")
		for mode in ["dark", "light"]:
			var mode_paths: Dictionary = paths.get(mode, {})
			for key in RUNTIME_OBJECT_KEYS:
				passed = passed and _assert_true(mode_paths.has(key), "%s should define runtime object %s" % [mode, key])
				if mode_paths.has(key):
					var path := String(mode_paths[key])
					passed = passed and _assert_true(path.ends_with("_photoroom.png"), "%s %s should use PhotoRoom cutout path" % [mode, key])
					passed = passed and _assert_true(not path.ends_with("_alpha.png"), "%s %s should not use chroma-key preview path" % [mode, key])
					passed = passed and _assert_true(FileAccess.file_exists(path), "%s %s PhotoRoom cutout should exist" % [mode, key])

	var manifest_variant: Variant = JSON.parse_string(manifest_text)
	passed = passed and _assert_true(manifest_variant is Dictionary, "Manifest JSON should parse as Dictionary")
	if manifest_variant is Dictionary:
		var manifest: Dictionary = manifest_variant as Dictionary
		var cutout_count := 0
		for item_variant in Array(manifest.get("items", [])):
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant as Dictionary
			var mode := String(item.get("mode", ""))
			var key := String(item.get("component_key", ""))
			if mode not in ["dark", "light"] or key.begins_with("background_full"):
				continue
			cutout_count += 1
			passed = passed and _assert_equal(String(item.get("background_removal_method", "")), "photoroom", "%s %s should record PhotoRoom background removal" % [mode, key])
			passed = passed and _assert_equal(String(item.get("production_background_removal_method", "")), "photoroom", "%s %s should record PhotoRoom production removal" % [mode, key])
			passed = passed and _assert_equal(String(item.get("edge_qa_status", "")), "approved_dark_light_checkerboard", "%s %s should pass edge QA" % [mode, key])
			passed = passed and _assert_true(String(item.get("production_res_path", "")).ends_with("_photoroom.png"), "%s %s should record production res path" % [mode, key])
			passed = passed and _assert_true(String(item.get("production_r2_url", "")).ends_with("_photoroom.png"), "%s %s should record production R2 URL" % [mode, key])
			var production_path := String(item.get("production_res_path", ""))
			if RUNTIME_OBJECT_KEYS.has(key):
				passed = passed and _assert_true(FileAccess.file_exists(production_path), "%s %s production res path should exist" % [mode, key])
			else:
				passed = passed and _assert_true(not FileAccess.file_exists(production_path), "%s %s non-runtime cutout should not remain in production import tree" % [mode, key])
				passed = passed and _assert_true(FileAccess.file_exists(_archived_production_path(production_path)), "%s %s non-runtime cutout should exist in source archive" % [mode, key])
			var alpha_extrema: Array = item.get("alpha_extrema", [])
			passed = passed and _assert_true(alpha_extrema.size() == 2, "%s %s alpha extrema should have two values" % [mode, key])
			if alpha_extrema.size() == 2:
				passed = passed and _assert_equal(int(alpha_extrema[0]), 0, "%s %s alpha minimum should be transparent" % [mode, key])
				passed = passed and _assert_equal(int(alpha_extrema[1]), 255, "%s %s alpha maximum should be opaque" % [mode, key])
		passed = passed and _assert_equal(cutout_count, EXPECTED_CUTOUT_COUNT, "Manifest should record every PhotoRoom cutout")
		passed = passed and _assert_true(String(manifest.get("photoroom_edge_qa_preview_r2", "")).begins_with("https://"), "Manifest should keep remote PhotoRoom QA preview evidence")

	if passed:
		print("test_ui_photoroom_cutout_contract: PASS")
		quit(0)
	else:
		print("test_ui_photoroom_cutout_contract: FAIL")
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

func _archived_production_path(path: String) -> String:
	return path.replace("res://", "res://Assets/UI/cyberpunk_theme/source_archive/")
