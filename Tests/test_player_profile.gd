extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")
const StoreScript := preload("res://addons/shinokute_game_core/core/local_save_store.gd")
const ProfileScript := preload("res://addons/shinokute_game_core/core/player_profile.gd")

var _passed := true
var _required_count := 0
var _ready_names: Array[String] = []

func _init() -> void:
	var cfg = ConfigScript.new()
	cfg.username_min_length = 3
	cfg.username_max_length = 15
	cfg.allow_skip_username = true
	cfg.require_username_on_first_launch = true
	var store = StoreScript.new()
	store.save_path = "user://shinokute_profile_test.cfg"
	store.load_store()
	store.wipe_all()
	var profile = ProfileScript.new()
	profile.configure(cfg, store)
	profile.username_required.connect(func(): _required_count += 1)
	profile.profile_ready.connect(func(name: String): _ready_names.append(name))
	profile.ensure_profile_ready()
	_assert_eq(_required_count, 1, "first run asks username")
	_assert_eq(_ready_names.size(), 0, "not ready before username")
	_assert_true(not profile.validate_username("xy").is_empty(), "invalid name rejected")
	_assert_true(profile.commit_username("CyberPilot"), "commit valid username")
	_assert_eq(store.get_username(), "CyberPilot", "username saved")
	profile.ensure_profile_ready()
	_assert_eq(_ready_names[-1], "CyberPilot", "ready with saved username")
	store.wipe_all()
	_assert_true(profile.skip_username(), "skip allowed")
	_assert_true(store.get_username().begins_with("Player_"), "skip creates default player")
	store.wipe_all()
	_cleanup_nodes([store, profile])
	cfg = null
	_report("test_player_profile")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _cleanup_nodes(objects: Array) -> void:
	for object in objects:
		if object is Node:
			object.free()

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
