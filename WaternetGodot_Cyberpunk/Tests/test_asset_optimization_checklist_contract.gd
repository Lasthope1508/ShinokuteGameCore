extends SceneTree

func _init() -> void:
	var passed := true
	var checklist := FileAccess.get_file_as_string("res://docs/mobile_html5_asset_optimization_checklist.md")
	var release_checklist := FileAccess.get_file_as_string("res://docs/release_packaging_checklist.md")

	passed = passed and _assert_true(not checklist.is_empty(), "Mobile/HTML5 asset optimization checklist should exist")
	passed = passed and _assert_true(release_checklist.contains("docs/mobile_html5_asset_optimization_checklist.md"), "Release packaging checklist should require asset optimization checklist")

	for required_text in [
		"Required Reading For Packaging Agents",
		"Hard Rule: No Fallback, No Guessing",
		"Runtime Asset Manifest",
		"Export Exclusion Gate",
		"Import Compression Gate",
		"Texture Budget",
		"Audio Budget",
		"HTML5 Initial Download Budget",
		"Android Bundle Budget",
		"Lazy Loading Gate",
		"Cache And CDN Gate",
		"Verification Commands",
		"Owner Approval Gate",
		"Forbidden Runtime Payload",
		"SSOT Fields To Add Before Optimization",
		"Package-Ready Definition"
	]:
		passed = passed and _assert_true(checklist.contains(required_text), "Asset optimization checklist should document %s" % required_text)

	for forbidden_payload in [
		"debug/",
		"component_refs/",
		"style_trial_",
		"raw.png",
		"_raw.png",
		"preview_sheet",
		"Tests/",
		"docs/",
		"backup_cyberpunk_assets_before"
	]:
		passed = passed and _assert_true(checklist.contains(forbidden_payload), "Asset optimization checklist should forbid %s in runtime payload" % forbidden_payload)

	for budget_text in [
		"Export/glyphflow_arrays.pck",
		"Export/glyphflow_arrays.wasm",
		"Export/glyphflow_arrays.aab",
		"Audio/Music/cyberpunk_theme/Gameplay.ogg",
		"Assets/VFX/lightning_boltarc_01_spritesheet.png"
	]:
		passed = passed and _assert_true(checklist.contains(budget_text), "Asset optimization checklist should name measured heavy payload %s" % budget_text)

	if passed:
		print("test_asset_optimization_checklist_contract: PASS")
		quit(0)
	else:
		print("test_asset_optimization_checklist_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
