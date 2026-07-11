extends SceneTree

const SSOT := "res://docs/default_skin_size_ssot.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const AGENTS := "res://AGENTS.md"
const STATE := "res://docs/reskin_state.md"
const MANIFEST := "res://docs/asset_manifest.md"
const SPEC := "res://docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md"
const PLAN := "res://docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md"
const CHARACTER_3D_RUNBOOK := "res://docs/reskin_2d_character_to_3d_runbook.md"

const REQUIRED_KEYS := [
	"app.icon",
	"app.splash",
	"env.skybox",
	"hud.coin.icon",
	"hud.score.frame",
	"hud.coin.text",
	"hud.font.main",
	"player.model",
	"player.shadow",
	"player.trail.dust",
	"collectible.coin.model",
	"collectible.coin.particle",
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
	"material.colormap",
	"audio.jump",
	"audio.land",
	"audio.coin",
	"audio.walking",
	"audio.break",
	"audio.fall"
]

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(SSOT, "# Default Skin Size SSOT", "Default size SSOT should exist") and passed
	passed = _assert_file_contains(SSOT, "Before any future reskin design option", "SSOT should define future gate blocker") and passed
	passed = _assert_file_contains(SSOT, "glb_replacement_done", "SSOT should distinguish full GLB replacement from wrappers") and passed
	passed = _assert_file_contains(SSOT, "legacy_mesh_kept", "SSOT should still distinguish VFX wrappers from full replacement") and passed
	passed = _assert_file_contains(SSOT, "CandyScoreFrame", "SSOT should lock HUD runtime sizing") and passed
	passed = _assert_file_contains(SSOT, "3D parity rule", "SSOT should define 3D parity rule") and passed
	passed = _assert_file_contains(SSOT, "player.visual_target_height = 1.30 u", "SSOT should define player visual target height") and passed
	passed = _assert_file_contains(SSOT, "player.visual_allowed_height = 1.10..1.35 u", "SSOT should define player visual allowed height range") and passed
	passed = _assert_file_contains(SSOT, "player.visual_scale_policy", "SSOT should define player visual scale policy") and passed
	passed = _assert_file_contains(SSOT, "reskin_2d_character_to_3d_runbook.md", "SSOT should route owner 2D characters through the character-to-3D runbook") and passed
	passed = _assert_file_contains(SSOT, "reference-derived volumetric", "SSOT should record reference-derived volumetric replacements") and passed
	passed = _assert_file_contains(SSOT, "default is volumetric 3D", "SSOT should record volumetric default roles") and passed
	for key in REQUIRED_KEYS:
		passed = _assert_file_contains(SSOT, "| %s |" % key, "SSOT should include %s" % key) and passed
	passed = _assert_file_contains(CHECKLIST, "Checkpoint 0: Default Skin Size SSOT", "Checklist should put baseline before visual gates") and passed
	passed = _assert_file_contains(CHECKLIST, "do not mark a flat `Sprite3D`", "Checklist should forbid flat Sprite3D as full 3D replacement") and passed
	passed = _assert_file_contains(AGENTS, "docs/default_skin_size_ssot.md", "Reset guard should require default size SSOT") and passed
	passed = _assert_file_contains(AGENTS, "3D parity rule", "Reset guard should require 3D parity rule") and passed
	passed = _assert_file_contains(AGENTS, "player.visual_target_height", "Reset guard should require player scale envelope") and passed
	passed = _assert_file_contains(AGENTS, "docs/reskin_2d_character_to_3d_runbook.md", "Reset guard should require 2D character to 3D runbook") and passed
	passed = _assert_file_contains(STATE, "Default Skin Size SSOT", "State should record baseline size SSOT") and passed
	passed = _assert_file_contains(STATE, "2D character to 3D player runbook", "State should record character-to-3D runbook") and passed
	passed = _assert_file_contains(STATE, "Cloud 3D parity replacement applied", "State should record cloud 3D parity completion") and passed
	passed = _assert_file_contains(MANIFEST, "default_skin_size_ssot.md", "Manifest should point to baseline size SSOT") and passed
	passed = _assert_file_contains(MANIFEST, "reskin_2d_character_to_3d_runbook.md", "Manifest should point to character-to-3D runbook") and passed
	passed = _assert_file_contains(MANIFEST, "cloud_candy_volume.glb", "Manifest should record volumetric cloud GLB") and passed
	passed = _assert_file_contains(SPEC, "Phase 0A: Default Skin Size SSOT", "Spec should put baseline before theme SSOT") and passed
	passed = _assert_file_contains(SPEC, "3D parity amendment", "Spec should include 3D parity amendment") and passed
	passed = _assert_file_contains(SPEC, "2D character to 3D amendment", "Spec should include owner 2D character to 3D amendment") and passed
	passed = _assert_file_contains(PLAN, "Task 0: Default Skin Size SSOT Baseline", "Plan should include baseline task") and passed
	passed = _assert_file_contains(PLAN, "3D parity amendment", "Plan should include 3D parity amendment") and passed
	passed = _assert_file_contains(CHARACTER_3D_RUNBOOK, "9Router reference-based turnaround/multiview sprite generation", "Character-to-3D runbook should require 9Router multiview generation") and passed
	passed = _assert_file_contains(CHARACTER_3D_RUNBOOK, "Photoroom output for the full turnaround sheet", "Character-to-3D runbook should require Photoroom full generated sheet") and passed
	passed = _assert_file_contains(CHARACTER_3D_RUNBOOK, "polygon outline data for every generated view/sprite", "Character-to-3D runbook should require polygon extraction per sprite/view") and passed
	if passed:
		print("test_default_skin_size_ssot_contract: PASS")
		quit(0)
	else:
		print("test_default_skin_size_ssot_contract: FAIL")
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
