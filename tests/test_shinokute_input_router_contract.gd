extends SceneTree

const ROUTER_SCRIPT_PATH := "res://addons/shinokute_game_core/services/input_router.gd"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(ROUTER_SCRIPT_PATH), "Shinokute core should provide input_router.gd") and passed
	if not passed:
		_finish(false)
		return

	var router_script := load(ROUTER_SCRIPT_PATH)
	var router: Node = router_script.new()
	root.add_child(router)
	await process_frame

	var required_methods := [
		"set_force_touch_controls_enabled",
		"is_touch_control_active",
		"set_virtual_move_vector",
		"get_move_vector",
		"set_virtual_look_delta",
		"has_pending_look_delta",
		"consume_look_delta",
		"set_virtual_zoom_delta",
		"consume_zoom_delta",
		"press_virtual_jump",
		"consume_jump_pressed",
		"clear_keyboard_input_state",
		"handle_web_keyboard_safety_event",
		"process_input_event"
	]
	for method in required_methods:
		passed = _assert_true(router.has_method(method), "Input router missing method %s" % method) and passed

	if passed:
		router.set_force_touch_controls_enabled(true)
		passed = _assert_true(router.is_touch_control_active(), "Forced touch controls should make touch scheme active") and passed

		router.set_virtual_move_vector(Vector2(0.6, -0.8))
		passed = _assert_vec2_close(router.get_move_vector(), Vector2(0.6, -0.8), "Touch move vector should pass through normalized virtual joystick") and passed

		router.set_virtual_look_delta(Vector2(12.0, -3.0))
		passed = _assert_true(router.has_pending_look_delta(), "Touch look delta should be peekable before camera consumes it") and passed
		passed = _assert_vec2_close(router.consume_look_delta(), Vector2(12.0, -3.0), "Touch look delta should be consumable once") and passed
		passed = _assert_true(not router.has_pending_look_delta(), "Touch look delta peek should clear after consume") and passed
		passed = _assert_vec2_close(router.consume_look_delta(), Vector2.ZERO, "Touch look delta should reset after consume") and passed

		router.set_virtual_zoom_delta(-1.25)
		passed = _assert_float_close(router.consume_zoom_delta(), -1.25, "Touch pinch zoom delta should be consumable once") and passed
		passed = _assert_float_close(router.consume_zoom_delta(), 0.0, "Touch pinch zoom delta should reset after consume") and passed

		router.press_virtual_jump()
		passed = _assert_true(router.consume_jump_pressed(), "Virtual jump should fire once") and passed
		passed = _assert_true(not router.consume_jump_pressed(), "Virtual jump should reset after consume") and passed

		router.set_force_touch_controls_enabled(false)
		router.set_virtual_move_vector(Vector2.ZERO)
		Input.action_press("move_right")
		Input.action_press("move_forward")
		passed = _assert_vec2_close(router.get_move_vector(), Vector2(1.0, -1.0).normalized(), "Keyboard/gamepad actions should remain supported when touch is inactive") and passed
		Input.action_release("move_right")
		Input.action_release("move_forward")

		Input.action_press("move_left")
		router.clear_keyboard_input_state()
		passed = _assert_vec2_close(router.get_move_vector(), Vector2.ZERO, "Keyboard clear should release stuck move_left from Unikey/IME lost keyup") and passed
		passed = _assert_true(not Input.is_action_pressed("move_left"), "Keyboard clear should release the underlying Godot move_left action") and passed

		Input.action_press("move_left")
		router.handle_web_keyboard_safety_event(["clear"])
		passed = _assert_vec2_close(router.get_move_vector(), Vector2.ZERO, "Web IME composition/blur safety event should clear stuck movement") and passed
		passed = _assert_true(not Input.is_action_pressed("move_left"), "Web IME safety clear should release underlying move_left action") and passed

		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		router.process_input_event(touch)
		passed = _assert_true(router.is_touch_control_active(), "Screen touch should switch router to touch scheme like Roblox last input tracking") and passed

		var key := InputEventKey.new()
		key.pressed = true
		key.physical_keycode = KEY_W
		router.process_input_event(key)
		passed = _assert_true(not router.is_touch_control_active(), "Keyboard input should switch router away from touch scheme") and passed

	root.remove_child(router)
	router.free()
	await process_frame
	_finish(passed)

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String) -> bool:
	if actual.distance_to(expected) > 0.001:
		push_error("%s. Expected %s, got %s" % [message, expected, actual])
		return false
	return true

func _assert_float_close(actual: float, expected: float, message: String) -> bool:
	if absf(actual - expected) > 0.001:
		push_error("%s. Expected %s, got %s" % [message, expected, actual])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_shinokute_input_router_contract: PASS")
		quit(0)
	else:
		print("test_shinokute_input_router_contract: FAIL")
		quit(1)
