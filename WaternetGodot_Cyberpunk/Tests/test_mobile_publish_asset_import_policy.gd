extends SceneTree

const BUDGET_PATH := "res://Resources/Data/AssetBudgets/cyberpunk_asset_budget.tres"
const HEAVY_TEXTURE_IMPORTS := [
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/background_full_landscape.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/background_full_portrait.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/board_backplate_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/bottom_tray_layer_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/floating_menu_button_default_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/floating_replay_button_default_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/logo_socket_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/modal_frame_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/stats_capsule_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/dark/top_tray_layer_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/background_full_landscape.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/background_full_portrait.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/board_backplate_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/bottom_tray_layer_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/floating_menu_button_default_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/floating_replay_button_default_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/logo_socket_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/modal_frame_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/stats_capsule_photoroom.png.import",
	"res://Assets/UI/cyberpunk_theme/generated/production/light/top_tray_layer_photoroom.png.import",
	"res://Assets/Themes/cyberpunk_theme/cell_tiles/dark_floorplate_b.png.import",
	"res://Assets/Themes/cyberpunk_theme/cell_tiles/light_floorplate_a.png.import",
	"res://Assets/VFX/lightning_boltarc_01_spritesheet.png.import"
]

func _init() -> void:
	var passed := true
	var budget: Resource = load(BUDGET_PATH)
	passed = passed and _assert_true(budget != null, "Asset budget should load")
	if budget != null:
		passed = passed and _assert_true(_has_property(budget, "texture_import_lossy_quality"), "Budget should define texture_import_lossy_quality")
		passed = passed and _assert_true(_has_property(budget, "bgm_publish_vorbis_quality"), "Budget should define bgm_publish_vorbis_quality")
		if _has_property(budget, "texture_import_lossy_quality"):
			passed = passed and _assert_true(float(budget.get("texture_import_lossy_quality")) <= 0.58, "Texture lossy quality should be mobile-sized")
		if _has_property(budget, "bgm_publish_vorbis_quality"):
			passed = passed and _assert_true(float(budget.get("bgm_publish_vorbis_quality")) <= 0.0, "BGM publish Vorbis quality should be mobile-sized")
	for import_path in HEAVY_TEXTURE_IMPORTS:
		passed = passed and _assert_import_uses_lossy(import_path)
	passed = passed and _assert_energy_sheet_imports_use_lossy("res://Assets/Themes/cyberpunk_theme/energy_sheets")

	if passed:
		print("test_mobile_publish_asset_import_policy: PASS")
		quit(0)
	else:
		print("test_mobile_publish_asset_import_policy: FAIL")
		quit(1)

func _assert_energy_sheet_imports_use_lossy(root_path: String) -> bool:
	var passed := true
	var stack := [root_path]
	while not stack.is_empty():
		var path := String(stack.pop_back())
		var dir := DirAccess.open(path)
		if dir == null:
			passed = passed and _assert_true(false, "Energy sheet directory should open %s" % path)
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while not entry.is_empty():
			if entry.begins_with("."):
				entry = dir.get_next()
				continue
			var child := path.path_join(entry)
			if dir.current_is_dir():
				stack.append(child)
			elif entry.ends_with(".png"):
				passed = passed and _assert_import_uses_lossy(child + ".import")
			entry = dir.get_next()
	return passed

func _assert_import_uses_lossy(import_path: String) -> bool:
	var text := FileAccess.get_file_as_string(import_path)
	var passed := true
	passed = passed and _assert_true(not text.is_empty(), "Import file should exist %s" % import_path)
	passed = passed and _assert_true(text.contains("compress/mode=1"), "Import file should use lossy compression %s" % import_path)
	passed = passed and _assert_true(text.contains("compress/lossy_quality=0.55"), "Import file should use canonical mobile lossy quality %s" % import_path)
	return passed

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
