extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")
const StoreScript := preload("res://addons/shinokute_game_core/core/local_save_store.gd")
const ClientScript := preload("res://addons/shinokute_game_core/core/leaderboard_client.gd")

var _passed := true

func _init() -> void:
	var cfg = ConfigScript.new()
	cfg.firebase_project_id = "foodapp-7ff6b"
	cfg.firestore_api_key = "abc"
	cfg.leaderboard_collections = {"classic": "glyphflow_classic", "chaos": "bloxchain_chaos"}
	cfg.score_labels = {"classic": "moves"}
	cfg.score_sort_directions = {"classic": "ASCENDING", "chaos": "DESCENDING"}
	var store = StoreScript.new()
	store.save_path = "user://shinokute_leaderboard_test.cfg"
	store.load_store()
	store.wipe_all()
	store.set_username("Pilot")
	store.set_geolocation("VN", "Vietnam", "AS")
	var client = ClientScript.new()
	client.configure(cfg, store)
	var submit_url := client.build_submit_url("classic", "device123")
	_assert_true(submit_url.ends_with("/glyphflow_classic/device123?key=abc"), "submit url uses collection and key")
	var doc := client.build_score_document(7, "classic", "device123")
	_assert_eq(doc["fields"]["username"]["stringValue"], "Pilot", "document username")
	_assert_eq(doc["fields"]["score"]["integerValue"], "7", "document score")
	_assert_eq(doc["fields"]["score_label"]["stringValue"], "moves", "document score label")
	var world_query := client.build_query_payload("world", "classic")
	_assert_eq(world_query["structuredQuery"]["orderBy"][0]["direction"], "ASCENDING", "classic ascending")
	_assert_true(not world_query["structuredQuery"].has("where"), "world has no region filter")
	var country_query := client.build_query_payload("country", "classic")
	_assert_eq(country_query["structuredQuery"]["where"]["fieldFilter"]["field"]["fieldPath"], "country_code", "country filter")
	var chaos_query := client.build_query_payload("world", "chaos")
	_assert_eq(chaos_query["structuredQuery"]["orderBy"][0]["direction"], "DESCENDING", "chaos descending")
	store.wipe_all()
	_cleanup_nodes([store, client])
	cfg = null
	_report("test_leaderboard_client")

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
