extends SceneTree

const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const CONCEPT_SHEET := "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png"
const STAR_COLLECTIBLE := "res://assets/themes/candy_sky_islands/star_collectible.png"
const HUD_SCORE_FRAME := "res://assets/themes/candy_sky_islands/hud_score_frame.png"
const EXTRACTION_QC := "res://assets/themes/candy_sky_islands/asset_family_extraction_qc.json"

func _init() -> void:
	var passed := true
	passed = passed and _assert_true(FileAccess.file_exists(CONCEPT_SHEET), "Asset family concept sheet should exist")
	passed = passed and _assert_true(FileAccess.file_exists(STAR_COLLECTIBLE), "Extracted star collectible should exist")
	passed = passed and _assert_true(FileAccess.file_exists(HUD_SCORE_FRAME), "Extracted HUD score frame should exist")
	passed = passed and _assert_true(FileAccess.file_exists(EXTRACTION_QC), "Extraction QC should exist")
	passed = passed and _assert_file_contains(MANIFEST, "asset_family.concept_sheet", "Manifest should include concept sheet asset key")
	passed = passed and _assert_file_contains(MANIFEST, "collectible.star_candy", "Manifest should include collectible asset-family key")
	passed = passed and _assert_file_contains(MANIFEST, "platform.cake_cloud_kit", "Manifest should include platform kit key")
	passed = passed and _assert_file_contains(MANIFEST, "hud.star_candy.icon", "Manifest should include HUD icon key")
	passed = passed and _assert_file_contains(MANIFEST, "env.candy_skybox", "Manifest should include skybox key")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Concept sheet generated and visually inspected.", "Checklist should record concept sheet inspection")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Concept sheet owner approved.", "Checklist should record owner concept approval")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Photoroom extraction completed for full sheet before object cloning:", "Checklist should record Photoroom full-sheet extraction")
	passed = passed and _assert_file_contains(STATE, "Asset Family concept sheet generated", "State should record concept sheet gate")
	passed = passed and _assert_file_contains(STATE, "Production extraction redone from the Photoroom alpha sheet", "State should record extraction gate")
	if passed:
		print("test_asset_family_manifest_contract: PASS")
		quit(0)
	else:
		print("test_asset_family_manifest_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
