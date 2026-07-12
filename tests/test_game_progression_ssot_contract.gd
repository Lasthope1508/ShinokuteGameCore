extends SceneTree

const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const MAIN_SCENE := "res://scenes/main.tscn"
const GOAL_SCENE := "res://objects/goal_flag.tscn"
const PLAYER_SCRIPT := "res://scripts/player.gd"
const PLAYER_CORE_SCRIPT := "res://addons/shinokute_game_core/controllers/character_3d_controller.gd"
const PLATFORM_SCRIPT := "res://objects/platform_falling.gd"
const MANAGER_SCRIPT := "res://scripts/game_progression.gd"
const DOC := "res://docs/gameplay_progression_ssot.md"
const AGENTS := "res://AGENTS.md"
const CORE_PROGRESS_CATALOG := "res://addons/shinokute_game_core/core/progression_catalog.gd"
const CORE_PROGRESS_LEVEL := "res://addons/shinokute_game_core/core/progression_level.gd"
const CORE_DYNAMIC_PROGRESS := "res://addons/shinokute_game_core/core/dynamic_progression_resolver.gd"
const LEGACY_PROGRESS_CONFIG := "res://Resources/GameProgressionConfig.gd"
const LEGACY_PROGRESS_LEVEL := "res://Resources/GameLevelDefinition.gd"

func _init() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(CONFIG_PATH), "Progression config should exist") and passed
	passed = _assert_true(ResourceLoader.exists(MAIN_SCENE), "Main scene should exist") and passed
	passed = _assert_true(ResourceLoader.exists(GOAL_SCENE), "Goal scene should exist") and passed
	passed = _assert_true(ResourceLoader.exists(MANAGER_SCRIPT), "Progression manager script should exist") and passed
	passed = _assert_file_contains(DOC, "progression.level_catalog", "Progression SSOT doc should define canonical level catalog") and passed
	passed = _assert_file_contains(DOC, "difficulty.curve", "Progression SSOT doc should define canonical difficulty curve") and passed
	passed = _assert_file_contains(DOC, "ShinokuteProgressionCatalog", "Progression SSOT doc should map to Shinokute core catalog") and passed
	passed = _assert_file_contains(DOC, "dynamic_progression_profile", "Progression SSOT doc should document dynamic infinite progression") and passed
	passed = _assert_file_contains(DOC, "deterministic", "Progression SSOT doc should require fair deterministic route randomness") and passed
	passed = _assert_file_contains(DOC, "3d_obby", "Progression SSOT doc should document 3D obby profile") and passed
	passed = _assert_file_contains(AGENTS, "docs/gameplay_progression_ssot.md", "AGENTS should require progression SSOT before gameplay progression work") and passed
	passed = _assert_file_contains(MAIN_SCENE, "[node name=\"GameProgression\"", "Main should own a GameProgression node") and passed
	passed = _assert_file_contains(MAIN_SCENE, "progression_config", "Main should bind progression config through exported Resource") and passed
	passed = _assert_file_contains(GOAL_SCENE, "GoalArea", "Goal should expose a trigger Area3D") and passed
	passed = _assert_file_contains(GOAL_SCENE, "path=\"res://objects/goal_flag.gd\"", "Goal should route completion through script") and passed
	passed = _assert_file_contains(PLAYER_SCRIPT, PLAYER_CORE_SCRIPT, "Candy player should inherit core controller") and passed
	passed = _assert_file_contains(PLAYER_CORE_SCRIPT, "fall_reset_y", "Core player fall threshold should be configurable") and passed
	passed = _assert_file_not_contains(PLAYER_CORE_SCRIPT, "position.y < -10", "Core player should not hardcode fall threshold") and passed
	passed = _assert_file_not_contains(PLAYER_SCRIPT, "reload_current_scene", "Player death path should not reload the SceneTree on Web") and passed
	passed = _assert_file_not_contains(PLAYER_CORE_SCRIPT, "reload_current_scene", "Core player death path should not reload the SceneTree on Web") and passed
	passed = _assert_file_contains(PLAYER_CORE_SCRIPT, "reset_for_level", "Core player should expose an in-place level reset hook") and passed
	passed = _assert_file_contains(PLATFORM_SCRIPT, "apply_difficulty_profile", "Falling platform should accept difficulty profile") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "difficulty_curve", "Core level definition should own difficulty as generic curve data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "completion_condition", "Core level definition should own completion condition as data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "failure_policy", "Core level definition should own failure policy as data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "layout_profile", "Core level definition should own layout profile as data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "stage_segments", "Core level definition should own stage segments as data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_LEVEL, "environment_segments", "Core level definition should own terrain and decor segments as data") and passed
	passed = _assert_file_contains(CORE_PROGRESS_CATALOG, "difficulty_sort_directions", "Core progression catalog should validate difficulty through data-owned sort directions") and passed
	passed = _assert_file_contains(CORE_PROGRESS_CATALOG, "layout_sort_directions", "Core progression catalog should validate obby map shape through data-owned sort directions") and passed
	passed = _assert_file_contains(CORE_PROGRESS_CATALOG, "dynamic_progression_profile", "Core progression catalog should own dynamic profile schema") and passed
	passed = _assert_file_contains(CORE_DYNAMIC_PROGRESS, "class_name ShinokuteDynamicProgressionResolver", "Core should expose a generic dynamic progression resolver") and passed
	passed = _assert_file_contains(CONFIG_PATH, CORE_PROGRESS_CATALOG, "Candy progression config should use Shinokute core catalog script") and passed
	passed = _assert_file_contains(CONFIG_PATH, CORE_PROGRESS_LEVEL, "Candy progression levels should use Shinokute core level script") and passed
	passed = _assert_file_not_contains(MANAGER_SCRIPT, "GameProgressionConfig", "Candy progression manager should type against Shinokute core catalog") and passed
	passed = _assert_false(FileAccess.file_exists(LEGACY_PROGRESS_CONFIG), "Legacy game-local progression config schema should not remain") and passed
	passed = _assert_false(FileAccess.file_exists(LEGACY_PROGRESS_LEVEL), "Legacy game-local level schema should not remain") and passed
	passed = _assert_file_contains("res://scripts/obby_stage_builder.gd", "apply_difficulty_profile", "Obby stage builder should accept canonical difficulty/profile data") and passed
	passed = _assert_file_contains("res://scripts/obby_stage_builder.gd", "environment_segments", "Obby stage builder should build terrain and decor from data") and passed
	passed = _assert_file_contains("res://scripts/obby_stage_builder.gd", "prop_scenes", "Obby stage builder should map prop kinds to game-owned scenes") and passed
	passed = _assert_file_contains(MAIN_SCENE, "obby_stage_builder.gd", "World should build Candy map from data-owned stage segments") and passed
	passed = _assert_file_not_contains(MANAGER_SCRIPT, "reload_current_scene", "Progression should not reload the SceneTree for win/death on Web") and passed
	passed = _assert_file_not_contains(MANAGER_SCRIPT, "change_scene", "Progression should not change scenes for win/death gameplay transitions") and passed
	passed = _assert_file_contains(MANAGER_SCRIPT, "_transition_in_progress", "Progression should guard against repeated win/death reset requests") and passed
	passed = _assert_file_contains(MANAGER_SCRIPT, "call_deferred(\"_restart_current_level\")", "Progression should defer death reset out of physics/signal callback") and passed
	passed = _assert_file_contains(MANAGER_SCRIPT, "call_deferred(\"_start_next_level\")", "Progression should defer next-level start out of goal signal callback") and passed
	passed = _assert_file_not_contains(CORE_PROGRESS_CATALOG, "falling_platform_acceleration < previous_accel", "Progression catalog should not hardcode falling platform acceleration validation") and passed
	passed = _assert_file_not_contains(CORE_PROGRESS_CATALOG, "falling_platform_trigger_delay > previous_delay", "Progression catalog should not hardcode falling trigger delay validation") and passed

	var config := load(CONFIG_PATH)
	passed = _assert_true(config != null, "Progression config should load") and passed
	if config != null:
		passed = _assert_true(config.game_family == "3d_obby", "Progression config should use 3D obby family") and passed
		passed = _assert_true(config.level_catalog.size() >= 3, "Progression config should define at least 3 levels") and passed
		passed = _assert_true(config.dynamic_progression_profile.has("layout_curves"), "Progression config should own dynamic layout curves") and passed
		passed = _assert_true(config.has_method("get_difficulty_profile_for_level_number"), "Progression config should expose dynamic profile lookup") and passed
		var dynamic_profile: Dictionary = config.get_difficulty_profile_for_level_number(25, 3.221)
		passed = _assert_true(int(dynamic_profile.get("level_number", 0)) == 25, "Dynamic profile should preserve visible level number") and passed
		passed = _assert_true(Dictionary(dynamic_profile.get("layout_profile", {})).has("route_shape"), "Dynamic profile should carry route shape SSOT") and passed
		var previous_values := {}
		for index in config.level_catalog.size():
			var level = config.level_catalog[index]
			passed = _assert_true(not level.level_id.strip_edges().is_empty(), "Level %s should have canonical id" % index) and passed
			var profile: Dictionary = level.difficulty_profile()
			passed = _assert_true(profile.has("completion_condition"), "Level %s should expose completion condition in profile" % index) and passed
			passed = _assert_true(profile.has("failure_policy"), "Level %s should expose failure policy in profile" % index) and passed
			passed = _assert_true(profile.has("layout_profile"), "Level %s should expose layout profile in profile" % index) and passed
			passed = _assert_true(profile.has("stage_segments"), "Level %s should expose stage segments in profile" % index) and passed
			passed = _assert_true(profile.has("environment_segments"), "Level %s should expose environment segments in profile" % index) and passed
			passed = _assert_true(level.stage_segments.size() >= 2, "Level %s should define at least start and goal segments" % index) and passed
			for key in config.required_difficulty_keys:
				var curve_key := String(key)
				passed = _assert_true(profile.has(curve_key), "Level %s should expose difficulty key %s" % [index, curve_key]) and passed
				var direction := String(config.difficulty_sort_directions.get(curve_key, "NONE")).to_upper()
				var value := float(profile.get(curve_key, 0.0))
				if previous_values.has(curve_key):
					var previous := float(previous_values[curve_key])
					if direction == "ASCENDING":
						passed = _assert_true(value >= previous, "%s should not decrease" % curve_key) and passed
					elif direction == "DESCENDING":
						passed = _assert_true(value <= previous, "%s should not increase" % curve_key) and passed
				previous_values[curve_key] = value
			for key in config.required_layout_keys:
				var layout_key := String(key)
				passed = _assert_true(level.layout_profile.has(layout_key), "Level %s should expose layout key %s" % [index, layout_key]) and passed
				var direction := String(config.layout_sort_directions.get(layout_key, "NONE")).to_upper()
				var value := float(level.layout_profile.get(layout_key, 0.0))
				var state_key := "layout_%s" % layout_key
				if previous_values.has(state_key):
					var previous := float(previous_values[state_key])
					if direction == "ASCENDING":
						passed = _assert_true(value >= previous, "%s should not decrease" % layout_key) and passed
					elif direction == "DESCENDING":
						passed = _assert_true(value <= previous, "%s should not increase" % layout_key) and passed
				previous_values[state_key] = value

	if passed:
		print("test_game_progression_ssot_contract: PASS")
		quit(0)
	else:
		print("test_game_progression_ssot_contract: FAIL")
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

func _assert_false(value: bool, message: String) -> bool:
	return _assert_true(not value, message)
