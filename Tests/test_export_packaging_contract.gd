extends SceneTree

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const MANIFEST_PATH := "res://docs/runtime_asset_manifest.json"
const CHECKLIST_PATH := "res://docs/release_packaging_checklist.md"

func _init() -> void:
	var passed := true
	var export_presets := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	var manifest_raw := FileAccess.get_file_as_string(MANIFEST_PATH)
	var checklist := FileAccess.get_file_as_string(CHECKLIST_PATH)
	var optimization_doc := FileAccess.get_file_as_string("res://docs/mobile_html5_asset_optimization_checklist.md")
	var audio_doc := FileAccess.get_file_as_string("res://docs/audio_pipeline.md")
	var vfx_doc := FileAccess.get_file_as_string("res://docs/fake3d_vfx_checklist.md")

	passed = passed and _assert_true(not export_presets.is_empty(), "export_presets.cfg should exist")
	passed = passed and _assert_true(not export_presets.contains("export_filter=\"all_resources\""), "Release exports must not use all_resources")
	passed = passed and _assert_true(export_presets.contains("export_filter=\"resources\""), "Release exports should use explicit selected resources")
	passed = passed and _assert_true(export_presets.contains("custom_features=\"production\""), "Release exports should include production feature flag")
	passed = passed and _assert_true(export_presets.contains("export_path=\"Export/bloxchain.html\""), "Web export path should use BloxChain name")
	passed = passed and _assert_true(export_presets.contains("export_path=\"Export/bloxchain.aab\""), "Android export path should use BloxChain name")
	passed = passed and _assert_true(export_presets.contains("res://Scenes/Main/Main.tscn"), "Export files should include main scene")
	passed = passed and _assert_true(export_presets.contains("res://Scenes/MainMenu/MainMenu.tscn"), "Export files should include main menu scene")
	passed = passed and _assert_true(export_presets.contains("res://Scenes/Game/Game.tscn"), "Export files should include gameplay scene")
	passed = passed and _assert_true(not export_presets.contains("res://Assets/Sprites/bloxchain_logo_raw.png"), "Raw logo source must not be exported")

	for broad_include in ["*.png", "*.webp", "*.wav", "*.ogg", "*.tres", "Assets/**"]:
		for line in export_presets.split("\n"):
			if line.begins_with("include_filter="):
				passed = passed and _assert_true(not line.contains(broad_include), "include_filter must not use broad marker %s" % broad_include)

	for line in export_presets.split("\n"):
		if line.begins_with("export_files="):
			for marker in ["debug/", "Tests/", "docs/", "scratch/", ".claude/", ".agents/", ".bak", "_raw.png", "Export/"]:
				passed = passed and _assert_true(not line.contains(marker), "export_files must not include forbidden marker %s" % marker)

	var manifest = JSON.parse_string(manifest_raw)
	passed = passed and _assert_true(manifest is Dictionary, "Runtime manifest should parse")
	if manifest is Dictionary:
		var manifest_dict: Dictionary = manifest
		for required_key in ["version", "project", "main_scene", "scene_roots", "runtime_resource_roots", "non_runtime_policies", "export_forbidden_markers", "budgets", "package_ready_gates"]:
			passed = passed and _assert_true(manifest_dict.has(required_key), "Runtime manifest should include %s" % required_key)
		passed = passed and _assert_equal(manifest_dict.get("project", ""), "BloxChain", "Runtime manifest project should match BloxChain")
		var forbidden_markers: Array = manifest_dict.get("export_forbidden_markers", [])
		for marker in ["debug/", "Tests/", "docs/", "scratch/", ".bak", "_raw.png", "Export/"]:
			passed = passed and _assert_true(forbidden_markers.has(marker), "Runtime manifest should forbid %s" % marker)
		var budgets: Dictionary = manifest_dict.get("budgets", {})
		for budget_key in ["web_pck_mb", "android_aab_mb", "total_texture_mb", "bgm_mb", "sfx_mb", "vfx_atlas_mb", "single_texture_mb"]:
			passed = passed and _assert_true(float(budgets.get(budget_key, 0.0)) > 0.0, "Budget should be positive for %s" % budget_key)

	for required_doc in [
		[checklist, "docs/runtime_asset_manifest.json", "Release checklist should link runtime manifest"],
		[optimization_doc, "all_resources", "Optimization doc should forbid all_resources"],
		[audio_doc, "Audio/Music", "Audio doc should name runtime music folder"],
		[vfx_doc, "effects/2d_vortex", "VFX doc should name runtime VFX roots"]
	]:
		passed = passed and _assert_true(String(required_doc[0]).contains(String(required_doc[1])), String(required_doc[2]))

	passed = passed and _assert_runtime_paths_exported(export_presets)

	if passed:
		print("test_export_packaging_contract: PASS")
		quit(0)
	else:
		print("test_export_packaging_contract: FAIL")
		quit(1)

func _assert_runtime_paths_exported(export_presets: String) -> bool:
	var passed := true
	var runtime_files := _collect_runtime_files("res://Scenes")
	runtime_files.append_array(_collect_runtime_files("res://Resources"))
	runtime_files.append_array(_collect_runtime_files("res://Scripts"))
	for file_path in runtime_files:
		var text := FileAccess.get_file_as_string(file_path)
		for referenced_path in _extract_res_paths(text):
			if referenced_path.ends_with("/"):
				continue
			if referenced_path.get_extension().is_empty():
				continue
			if referenced_path.contains("%"):
				continue
			if referenced_path.contains("_raw.png"):
				continue
			if referenced_path.contains("/debug/") or referenced_path.contains("/scratch/"):
				continue
			passed = passed and _assert_true(export_presets.contains(referenced_path), "Referenced runtime path should be exported: %s" % referenced_path)
	return passed

func _collect_runtime_files(root_path: String) -> Array[String]:
	var files: Array[String] = []
	_collect_runtime_files_recursive(root_path, files)
	return files

func _collect_runtime_files_recursive(root_path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item.begins_with("."):
			item = dir.get_next()
			continue
		var path := "%s/%s" % [root_path, item]
		if dir.current_is_dir():
			_collect_runtime_files_recursive(path, files)
		elif path.ends_with(".gd") or path.ends_with(".tscn") or path.ends_with(".tres"):
			files.append(path)
		item = dir.get_next()

func _extract_res_paths(text: String) -> Array[String]:
	var paths: Array[String] = []
	var regex := RegEx.new()
	regex.compile("res://[^\"'\\)\\]\\s,]+")
	for result in regex.search_all(text):
		var value := result.get_string()
		if value.ends_with("."):
			value = value.trim_suffix(".")
		if not paths.has(value):
			paths.append(value)
	return paths

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [message, str(expected), str(actual)])
		return false
	return true
