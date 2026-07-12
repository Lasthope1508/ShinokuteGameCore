extends SceneTree

const CORE_ROUTE_GENERATOR := "res://addons/shinokute_game_core/core/obby_route_generator_3d.gd"
const CANDY_ROUTE_WRAPPER := "res://scripts/obby_route_generator.gd"
const WEB_EXPORT_PRESETS := "res://export_presets.cfg"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(CORE_ROUTE_GENERATOR), "3D obby route/difficulty algorithm should live in Shinokute core") and passed
	passed = _assert_file_contains(CORE_ROUTE_GENERATOR, "class_name ShinokuteObbyRouteGenerator3D", "Core route generator should expose a reusable class") and passed
	passed = _assert_file_contains(CORE_ROUTE_GENERATOR, "shinokute_3d_obby_curve_v1", "Core route generator should own canonical route id") and passed
	passed = _assert_file_not_contains(CORE_ROUTE_GENERATOR, "Candy", "Core route generator must not contain Candy game names") and passed
	passed = _assert_file_not_contains(CORE_ROUTE_GENERATOR, "candy_", "Core route generator must not contain Candy route ids") and passed
	passed = _assert_file_contains(CANDY_ROUTE_WRAPPER, CORE_ROUTE_GENERATOR, "Candy route wrapper should pull canonical algorithm from core") and passed
	passed = _assert_file_not_contains(CANDY_ROUTE_WRAPPER, "RandomNumberGenerator.new", "Candy route wrapper must not own route random/path algorithm") and passed
	passed = _assert_file_not_contains(CANDY_ROUTE_WRAPPER, "sin(t * TAU", "Candy route wrapper must not own 3D route curve math") and passed
	passed = _assert_file_contains(WEB_EXPORT_PRESETS, CORE_ROUTE_GENERATOR, "Selected-resource exports should include core 3D obby route generator") and passed
	_finish(passed)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

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

func _finish(passed: bool) -> void:
	if passed:
		print("test_shinokute_3d_obby_progression_core_contract: PASS")
		quit(0)
	else:
		print("test_shinokute_3d_obby_progression_core_contract: FAIL")
		quit(1)
