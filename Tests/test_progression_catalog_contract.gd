extends SceneTree

const CatalogScript := preload("res://addons/shinokute_game_core/core/progression_catalog.gd")
const LevelScript := preload("res://addons/shinokute_game_core/core/progression_level.gd")
const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")

var _passed := true

func _init() -> void:
	var first = LevelScript.new()
	first.level_id = "stage_001"
	first.display_name = "Intro"
	first.difficulty_tier = 1
	first.completion_condition = {"type": "goal_reached", "coin_quota": 0}
	first.failure_policy = {"type": "retry_current", "fall_reset_y": -10.0}
	first.layout_profile = {
		"route_length": 18.0,
		"platform_count": 4,
		"verticality": 1.0,
		"gap_distance": 3.0,
		"hazard_count": 1
	}
	first.stage_segments = [
		{"role": "start", "position": Vector3(0, 0, 0), "platform": "large"},
		{"role": "goal", "position": Vector3(-12, 1, -4), "platform": "medium"}
	]
	first.environment_segments = [
		{"role": "decor", "kind": "cloud", "position": Vector3(2, 2, -4)}
	]
	first.difficulty_curve = {
		"falling_platform_acceleration": 15.0,
		"falling_platform_trigger_delay": 0.35
	}
	first.next_level_id = "stage_002"

	var second = LevelScript.new()
	second.level_id = "stage_002"
	second.display_name = "Drop"
	second.difficulty_tier = 2
	second.completion_condition = {"type": "goal_reached", "coin_quota": 1}
	second.failure_policy = {"type": "retry_current", "fall_reset_y": -12.0}
	second.layout_profile = {
		"route_length": 32.0,
		"platform_count": 7,
		"verticality": 2.5,
		"gap_distance": 4.5,
		"hazard_count": 2
	}
	second.stage_segments = [
		{"role": "start", "position": Vector3(0, 0, 0), "platform": "large"},
		{"role": "goal", "position": Vector3(-24, 2, -8), "platform": "medium"}
	]
	second.environment_segments = [
		{"role": "decor", "kind": "cloud", "position": Vector3(4, 2, -8)},
		{"role": "terrain", "kind": "brick", "position": Vector3(-8, 1, -2)}
	]
	second.difficulty_curve = {
		"falling_platform_acceleration": 20.0,
		"falling_platform_trigger_delay": 0.1
	}

	var catalog = CatalogScript.new()
	catalog.game_family = "3d_obby"
	catalog.required_difficulty_keys = ["falling_platform_acceleration", "falling_platform_trigger_delay"]
	catalog.required_layout_keys = ["route_length", "platform_count", "verticality", "gap_distance", "hazard_count"]
	catalog.layout_sort_directions = {
		"route_length": "ASCENDING",
		"platform_count": "ASCENDING",
		"verticality": "ASCENDING",
		"gap_distance": "ASCENDING",
		"hazard_count": "ASCENDING"
	}
	catalog.difficulty_sort_directions = {
		"falling_platform_acceleration": "ASCENDING",
		"falling_platform_trigger_delay": "DESCENDING"
	}
	catalog.level_catalog = [first, second]

	_assert_true(catalog.validate().is_empty(), "valid data-driven catalog should pass")
	_assert_eq(catalog.get_next_level_index(0), 1, "explicit next level should resolve by id")
	_assert_eq(catalog.get_next_level_index(1), 0, "default loop should return first level")
	var profile := catalog.get_difficulty_profile(0)
	_assert_eq(profile["level_id"], "stage_001", "profile should expose canonical level id")
	_assert_eq(profile["completion_condition"]["type"], "goal_reached", "profile should expose completion condition")
	_assert_eq(profile["failure_policy"]["fall_reset_y"], -10.0, "profile should expose failure policy")
	_assert_eq(profile["layout_profile"]["platform_count"], 4, "profile should expose canonical layout profile")
	_assert_eq(profile["stage_segments"].size(), 2, "profile should expose stage segment list")
	_assert_eq(profile["environment_segments"].size(), 1, "profile should expose environment segment list")
	_assert_eq(profile["falling_platform_acceleration"], 15.0, "profile should flatten difficulty curve values for gameplay nodes")

	var broken = LevelScript.new()
	broken.level_id = "broken"
	broken.completion_condition = {"type": "goal_reached"}
	broken.failure_policy = {"type": "retry_current"}
	broken.layout_profile = {"route_length": 1.0}
	broken.stage_segments = []
	broken.difficulty_curve = {"falling_platform_acceleration": 1.0}
	catalog.level_catalog = [first, broken]
	_assert_true(not catalog.validate().is_empty(), "missing required difficulty key should fail validation")

	var cfg = ConfigScript.new()
	cfg.game_id = "candy_sky_islands"
	cfg.firebase_project_id = "example"
	cfg.firestore_api_key = "example"
	cfg.leaderboard_collections = {"classic": "candy_scores"}
	cfg.progression_catalog = catalog
	_assert_true(not cfg.validate_config().is_empty(), "GameCoreConfig should surface progression catalog validation errors")

	_report("test_progression_catalog_contract")

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
