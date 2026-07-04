extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")

var _passed := true

func _init() -> void:
	var cfg = ConfigScript.new()
	cfg.game_id = "glyphflow_arrays"
	cfg.display_name = "Glyphflow Arrays"
	cfg.firebase_project_id = "foodapp-7ff6b"
	cfg.firestore_api_key = "abc"
	cfg.geolocation_url = "https://example.com/location"
	cfg.leaderboard_collections = {"classic": "glyphflow_classic"}
	cfg.score_labels = {"classic": "moves"}
	cfg.score_sort_directions = {"classic": "ASCENDING"}
	cfg.username_min_length = 3
	cfg.username_max_length = 15
	cfg.allow_skip_username = true
	cfg.require_username_on_first_launch = true
	_assert_eq(cfg.get_collection("classic"), "glyphflow_classic", "collection from config")
	_assert_eq(cfg.get_score_label("classic"), "moves", "score label from config")
	_assert_eq(cfg.get_sort_direction("classic"), "ASCENDING", "sort direction from config")
	_assert_true(cfg.is_username_required(), "username should be required")
	_assert_true(cfg.validate_config().is_empty(), "valid config should have no errors")
	_assert_true(cfg.validate_username("Abc").is_empty(), "valid username accepted")
	_assert_true(not cfg.validate_username("Al").is_empty(), "short username rejected")
	_assert_true(not cfg.validate_username("ThisNameIsWayTooLong").is_empty(), "long username rejected")
	_report("test_game_core_config")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
