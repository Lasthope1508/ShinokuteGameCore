extends SceneTree

const AGENTS := "res://AGENTS.md"
const HANDOFF := "res://docs/packaging_handoff.md"
const FIREBASE := "res://firebase.json"
const EXPORT_PRESETS := "res://export_presets.cfg"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(AGENTS, "docs/packaging_handoff.md", "AGENTS should force packaging agents to read the packaging handoff") and passed
	passed = _assert_file_contains(HANDOFF, "Export/", "Packaging handoff should define canonical Godot export folder") and passed
	passed = _assert_file_contains(HANDOFF, "Export_web_test/", "Packaging handoff should define Firebase public folder") and passed
	passed = _assert_file_contains(HANDOFF, "firebase hosting:channel:deploy candy-sky-islands-test", "Packaging handoff should name the Firebase preview channel command") and passed
	passed = _assert_file_contains(HANDOFF, "export_filter=\"resources\"", "Packaging handoff should preserve selected-resource export rule") and passed
	passed = _assert_file_contains(HANDOFF, "Do not claim Android", "Packaging handoff should block Android/package-ready claims until Android evidence exists") and passed
	passed = _assert_file_contains(FIREBASE, "\"public\": \"Export_web_test\"", "Firebase config should publish from Export_web_test") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "export_path=\"Export/candy_sky_islands.html\"", "Web preset should still export canonical local build to Export") and passed
	_finish(passed)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_packaging_handoff_contract: PASS")
		quit(0)
	else:
		print("test_packaging_handoff_contract: FAIL")
		quit(1)
