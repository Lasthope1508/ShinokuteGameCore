extends SceneTree

const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const SPEC := "res://docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md"
const PLAN := "res://docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md"

const REQUIRED_MANIFEST_KEYS := [
	"player.model",
	"player.shadow",
	"player.trail.dust",
	"collectible.coin.model",
	"collectible.coin.particle",
	"hud.star_candy.icon",
	"platform.small",
	"platform.medium",
	"platform.falling",
	"platform.round.large",
	"platform.large.unused_candidate",
	"block.coin.unused_candidate",
	"obstacle.brick",
	"obstacle.brick.particle",
	"goal.flag",
	"prop.cloud",
	"prop.grass",
	"prop.grass.small",
	"env.skybox",
	"material.colormap",
	"audio.break",
	"audio.fall"
]

func _init() -> void:
	var passed := true
	for key in REQUIRED_MANIFEST_KEYS:
		passed = _assert_file_contains(MANIFEST, key, "Manifest should include %s" % key) and passed
	passed = _assert_file_contains(CHECKLIST, "### Checkpoint 5: Deep Reskin", "Checklist should include deep reskin checkpoint") and passed
	passed = _assert_file_contains(CHECKLIST, "Stop before SFX replacement", "Checklist should record SFX stop rule") and passed
	passed = _assert_file_contains(STATE, "Deep Reskin", "State should mention deep reskin gate") and passed
	passed = _assert_file_contains(STATE, "SFX replacement deferred", "State should record SFX deferral") and passed
	passed = _assert_file_contains_case_insensitive(SPEC, "Stop before SFX Replacement", "Spec should record SFX boundary") and passed
	passed = _assert_file_contains(PLAN, "Candy Sky Islands Deep Reskin Implementation Plan", "Plan should exist") and passed
	if passed:
		print("test_deep_reskin_manifest_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_manifest_contract: FAIL")
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

func _assert_file_contains_case_insensitive(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.to_lower().contains(needle.to_lower()):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
