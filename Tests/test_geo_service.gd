extends SceneTree

const StoreScript := preload("res://addons/shinokute_game_core/core/local_save_store.gd")
const GeoScript := preload("res://addons/shinokute_game_core/core/geo_service.gd")

var _passed := true

func _init() -> void:
	var store = StoreScript.new()
	store.save_path = "user://shinokute_geo_test.cfg"
	store.load_store()
	store.wipe_all()
	var geo = GeoScript.new()
	geo.configure(store)
	geo.apply_geolocation_response({"country_code": "JP", "country_name": "Japan", "continent_code": "AS"})
	_assert_eq(store.get_country_code(), "JP", "country code saved")
	_assert_eq(store.get_country_name(), "Japan", "country name saved")
	_assert_eq(store.get_continent_code(), "AS", "continent saved")
	geo.apply_geolocation_response({})
	_assert_eq(store.get_country_code(), "JP", "empty response does not hardcode fallback")
	store.wipe_all()
	_report("test_geo_service")

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
