extends SceneTree

const CHECKLIST := "res://docs/reskin_checklist.md"
const MANIFEST := "res://docs/asset_manifest.md"
const SPEC := "res://docs/superpowers/specs/2026-07-07-candy-sky-islands-reskin-design.md"
const THEME := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Owner approved theme name: Candy Sky Islands.", "Checklist should record theme approval")
	passed = passed and _assert_file_contains(CHECKLIST, "[x] Checkpoint 1 approved.", "Checklist should record Checkpoint 1")
	passed = passed and _assert_file_contains(MANIFEST, "collectible.coin.scene", "Manifest should inventory coin scene")
	passed = passed and _assert_file_contains(MANIFEST, "hud.coin.text", "Manifest should inventory HUD text")
	passed = passed and _assert_file_contains(SPEC, "Candy Sky Islands", "Spec should name the approved theme")
	passed = passed and _assert_true(ResourceLoader.exists(THEME), "Theme resource should exist")
	if passed:
		print("test_reskin_static_contract: PASS")
		quit(0)
	else:
		print("test_reskin_static_contract: FAIL")
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

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
