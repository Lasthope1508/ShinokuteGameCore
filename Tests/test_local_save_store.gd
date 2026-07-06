extends SceneTree

const StoreScript := preload("res://addons/shinokute_game_core/core/local_save_store.gd")

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var store = StoreScript.new()
	root.add_child(store)
	store.save_path = "user://shinokute_game_core_test.cfg"
	store.load_store()
	store.wipe_all()
	store.set_username("  Player One  ")
	_assert_eq(store.get_username(), "Player One", "trimmed username")
	var first_uuid := store.get_device_uuid()
	var second_uuid := store.get_device_uuid()
	_assert_true(first_uuid.length() == 32, "uuid should be 32 hex chars")
	_assert_eq(second_uuid, first_uuid, "uuid stable")
	store.set_geolocation("VN", "Vietnam", "AS")
	_assert_eq(store.get_country_code(), "VN", "country code")
	_assert_eq(store.get_country_name(), "Vietnam", "country name")
	_assert_eq(store.get_continent_code(), "AS", "continent code")
	store.set_best_score(12, "classic")
	store.set_last_submitted_score(10, "classic")
	store.set_pending_score(8, "classic")
	_assert_eq(store.get_best_score("classic"), 12, "best score")
	_assert_eq(store.get_last_submitted_score("classic"), 10, "last submitted score")
	_assert_eq(store.get_pending_score("classic"), 8, "pending score")
	store.clear_pending_score("classic")
	_assert_eq(store.get_pending_score("classic"), 0, "cleared pending score")
	store.wipe_all()
	root.remove_child(store)
	store.free()
	_report("test_local_save_store")

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
