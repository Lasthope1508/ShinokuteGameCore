extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const BUDGET_PATH := "res://Resources/Data/AssetBudgets/cyberpunk_asset_budget.tres"
const MANIFEST_PATH := "res://docs/runtime_asset_manifest.json"

func _init() -> void:
	var passed := true
	var theme: ThemeConfig = load(THEME_PATH)
	var budget: Resource = load(BUDGET_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(budget != null, "Cyber asset budget should load")
	if budget != null:
		for property_name in [
			"web_pck_mb",
			"android_aab_mb",
			"texture_total_mb",
			"generated_ui_mode_mb",
			"single_texture_mb",
			"vfx_atlas_mb",
			"bgm_mb",
			"sfx_total_mb",
			"forbidden_export_markers",
			"runtime_manifest_path"
		]:
			passed = passed and _assert_true(_has_property(budget, property_name), "Asset budget should own %s" % property_name)
		if _has_property(budget, "runtime_manifest_path"):
			passed = passed and _assert_equal(budget.get("runtime_manifest_path"), MANIFEST_PATH, "Asset budget should point to canonical runtime asset manifest")
		for numeric_property in [
			"web_pck_mb",
			"android_aab_mb",
			"texture_total_mb",
			"generated_ui_mode_mb",
			"single_texture_mb",
			"vfx_atlas_mb",
			"bgm_mb",
			"sfx_total_mb"
		]:
			if _has_property(budget, numeric_property):
				passed = passed and _assert_true(float(budget.get(numeric_property)) > 0.0, "%s should be positive" % numeric_property)

	var raw_manifest := FileAccess.get_file_as_string(MANIFEST_PATH)
	passed = passed and _assert_true(not raw_manifest.is_empty(), "Runtime asset manifest should exist")
	var manifest = JSON.parse_string(raw_manifest)
	passed = passed and _assert_true(manifest is Dictionary, "Runtime asset manifest should parse as JSON object")
	if manifest is Dictionary and theme != null:
		var manifest_dict: Dictionary = manifest
		for required_key in ["version", "budgets", "runtime_assets", "non_runtime_policies", "export_forbidden_markers", "package_ready_gates"]:
			passed = passed and _assert_true(manifest_dict.has(required_key), "Manifest should include %s" % required_key)
		var runtime_assets: Array = manifest_dict.get("runtime_assets", [])
		passed = passed and _assert_true(runtime_assets.size() > 0, "Manifest should list runtime assets")
		var path_index := {}
		for asset in runtime_assets:
			passed = passed and _assert_true(asset is Dictionary, "Runtime asset entry should be a dictionary")
			if asset is Dictionary:
				var entry: Dictionary = asset
				for field in ["path", "role", "runtime_required", "export_policy", "compression_policy", "owner_approved"]:
					passed = passed and _assert_true(entry.has(field), "Runtime asset entry should include %s" % field)
				path_index[String(entry.get("path", ""))] = true
		passed = passed and _assert_manifest_contains_theme_runtime_paths(theme, path_index)
		var forbidden_markers: Array = manifest_dict.get("export_forbidden_markers", [])
		for marker in ["debug/", "Tests/", "docs/", "component_refs/", "style_trial_", "_raw.png", "raw.png", "preview_sheet"]:
			passed = passed and _assert_true(forbidden_markers.has(marker), "Manifest should forbid export marker %s" % marker)
			if budget != null and _has_property(budget, "forbidden_export_markers"):
				passed = passed and _assert_true(budget.forbidden_export_markers.has(marker), "Asset budget should forbid export marker %s" % marker)

	if passed:
		print("test_asset_budget_runtime_manifest: PASS")
		quit(0)
	else:
		print("test_asset_budget_runtime_manifest: FAIL")
		quit(1)

func _assert_manifest_contains_theme_runtime_paths(theme: ThemeConfig, path_index: Dictionary) -> bool:
	var passed := true
	if _has_property(theme, "bgm_path"):
		passed = passed and _assert_true(path_index.has(String(theme.get("bgm_path"))), "Manifest should include theme BGM")
	if _has_property(theme, "bgm_manifest_path"):
		passed = passed and _assert_true(path_index.has(String(theme.get("bgm_manifest_path"))), "Manifest should include BGM manifest")
	if _has_property(theme, "sfx_event_paths"):
		var sfx_paths: Dictionary = theme.get("sfx_event_paths")
		for event_name in sfx_paths:
			passed = passed and _assert_true(path_index.has(String(sfx_paths[event_name])), "Manifest should include SFX event %s" % event_name)
	if _has_property(theme, "ui_cell_texture_paths"):
		var cell_paths: Dictionary = theme.get("ui_cell_texture_paths")
		for mode in cell_paths:
			passed = passed and _assert_true(path_index.has(String(cell_paths[mode])), "Manifest should include cell texture for %s" % mode)
	if _has_property(theme, "ui_generated_asset_paths"):
		var generated_paths: Dictionary = theme.get("ui_generated_asset_paths")
		for mode in generated_paths:
			var mode_paths: Dictionary = generated_paths[mode]
			for asset_key in mode_paths:
				passed = passed and _assert_true(path_index.has(String(mode_paths[asset_key])), "Manifest should include generated UI %s %s" % [mode, asset_key])
	if _has_property(theme, "energy_sheet_manifest_path"):
		passed = passed and _assert_true(path_index.has(String(theme.get("energy_sheet_manifest_path"))), "Manifest should include energy sheet manifest")
	return passed

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
