extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

const REQUIRED_ROLE_KEYS := [
	"player_model_role",
	"player_shadow_role",
	"player_trail_mesh_role",
	"collectible_model_role",
	"collectible_particle_role",
	"hud_icon_role",
	"platform_small_role",
	"platform_medium_role",
	"platform_falling_role",
	"platform_round_role",
	"platform_large_unused_role",
	"block_coin_unused_role",
	"obstacle_brick_role",
	"obstacle_brick_particle_role",
	"goal_flag_role",
	"prop_cloud_role",
	"prop_grass_role",
	"prop_grass_small_role",
	"skybox_role",
	"colormap_role"
]

const ALLOWED_MODES := ["legacy", "material", "replacement", "unused_candidate", "audio_deferred"]

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		for key in REQUIRED_ROLE_KEYS:
			var role = theme.get(key)
			passed = _assert_true(role != null, "%s should exist" % key) and passed
			if role != null:
				passed = _assert_true(role.has_method("validate_role"), "%s should be a QuantumAssetRole-like resource" % key) and passed
				passed = _assert_true(ALLOWED_MODES.has(role.mode), "%s should use an allowed mode, got %s" % [key, role.mode]) and passed
				passed = _assert_true(not role.legacy_path.strip_edges().is_empty(), "%s should record legacy path" % key) and passed
				passed = _assert_true(role.validate_role().is_empty(), "%s should validate cleanly" % key) and passed
		passed = _assert_active_path(theme, "player_model_role", "res://objects/character.tscn") and passed
		passed = _assert_active_path(theme, "platform_small_role", "res://objects/platform.tscn") and passed
		passed = _assert_active_path(theme, "platform_medium_role", "res://objects/platform_medium.tscn") and passed
		passed = _assert_active_path(theme, "platform_falling_role", "res://objects/platform_falling.tscn") and passed
		passed = _assert_active_path(theme, "player_shadow_role", "res://assets/themes/candy_sky_islands/player_shadow_soft.png") and passed
		passed = _assert_active_path(theme, "platform_large_unused_role", "res://models/platform-large.glb") and passed
		passed = _assert_active_path(theme, "hud_icon_role", "res://assets/themes/candy_sky_islands/star_collectible.png") and passed
	if passed:
		print("test_deep_reskin_theme_contract: PASS")
		quit(0)
	else:
		print("test_deep_reskin_theme_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_active_path(theme: Resource, role_key: String, expected: String) -> bool:
	var role = theme.get(role_key)
	if role == null or not role.has_method("active_path"):
		push_error("%s should expose active_path()" % role_key)
		return false
	var actual: String = role.active_path()
	if actual != expected:
		push_error("%s active_path should be %s, got %s" % [role_key, expected, actual])
		return false
	return true
