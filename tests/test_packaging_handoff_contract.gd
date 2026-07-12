extends SceneTree

const AGENTS := "res://AGENTS.md"
const HANDOFF := "res://docs/packaging_handoff.md"
const ANDROID_RUNBOOK := "res://docs/android_packaging_runbook.md"
const FIREBASE := "res://firebase.json"
const FIREBASERC := "res://.firebaserc"
const EXPORT_PRESETS := "res://export_presets.cfg"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(AGENTS, "docs/packaging_handoff.md", "AGENTS should force packaging agents to read the packaging handoff") and passed
	passed = _assert_file_contains(AGENTS, "docs/android_packaging_runbook.md", "AGENTS should force Android packagers to read the Android runbook") and passed
	passed = _assert_file_contains(AGENTS, "contextless packaging agents", "AGENTS should state that packaging handoff is for agents without chat context") and passed
	passed = _assert_file_contains(AGENTS, "Before finishing, committing, or pushing source changes", "AGENTS should require source-completion handoff review before commits") and passed
	passed = _assert_file_contains(AGENTS, "Android Packaging Reset Rule", "AGENTS should force Android packagers to read the Android reset rule") and passed
	passed = _assert_file_contains(HANDOFF, "Contextless Agent Bootstrap", "Packaging handoff should have a contextless bootstrap section") and passed
	passed = _assert_file_contains(HANDOFF, "Source Completion Handoff Gate", "Packaging handoff should require source owners to maintain deploy docs before push") and passed
	passed = _assert_file_contains(HANDOFF, "docs/android_packaging_runbook.md", "Packaging handoff should delegate Android packaging details to the Android runbook") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "Android Packaging Runbook", "Android runbook should exist as the Android packaging SSOT") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "Duplication Rule", "Android runbook should define how duplicate Android docs are avoided") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "Android Packaging Reset Rule", "Android runbook should document the Android packaging reset rule") and passed
	passed = _assert_file_contains(HANDOFF, "Source handoff work must not install Java/JDK", "Packaging handoff should forbid toolchain installs during source handoff") and passed
	passed = _assert_file_contains(HANDOFF, "First compare the existing shipped patterns", "Packaging handoff should require comparing shipped Android branches before guessing") and passed
	passed = _assert_file_contains(HANDOFF, "Do not create a replacement keystore", "Packaging handoff should forbid unapproved replacement keystores") and passed
	passed = _assert_file_contains(HANDOFF, "Do not use memory, prior chat", "Packaging handoff should forbid chat-history-dependent packaging") and passed
	passed = _assert_file_contains(HANDOFF, "The packaging agent must stop if this contract fails after pulling.", "Packaging handoff should give stop condition for contextless agents") and passed
	passed = _assert_file_contains(HANDOFF, "Export/", "Packaging handoff should define canonical Godot export folder") and passed
	passed = _assert_file_contains(HANDOFF, "Export_web_test/", "Packaging handoff should define Firebase public folder") and passed
	passed = _assert_file_contains(HANDOFF, "firebase hosting:channel:deploy candy-sky-islands-test", "Packaging handoff should name the Firebase preview channel command") and passed
	passed = _assert_file_contains(HANDOFF, "play.shinokute.com", "Packaging handoff should name the production custom domain") and passed
	passed = _assert_file_contains(HANDOFF, "firebase deploy --only hosting:shinokute-play --project shinokute-studio", "Packaging handoff should name the production deploy command") and passed
	passed = _assert_file_contains(HANDOFF, "Android preset name: `Android`", "Packaging handoff should name the Android preset") and passed
	passed = _assert_file_contains(HANDOFF, "Package id: `com.shinokutestudio.candyskyislands`", "Packaging handoff should name Candy Android package id") and passed
	passed = _assert_file_contains(HANDOFF, "AAB export path: `Export/candy_sky_islands.aab`", "Packaging handoff should name Candy AAB output") and passed
	passed = _assert_file_contains(HANDOFF, "candy_sky_islands_keystore_secrets.json", "Packaging handoff should name password source without embedding secrets") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "Gate 4C: Android Payload Hygiene", "Android runbook should require Android AAB scan") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "tools/patch_android_template_for_play.ps1", "Android runbook should require the local template patch script") and passed
	passed = _assert_file_contains(ANDROID_RUNBOOK, "android/build/.gdignore", "Android runbook should preserve Android template gdignore marker") and passed
	passed = _assert_file_not_contains(HANDOFF, "Android blocked: no Android preset or signing handoff in source", "Packaging handoff should not keep the old Android source blocker after source preset exists") and passed
	passed = _assert_file_contains(HANDOFF, "$runtimeFiles = @(", "Packaging handoff should sync Firebase public dir from runtime whitelist") and passed
	passed = _assert_file_contains(HANDOFF, "PUBLIC_WHITELIST_SYNC_PASS", "Packaging handoff should report whitelist sync evidence") and passed
	passed = _assert_file_contains(HANDOFF, "PUBLIC_FORBIDDEN", "Packaging handoff should fail if public dir contains sidecar artifacts") and passed
	passed = _assert_file_not_contains(HANDOFF, "Copy-Item -LiteralPath (Get-ChildItem", "Packaging handoff must not copy all files from Export into Firebase public dir") and passed
	passed = _assert_file_contains(HANDOFF, "export_filter=\"resources\"", "Packaging handoff should preserve selected-resource export rule") and passed
	passed = _assert_file_contains(HANDOFF, "Do not claim Android", "Packaging handoff should block Android/package-ready claims until Android evidence exists") and passed
	passed = _assert_file_contains(FIREBASE, "\"target\": \"candy-preview\"", "Firebase config should define preview hosting target") and passed
	passed = _assert_file_contains(FIREBASE, "\"target\": \"shinokute-play\"", "Firebase config should define production play hosting target") and passed
	passed = _assert_file_contains(FIREBASE, "\"public\": \"Export_web_test\"", "Firebase config should publish from Export_web_test") and passed
	passed = _assert_file_contains(FIREBASE, "\"**/*.import\"", "Firebase config should ignore Godot import sidecars") and passed
	passed = _assert_file_contains(FIREBASE, "\"**/*.gdignore\"", "Firebase config should ignore Godot gdignore sidecars") and passed
	passed = _assert_file_contains(FIREBASERC, "\"play\": \"shinokute-studio\"", "Firebase rc should expose play project alias") and passed
	passed = _assert_file_contains(FIREBASERC, "\"shinokute-play\"", "Firebase rc should map shinokute-play hosting target") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "export_path=\"Export/candy_sky_islands.html\"", "Web preset should still export canonical local build to Export") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "platform=\"Android\"", "Android preset should exist after source package/signing handoff is approved") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "export_path=\"Export/candy_sky_islands.aab\"", "Android preset should export canonical Candy AAB to Export") and passed
	passed = _assert_file_contains(EXPORT_PRESETS, "package/unique_name=\"com.shinokutestudio.candyskyislands\"", "Android preset should carry Candy package id") and passed
	passed = _assert_true(not FileAccess.file_exists("res://Export_web_test/.gdignore"), "Firebase public dir should not keep .gdignore as a tracked public artifact") and passed
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

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
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
