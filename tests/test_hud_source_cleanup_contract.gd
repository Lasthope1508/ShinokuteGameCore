extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const CHECKLIST := "res://docs/reskin_checklist.md"
const MANIFEST := "res://docs/asset_manifest.md"

func _init() -> void:
	var passed := true
	passed = _assert_file_not_contains(MAIN_SCENE, "path=\"res://sprites/coin.png\"", "Main scene should not source the old HUD coin sprite") and passed
	passed = _assert_file_contains(MAIN_SCENE, "path=\"res://assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png\"", "Main scene should source 9Router reference-edited HUD score frame") and passed
	passed = _assert_file_not_contains(MAIN_SCENE, "path=\"res://assets/themes/candy_sky_islands/hud_score_frame_clean.png\"", "Main scene should not source local cleanup fallback") and passed
	passed = _assert_file_contains(MAIN_SCENE, "[node name=\"CandyScoreFrame\" type=\"TextureRect\" parent=\"HUD\"]", "HUD should include real Candy Sky Islands score frame") and passed
	passed = _assert_file_not_contains(MAIN_SCENE, "[node name=\"Icon\" type=\"TextureRect\" parent=\"HUD\"]", "HUD should not keep the hidden old icon node") and passed
	passed = _assert_file_not_contains(MAIN_SCENE, "[node name=\"x\" type=\"Label\" parent=\"HUD\"]", "HUD should not keep the hidden old multiplier label") and passed
	passed = _assert_file_not_contains(MAIN_SCENE, "[node name=\"CandyScoreShell\" type=\"Panel\" parent=\"HUD\"]", "HUD should not use a dummy local panel shell") and passed
	passed = _assert_file_not_contains(MAIN_SCENE, "StyleBoxFlat_candy_hud", "HUD should not use dummy stylebox shell") and passed
	passed = _assert_file_contains(CHECKLIST, "Full HUD design source cleanup completed", "Checklist should track HUD source cleanup") and passed
	passed = _assert_file_contains(MANIFEST, "source cleanup applied", "Manifest should record HUD source cleanup") and passed
	if passed:
		print("test_hud_source_cleanup_contract: PASS")
		quit(0)
	else:
		print("test_hud_source_cleanup_contract: FAIL")
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
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true
