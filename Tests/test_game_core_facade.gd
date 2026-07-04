extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")
const CoreScript := preload("res://addons/shinokute_game_core/core/game_core.gd")

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var cfg = ConfigScript.new()
	cfg.game_id = "glyphflow_arrays"
	cfg.firebase_project_id = "foodapp-7ff6b"
	cfg.firestore_api_key = "abc"
	cfg.leaderboard_collections = {"classic": "glyphflow_classic"}
	cfg.score_sort_directions = {"classic": "ASCENDING"}
	cfg.score_labels = {"classic": "moves"}
	var core = CoreScript.new()
	root.add_child(core)
	await process_frame
	core.configure(cfg, "user://shinokute_core_facade_test.cfg")
	await process_frame
	core.save_store.wipe_all()
	_assert_true(core.profile != null, "profile wired")
	_assert_true(core.leaderboard != null, "leaderboard wired")
	_assert_true(core.geo_service != null, "geo service wired")
	_assert_true(core.submit_score({"mode": "classic", "value": 3}) == OK, "submit score accepts canonical dict")
	core.save_store.wipe_all()
	_report("test_game_core_facade")

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
