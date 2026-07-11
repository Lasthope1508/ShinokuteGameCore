extends SceneTree

const PLAYER_SCENE := "res://objects/player.tscn"
const CHARACTER_SCENE := "res://objects/character.tscn"
const PLAYER_SCRIPT := "res://scripts/player.gd"
const PLAYER_CORE_SCRIPT := "res://addons/shinokute_game_core/controllers/character_3d_controller.gd"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const CAPTURE_TOOL := "res://tools/capture_candy_sky_screenshots.gd"
const PROOF := "res://docs/screenshots/candy_sky_islands_player_glb_replacement.png"
const CHR077_GLB := "res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb"

func _init() -> void:
	var passed := true

	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"Player\" type=\"CharacterBody3D\"]", "Player root should remain CharacterBody3D") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "script = ExtResource(\"1_ffboj\")", "Player script should remain attached") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "path=\"res://objects/character.tscn\"", "Player should keep existing character scene") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"Collider\" type=\"CollisionShape3D\" parent=\".\"]", "Player collider should remain") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"Character\" parent=\".\" instance=ExtResource(\"2_nero3\")]", "Existing rig scene should remain") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"ParticlesTrail\" type=\"GPUParticles3D\" parent=\".\"]", "Trail particles should remain") and passed
	passed = _assert_file_contains(PLAYER_SCENE, "[node name=\"SoundFootsteps\" type=\"AudioStreamPlayer\" parent=\".\"]", "Footsteps should remain") and passed
	passed = _assert_file_not_contains(PLAYER_SCENE, "CandyPlayerWrapper", "Player wrapper should remain removed after full character GLB replacement") and passed

	passed = _assert_file_contains(CHARACTER_SCENE, CHR077_GLB, "Character scene should use CHR077 Skeleton Mage player GLB") and passed
	passed = _assert_file_not_contains(CHARACTER_SCENE, "res://models/character.glb", "Character scene should not reference legacy player GLB") and passed
	passed = _assert_file_not_contains(CHARACTER_SCENE, "character_shinokute_human.glb", "Character scene should not reference rejected Shinokute human player GLB") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "[node name=\"CHR077SkeletonMageSlot\" type=\"Node3D\" parent=\".\"]", "Character scene should keep CHR077 scale slot") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "Transform3D(0.5, 0, 0, 0, 0.5, 0, 0, 0, 0.5", "Character scene should scale CHR077 through the player.model SSOT policy") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "[node name=\"CHR077SkeletonMageVisual\" parent=\"CHR077SkeletonMageSlot\" instance=ExtResource", "Character scene should instance CHR077 Skeleton Mage GLB visual under scale slot") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "[node name=\"AnimationPlayer\" type=\"AnimationPlayer\" parent=\".\"]", "Character scene should keep AnimationPlayer contract") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "\"idle\": SubResource", "Character scene should provide idle animation") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "\"walk\": SubResource", "Character scene should provide walk animation") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "\"run\": SubResource", "Character scene should provide run animation for future speed mapping") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "\"jump\": SubResource", "Character scene should provide jump animation") and passed
	passed = _assert_file_contains(CHARACTER_SCENE, "step = 0.0166667", "Character animations should use 60 FPS step") and passed
	passed = _assert_file_not_contains(CHARACTER_SCENE, "idle_sign_aura_ring", "CHR077 idle should not target removed Shinokute aura nodes") and passed

	passed = _assert_file_contains(PLAYER_SCRIPT, PLAYER_CORE_SCRIPT, "Candy player script should inherit Shinokute core character controller") and passed
	passed = _assert_file_contains(PLAYER_CORE_SCRIPT, "@onready var model = $Character", "Core player animation target should remain existing Character node") and passed
	passed = _assert_file_contains(PLAYER_CORE_SCRIPT, "Audio.play_event(\"jump\")", "Jump sound should stay routed through core event") and passed
	passed = _assert_file_contains(PLAYER_CORE_SCRIPT, "Audio.play_event(\"land\")", "Land sound should stay routed through core event") and passed
	passed = _assert_file_contains(CAPTURE_TOOL, "candy_sky_islands_player_glb_replacement.png", "Screenshot tool should capture player GLB proof") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		var role = theme.get("player_model_role")
		passed = _assert_true(role != null, "player_model_role should exist") and passed
		if role != null:
			passed = _assert_true(role.mode == "replacement", "player_model_role should be replacement mode") and passed
			passed = _assert_true(role.replacement_path == "res://objects/character.tscn", "player_model_role should point at CHR077 character scene") and passed
			passed = _assert_true(role.proof_path == PROOF, "player_model_role should record player GLB proof") and passed
			passed = _assert_true(String(role.notes).contains("preserves controller"), "player_model_role notes should record behavior preservation") and passed
			passed = _assert_true(String(role.notes).contains("CHR077 Skeleton Mage GLB"), "player_model_role notes should record CHR077 replacement") and passed

	if passed:
		print("test_deep_player_wrapper_contract: PASS")
		quit(0)
	else:
		print("test_deep_player_wrapper_contract: FAIL")
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

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
