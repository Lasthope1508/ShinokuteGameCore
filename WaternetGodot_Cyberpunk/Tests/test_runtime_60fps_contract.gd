extends SceneTree

func _init() -> void:
	var passed := true
	passed = passed and _assert_equal(int(ProjectSettings.get_setting("application/run/max_fps", 0)), 60, "Runtime max FPS should be locked to 60")
	passed = passed and _assert_equal(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0)), 60, "Physics tick rate should stay at 60")

	if passed:
		print("test_runtime_60fps_contract: PASS")
		quit(0)
	else:
		print("test_runtime_60fps_contract: FAIL")
		quit(1)

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
