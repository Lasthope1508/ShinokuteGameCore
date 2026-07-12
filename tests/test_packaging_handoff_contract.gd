extends SceneTree

const AGENTS := "res://AGENTS.md"
const HANDOFF := "res://docs/packaging_handoff.md"
const FIREBASE := "res://firebase.json"
const FIREBASERC := "res://.firebaserc"
const EXPORT_PRESETS := "res://export_presets.cfg"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(AGENTS, "docs/packaging_handoff.md", "AGENTS should force packaging agents to read the packaging handoff") and passed
	passed = _assert_file_contains(HANDOFF, "Export/", "Packaging handoff should define canonical Godot export folder") and passed
	passed = _assert_file_contains(HANDOFF, "Export_web_test/", "Packaging handoff should define Firebase public folder") and passed
	passed = _assert_file_contains(HANDOFF, "firebase hosting:channel:deploy candy-sky-islands-test", "Packaging handoff should name the Firebase preview channel command") and passed
	passed = _assert_file_contains(HANDOFF, "play.shinokute.com", "Packaging handoff should name the production custom domain") and passed
	passed = _assert_file_contains(HANDOFF, "firebase deploy --only hosting:shinokute-play --project shinokute-studio", "Packaging handoff should name the production deploy command") and passed
	passed = _assert_file_contains(HANDOFF, "Android blocked: no Android preset or signing handoff in source", "Packaging handoff should give exact Android blocker wording") and passed
	passed = _assert_file_contains(HANDOFF, "export_filter=\"resources\"", "Packaging handoff should preserve selected-resource export rule") and passed
	passed = _assert_file_contains(HANDOFF, "Do not claim Android", "Packaging handoff should block Android/package-ready claims until Android evidence exists") and passed
	passed = _assert_file_contains(FIREBASE, "\"target\": \"candy-preview\"", "Firebase config should define preview hosting target") and passed
	passed = _assert_file_contains(FIREBASE, "\"target\": \"shinokute-play\"", "Firebase config should define production play hosting target") and passed
	passed = _assert_file_contains(FIREBASE, "\"public\": \"Export_web_test\"", "Firebase config should publish from Export_web_test") and passed
	passed = _assert_file_contains(FIREBASERC, "\"play\": \"shinokute-studio\"", "Firebase rc should expose play project alias") and passed
	passed = _assert_file_contains(FIREBASERC, "\"shinokute-play\"", "Firebase rc should map shinokute-play hosting target") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "export_path=\"Export/candy_sky_islands.html\"", "Web preset should still export canonical local build to Export") and passed
	passed = _assert_file_not_contains(EXPORT_PRESETS, "platform=\"Android\"", "Android preset must not exist until package id/signing handoff is approved") and passed
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

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains(needle):
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_packaging_handoff_contract: PASS")
		quit(0)
	else:
		print("test_packaging_handoff_contract: FAIL")
		quit(1)
