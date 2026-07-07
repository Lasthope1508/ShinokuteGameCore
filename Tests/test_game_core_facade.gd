extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")
const CoreScript := preload("res://addons/shinokute_game_core/core/game_core.gd")
const SAVE_PATH := "user://shinokute_core_facade_test.cfg"

var _passed := true

class FakeLeaderboard:
	extends Node
	var submitted: Array = []

	func submit_score(score: int, mode: String = "classic") -> int:
		submitted.append({"score": score, "mode": mode})
		return OK

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
	core.configure(cfg, SAVE_PATH)
	await process_frame
	core.save_store.wipe_all()
	_assert_true(core.profile != null, "profile wired")
	_assert_true(core.leaderboard != null, "leaderboard wired")
	_assert_true(core.geo_service != null, "geo service wired")
	_assert_true(core.theme_manager != null, "theme manager wired")
	_assert_true(core.audio_haptics != null, "audio and haptics wired")
	_assert_true(core.analytics != null, "analytics wired")
	_assert_true(core.ads != null, "ads wired")
	_assert_true(core.localization != null, "localization wired")
	_assert_true(core.remote_config != null, "remote config wired")
	_assert_true(core.scene_router != null, "scene router wired")
	_assert_true(core.overlay_manager != null, "overlay manager wired")
	_assert_true(core.session != null, "game session wired")
	_assert_true(core.submit_score({"mode": "classic", "value": 12}) == ERR_UNAVAILABLE, "submit without username stores locally but cannot submit remotely")
	_assert_eq(core.save_store.get_best_score("classic"), 12, "score without username should persist local best")
	_assert_eq(core.save_store.get_pending_score("classic"), 12, "score without username should persist pending submit")
	_assert_true(core.submit_score({"mode": "classic", "value": 9}) == ERR_UNAVAILABLE, "better ascending score without username stays pending")
	_assert_eq(core.save_store.get_best_score("classic"), 9, "lower moves should replace local best")
	_assert_eq(core.save_store.get_pending_score("classic"), 9, "lower moves should replace pending score")
	root.remove_child(core)
	core.free()
	core = CoreScript.new()
	root.add_child(core)
	await process_frame
	core.configure(cfg, SAVE_PATH)
	await process_frame
	_assert_eq(core.save_store.get_best_score("classic"), 9, "local best should survive game close and reload")
	_assert_eq(core.save_store.get_pending_score("classic"), 9, "pending score should survive game close and reload")
	var fake_leaderboard := FakeLeaderboard.new()
	core.add_child(fake_leaderboard)
	core.leaderboard = fake_leaderboard
	_assert_true(core.profile.commit_username("Runner") == true, "committing username should succeed")
	await process_frame
	_assert_eq(fake_leaderboard.submitted.size(), 1, "committing username should flush pending score")
	if fake_leaderboard.submitted.size() == 1:
		_assert_eq(int(fake_leaderboard.submitted[0]["score"]), 9, "flushed pending score should be best ascending score")
	core.save_store.wipe_all()
	_report("test_game_core_facade")

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
