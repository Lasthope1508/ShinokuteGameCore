extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var packed_scene := load(MAIN_SCENE) as PackedScene
	passed = _assert_true(packed_scene != null, "Main scene should load") and passed
	if packed_scene == null:
		_finish(false)
		return

	var scene := packed_scene.instantiate()
	_disable_audio_autoplay(scene)
	root.add_child(scene)
	await process_frame

	var bridge := scene.get_node_or_null("CandyGameCore")
	passed = _assert_true(bridge != null, "CandyGameCore should exist") and passed
	var router := scene.get_node_or_null("CandyGameCore/ShinokuteInputRouter")
	passed = _assert_true(router != null, "CandyGameCore should expose ShinokuteInputRouter child") and passed

	var player := scene.get_node_or_null("Player")
	var view := scene.get_node_or_null("View")
	passed = _assert_true(player != null and "input_router_path" in player, "Player should have input_router_path") and passed
	passed = _assert_true(view != null and "input_router_path" in view, "View should have input_router_path") and passed
	if player != null and "input_router_path" in player:
		passed = _assert_true(str(player.input_router_path).find("ShinokuteInputRouter") >= 0, "Player should read movement/jump through core router") and passed
	if view != null and "input_router_path" in view:
		passed = _assert_true(str(view.input_router_path).find("ShinokuteInputRouter") >= 0, "View should read touch look through core router, got %s" % str(view.input_router_path)) and passed

	var touch_controls := scene.get_node_or_null("HUD/MobileTouchControls")
	passed = _assert_true(touch_controls != null, "Candy HUD should own MobileTouchControls for HTML5 phones") and passed
	var mobile_touch_source := FileAccess.get_file_as_string("res://addons/shinokute_game_core/controllers/mobile_touch_controls_3d.gd")
	passed = _assert_true(mobile_touch_source.find("window.shinokutePointerEvent([type") < 0, "Web pointer bridge must call JavaScriptBridge callback with flat arguments, not one nested array payload") and passed
	passed = _assert_true(mobile_touch_source.find("window.shinokuteTouchEvent([type") < 0, "Web touch bridge must call JavaScriptBridge callback with flat arguments, not one nested array payload") and passed
	passed = _assert_true(mobile_touch_source.find("window.shinokutePointerEvent(type, event.pointerId") >= 0, "Web pointer bridge should pass pointer payload as JavaScript arguments for Godot JavaScriptBridge") and passed
	passed = _assert_true(mobile_touch_source.find("window.shinokuteTouchEvent(type, touch.identifier") >= 0, "Web touch bridge should pass touch payload as JavaScript arguments for Godot JavaScriptBridge") and passed
	if touch_controls != null:
		for method in [
			"configure",
			"set_touch_controls_visible",
			"get_move_stick_rect",
			"get_move_guard_rect",
			"get_jump_button_rect",
			"get_jump_guard_rect",
			"get_look_area_rect"
		]:
			passed = _assert_true(touch_controls.has_method(method), "MobileTouchControls missing method %s" % method) and passed
		if router != null and touch_controls.has_method("configure"):
			touch_controls.configure(router)
			touch_controls.set_touch_controls_visible(true)
			passed = _assert_true(touch_controls.visible, "Mobile controls should be showable on touch devices") and passed
			var move_rect: Rect2 = touch_controls.get_move_stick_rect()
			var jump_rect: Rect2 = touch_controls.get_jump_button_rect()
			var look_rect: Rect2 = touch_controls.get_look_area_rect()
			passed = _assert_true(move_rect.position.x < 220.0, "Move thumbstick should live on left side like Roblox mobile controls") and passed
			passed = _assert_true(jump_rect.position.x > 900.0, "Jump button should live on right side like Roblox mobile controls") and passed
			passed = _assert_true(look_rect.position.x > move_rect.end.x, "Look drag area should be separated from move thumbstick") and passed
			var move_touch := InputEventScreenTouch.new()
			move_touch.index = 1
			move_touch.pressed = true
			move_touch.position = move_rect.get_center()
			touch_controls._input(move_touch)
			var move_drag := InputEventScreenDrag.new()
			move_drag.index = 1
			move_drag.position = move_rect.get_center() + Vector2(0.0, -move_rect.size.y * 0.5)
			move_drag.relative = Vector2(0.0, -move_rect.size.y * 0.5)
			touch_controls._input(move_drag)
			passed = _assert_true(router.get_move_vector().y < -0.45, "Left thumbstick upward drag should produce forward move vector") and passed
			move_touch.pressed = false
			touch_controls._input(move_touch)
			passed = _assert_true(router.get_move_vector().length() < 0.001, "Thumbstick release should clear move vector") and passed

			var move_guard_rect: Rect2 = touch_controls.get_move_guard_rect()
			var slipped_move_position := Vector2(move_rect.end.x + 24.0, move_rect.get_center().y)
			passed = _assert_true(not move_rect.has_point(slipped_move_position), "Slipped joystick test point should sit outside the visual move rect") and passed
			passed = _assert_true(move_guard_rect.has_point(slipped_move_position), "Slipped joystick test point should stay inside the move guard rect") and passed
			var slipped_move_touch := InputEventScreenTouch.new()
			slipped_move_touch.index = 8
			slipped_move_touch.pressed = true
			slipped_move_touch.position = slipped_move_position
			touch_controls._input(slipped_move_touch)
			var slipped_move_drag := InputEventScreenDrag.new()
			slipped_move_drag.index = 8
			slipped_move_drag.position = slipped_move_position + Vector2(0.0, -move_rect.size.y * 0.45)
			slipped_move_drag.relative = Vector2(0.0, -move_rect.size.y * 0.45)
			touch_controls._input(slipped_move_drag)
			passed = _assert_true(router.get_move_vector().y < -0.35, "Slipped left thumb near joystick should stay movement, not camera look") and passed
			passed = _assert_true(router.consume_look_delta().length() < 0.001, "Slipped left thumb near joystick should not emit camera look delta") and passed
			slipped_move_touch.pressed = false
			touch_controls._input(slipped_move_touch)
			passed = _assert_true(router.get_move_vector().length() < 0.001, "Slipped joystick release should clear move vector") and passed

			var jump_touch := InputEventScreenTouch.new()
			jump_touch.index = 2
			jump_touch.pressed = true
			jump_touch.position = jump_rect.get_center()
			touch_controls._input(jump_touch)
			passed = _assert_true(router.consume_jump_pressed(), "Right jump button should fire virtual jump") and passed
			passed = _assert_true(not router.consume_jump_pressed(), "Right jump button should consume once") and passed
			jump_touch.pressed = false
			touch_controls._input(jump_touch)

			var near_jump_position := Vector2(jump_rect.position.x - 12.0, jump_rect.get_center().y)
			passed = _assert_true(not jump_rect.has_point(near_jump_position), "Jump forgiveness test point should sit just outside the visual jump rect") and passed
			passed = _assert_true(look_rect.has_point(near_jump_position), "Jump forgiveness test point should otherwise overlap the right-side look area") and passed
			var near_jump_touch := InputEventScreenTouch.new()
			near_jump_touch.index = 7
			near_jump_touch.pressed = true
			near_jump_touch.position = near_jump_position
			touch_controls._input(near_jump_touch)
			passed = _assert_true(router.consume_jump_pressed(), "Near-edge jump tap should still fire jump instead of becoming look input") and passed
			var near_jump_drag := InputEventScreenDrag.new()
			near_jump_drag.index = 7
			near_jump_drag.position = near_jump_position + Vector2(64.0, 0.0)
			near_jump_drag.relative = Vector2(64.0, 0.0)
			touch_controls._input(near_jump_drag)
			passed = _assert_true(router.consume_look_delta().length() < 0.001, "Captured jump touch drag should not rotate camera in shift-lock off mode") and passed
			near_jump_touch.pressed = false
			touch_controls._input(near_jump_touch)

			var jump_guard_rect: Rect2 = touch_controls.get_jump_guard_rect()
			var missed_jump_position := Vector2(jump_rect.position.x - 60.0, jump_rect.get_center().y)
			passed = _assert_true(not jump_rect.has_point(missed_jump_position), "Missed jump test point should sit outside the visual jump rect") and passed
			passed = _assert_true(jump_guard_rect.has_point(missed_jump_position), "Missed jump test point should stay inside the jump guard rect") and passed
			var missed_jump_touch := InputEventScreenTouch.new()
			missed_jump_touch.index = 9
			missed_jump_touch.pressed = true
			missed_jump_touch.position = missed_jump_position
			touch_controls._input(missed_jump_touch)
			passed = _assert_true(router.consume_jump_pressed(), "Missed right thumb near jump should still fire jump instead of camera look") and passed
			var missed_jump_drag := InputEventScreenDrag.new()
			missed_jump_drag.index = 9
			missed_jump_drag.position = missed_jump_position + Vector2(-72.0, 0.0)
			missed_jump_drag.relative = Vector2(-72.0, 0.0)
			touch_controls._input(missed_jump_drag)
			passed = _assert_true(router.consume_look_delta().length() < 0.001, "Missed right thumb near jump should not emit camera look delta") and passed
			missed_jump_touch.pressed = false
			touch_controls._input(missed_jump_touch)

			var look_touch := InputEventScreenTouch.new()
			look_touch.index = 3
			look_touch.pressed = true
			look_touch.position = look_rect.get_center()
			touch_controls._input(look_touch)
			var look_drag := InputEventScreenDrag.new()
			look_drag.index = 3
			look_drag.position = look_rect.get_center() + Vector2(20.0, 0.0)
			look_drag.relative = Vector2(20.0, 0.0)
			touch_controls._input(look_drag)
			passed = _assert_true(router.consume_look_delta().x > 19.0, "Right-screen touch drag should produce look delta") and passed
			look_touch.pressed = false
			touch_controls._input(look_touch)

			var held_right_look_touch := InputEventScreenTouch.new()
			held_right_look_touch.index = 10
			held_right_look_touch.pressed = true
			held_right_look_touch.position = look_rect.get_center()
			touch_controls._input(held_right_look_touch)
			var second_left_move_touch := InputEventScreenTouch.new()
			second_left_move_touch.index = 11
			second_left_move_touch.pressed = true
			second_left_move_touch.position = move_rect.get_center()
			touch_controls._input(second_left_move_touch)
			var second_left_move_drag := InputEventScreenDrag.new()
			second_left_move_drag.index = 11
			second_left_move_drag.position = move_rect.get_center() + Vector2(0.0, -move_rect.size.y * 0.5)
			second_left_move_drag.relative = Vector2(0.0, -move_rect.size.y * 0.5)
			touch_controls._input(second_left_move_drag)
			passed = _assert_true(router.get_move_vector().y < -0.45, "Holding right look first then dragging left thumbstick should move, not spin camera") and passed
			passed = _assert_true(router.consume_look_delta().length() < 0.001, "Left thumbstick drag must not emit look delta while a right look finger is held") and passed
			second_left_move_touch.pressed = false
			touch_controls._input(second_left_move_touch)
			held_right_look_touch.pressed = false
			touch_controls._input(held_right_look_touch)

			var pinch_left := InputEventScreenTouch.new()
			pinch_left.index = 4
			pinch_left.pressed = true
			pinch_left.position = look_rect.get_center() + Vector2(-24.0, 0.0)
			touch_controls._input(pinch_left)
			var pinch_right := InputEventScreenTouch.new()
			pinch_right.index = 5
			pinch_right.pressed = true
			pinch_right.position = look_rect.get_center() + Vector2(24.0, 0.0)
			touch_controls._input(pinch_right)
			var pinch_drag := InputEventScreenDrag.new()
			pinch_drag.index = 5
			pinch_drag.position = look_rect.get_center() + Vector2(96.0, 0.0)
			pinch_drag.relative = Vector2(72.0, 0.0)
			touch_controls._input(pinch_drag)
			passed = _assert_true(router.consume_zoom_delta() < -0.01, "Two-finger pinch spread should route zoom-in delta for iOS/mobile") and passed
			pinch_left.pressed = false
			touch_controls._input(pinch_left)
			pinch_right.pressed = false
			touch_controls._input(pinch_right)

			var mouse_down := InputEventMouseButton.new()
			mouse_down.button_index = MOUSE_BUTTON_LEFT
			mouse_down.pressed = true
			mouse_down.position = move_rect.get_center()
			touch_controls._input(mouse_down)
			var mouse_drag := InputEventMouseMotion.new()
			mouse_drag.position = move_rect.get_center() + Vector2(0.0, -move_rect.size.y * 0.5)
			mouse_drag.relative = Vector2(0.0, -move_rect.size.y * 0.5)
			touch_controls._input(mouse_drag)
			passed = _assert_true(router.get_move_vector().y < -0.45, "Mouse/pointer fallback should drive left thumbstick when iOS Web maps touch to mouse") and passed
			var mouse_up := InputEventMouseButton.new()
			mouse_up.button_index = MOUSE_BUTTON_LEFT
			mouse_up.pressed = false
			mouse_up.position = mouse_drag.position
			touch_controls._input(mouse_up)
			passed = _assert_true(router.get_move_vector().length() < 0.001, "Mouse/pointer fallback release should clear move vector") and passed

			var mouse_right_down := InputEventMouseButton.new()
			mouse_right_down.button_index = MOUSE_BUTTON_LEFT
			mouse_right_down.pressed = true
			mouse_right_down.position = look_rect.get_center()
			touch_controls._input(mouse_right_down)
			var mouse_right_drag := InputEventMouseMotion.new()
			mouse_right_drag.position = look_rect.get_center() + Vector2(96.0, 0.0)
			mouse_right_drag.relative = Vector2(96.0, 0.0)
			touch_controls._input(mouse_right_drag)
			passed = _assert_true(router.consume_look_delta().length() < 0.001, "Mouse/pointer fallback must not emit look delta because mobile Web cannot assign multiple mouse motions to the correct finger") and passed
			mouse_right_down.pressed = false
			touch_controls._input(mouse_right_down)

			passed = _assert_true(touch_controls.has_method("handle_web_pointer_event"), "Mobile controls should expose a JS pointer bridge so iOS Web multi-touch keeps pointer ownership") and passed
			if touch_controls.has_method("handle_web_pointer_event"):
				touch_controls.handle_web_pointer_event(["down", 101, look_rect.get_center().x, look_rect.get_center().y])
				touch_controls.handle_web_pointer_event(["move", 101, look_rect.get_center().x + 44.0, look_rect.get_center().y])
				passed = _assert_true(router.consume_look_delta().x > 40.0, "Single right-hand JS pointer drag should rotate camera through routed look") and passed
				touch_controls.handle_web_pointer_event(["up", 101, look_rect.get_center().x + 44.0, look_rect.get_center().y])
				passed = _assert_true(touch_controls.has_method("handle_web_touch_event"), "Mobile controls should expose a JS Touch Events bridge fallback for iOS Safari when Pointer Events do not drive right-look") and passed
				if touch_controls.has_method("handle_web_touch_event"):
					touch_controls.handle_web_touch_event(["start", 801, look_rect.get_center().x, look_rect.get_center().y])
					touch_controls.handle_web_touch_event(["move", 801, look_rect.get_center().x + 50.0, look_rect.get_center().y])
					passed = _assert_true(router.consume_look_delta().x > 46.0, "Single right-hand JS touch fallback drag should rotate camera through routed look on iOS Safari") and passed
					touch_controls.handle_web_touch_event(["end", 801, look_rect.get_center().x + 50.0, look_rect.get_center().y])
					touch_controls.handle_web_pointer_event([["down", 901, look_rect.get_center().x, look_rect.get_center().y]])
					touch_controls.handle_web_pointer_event([["move", 901, look_rect.get_center().x + 54.0, look_rect.get_center().y]])
					passed = _assert_true(router.consume_look_delta().x > 50.0, "Godot JavaScriptBridge callback wraps JS arguments, so nested pointer payload should still rotate right-look") and passed
					touch_controls.handle_web_pointer_event([["up", 901, look_rect.get_center().x + 54.0, look_rect.get_center().y]])
					touch_controls.handle_web_touch_event([["start", 902, look_rect.get_center().x, look_rect.get_center().y]])
					touch_controls.handle_web_touch_event([["move", 902, look_rect.get_center().x + 58.0, look_rect.get_center().y]])
					passed = _assert_true(router.consume_look_delta().x > 54.0, "Godot JavaScriptBridge callback wraps JS arguments, so nested touch payload should still rotate right-look") and passed
					touch_controls.handle_web_touch_event([["end", 902, look_rect.get_center().x + 58.0, look_rect.get_center().y]])

				touch_controls.handle_web_pointer_event(["down", 201, look_rect.get_center().x, look_rect.get_center().y])
				touch_controls.handle_web_pointer_event(["down", 202, move_rect.get_center().x, move_rect.get_center().y])
				touch_controls.handle_web_pointer_event(["move", 202, move_rect.get_center().x, move_rect.get_center().y - move_rect.size.y * 0.5])
				passed = _assert_true(router.get_move_vector().y < -0.45, "JS pointer bridge should let left thumbstick move while right look finger is held") and passed
				passed = _assert_true(router.consume_look_delta().length() < 0.001, "JS pointer bridge must not convert left pointer movement into right-hand camera look") and passed
				touch_controls.handle_web_pointer_event(["move", 201, look_rect.get_center().x + 36.0, look_rect.get_center().y])
				passed = _assert_true(router.consume_look_delta().x > 32.0, "JS pointer bridge should still let held right finger rotate camera while left thumbstick is active") and passed
				touch_controls.handle_web_pointer_event(["up", 202, move_rect.get_center().x, move_rect.get_center().y - move_rect.size.y * 0.5])
				touch_controls.handle_web_pointer_event(["up", 201, look_rect.get_center().x + 36.0, look_rect.get_center().y])

				var hybrid_look_position := look_rect.get_center() + Vector2(80.0, 0.0)
				var hybrid_screen_touch := InputEventScreenTouch.new()
				hybrid_screen_touch.index = 301
				hybrid_screen_touch.pressed = true
				hybrid_screen_touch.position = hybrid_look_position
				touch_controls._input(hybrid_screen_touch)
				touch_controls.handle_web_pointer_event(["down", 401, hybrid_look_position.x, hybrid_look_position.y])
				touch_controls.handle_web_pointer_event(["move", 401, hybrid_look_position.x + 52.0, hybrid_look_position.y])
				passed = _assert_true(router.consume_look_delta().x > 48.0, "Hybrid iOS touch+JS pointer duplicate for one physical right finger should stay one look pointer, not become pinch") and passed
				passed = _assert_true(absf(router.consume_zoom_delta()) < 0.001, "Hybrid duplicate of one physical right finger must not emit pinch zoom") and passed
				touch_controls.handle_web_pointer_event(["up", 401, hybrid_look_position.x + 52.0, hybrid_look_position.y])
				hybrid_screen_touch.pressed = false
				touch_controls._input(hybrid_screen_touch)

				var hybrid_pinch_left := look_rect.get_center() + Vector2(-48.0, -32.0)
				var hybrid_pinch_right := look_rect.get_center() + Vector2(48.0, -32.0)
				var hybrid_screen_left := InputEventScreenTouch.new()
				hybrid_screen_left.index = 302
				hybrid_screen_left.pressed = true
				hybrid_screen_left.position = hybrid_pinch_left
				touch_controls._input(hybrid_screen_left)
				touch_controls.handle_web_pointer_event(["down", 402, hybrid_pinch_left.x, hybrid_pinch_left.y])
				var hybrid_screen_right := InputEventScreenTouch.new()
				hybrid_screen_right.index = 303
				hybrid_screen_right.pressed = true
				hybrid_screen_right.position = hybrid_pinch_right
				touch_controls._input(hybrid_screen_right)
				touch_controls.handle_web_pointer_event(["down", 403, hybrid_pinch_right.x, hybrid_pinch_right.y])
				touch_controls.handle_web_pointer_event(["move", 403, hybrid_pinch_right.x + 72.0, hybrid_pinch_right.y])
				passed = _assert_true(router.consume_look_delta().length() < 0.001, "Hybrid duplicated two-finger gesture should not spin camera when one finger moves") and passed
				passed = _assert_true(router.consume_zoom_delta() < -0.01, "Hybrid duplicated two-finger gesture should remain pinch zoom") and passed
				touch_controls.handle_web_pointer_event(["up", 403, hybrid_pinch_right.x + 72.0, hybrid_pinch_right.y])
				hybrid_screen_right.pressed = false
				touch_controls._input(hybrid_screen_right)
				touch_controls.handle_web_pointer_event(["up", 402, hybrid_pinch_left.x, hybrid_pinch_left.y])
				hybrid_screen_left.pressed = false
				touch_controls._input(hybrid_screen_left)

			var portrait_size: Vector2i = Vector2i(430, 932)
			var landscape_size: Vector2i = Vector2i(932, 430)
			root.size = portrait_size
			await process_frame
			root.size = landscape_size
			await process_frame
			var expected_landscape_size: Vector2 = root.get_visible_rect().size
			var control_rect: Rect2 = touch_controls.get_global_rect()
			passed = _assert_true(control_rect.position.distance_to(Vector2.ZERO) < 0.01, "Mobile controls should stay pinned to viewport origin after portrait-to-landscape rotate, got %s" % control_rect) and passed
			passed = _assert_true(control_rect.size.distance_to(expected_landscape_size) < 0.01, "Mobile controls should resize to landscape visible rect after rotate, got %s expected %s" % [control_rect.size, expected_landscape_size]) and passed
			var rotated_move_rect: Rect2 = touch_controls.get_move_stick_rect()
			var rotated_jump_rect: Rect2 = touch_controls.get_jump_button_rect()
			passed = _assert_true(control_rect.encloses(rotated_move_rect), "Move thumbstick drawn rect should remain inside touch control rect after rotate, got %s inside %s" % [rotated_move_rect, control_rect]) and passed
			passed = _assert_true(control_rect.encloses(rotated_jump_rect), "Jump button drawn rect should remain inside touch control rect after rotate, got %s inside %s" % [rotated_jump_rect, control_rect]) and passed
			var scaled_css_canvas_size := expected_landscape_size * 0.5
			var scaled_css_move_center := Vector2(
				rotated_move_rect.get_center().x * scaled_css_canvas_size.x / expected_landscape_size.x,
				rotated_move_rect.get_center().y * scaled_css_canvas_size.y / expected_landscape_size.y
			)
			var scaled_css_move_drag := Vector2(
				rotated_move_rect.get_center().x * scaled_css_canvas_size.x / expected_landscape_size.x,
				(rotated_move_rect.get_center().y - rotated_move_rect.size.y * 0.5) * scaled_css_canvas_size.y / expected_landscape_size.y
			)
			touch_controls.handle_web_pointer_event(["down", 701, scaled_css_move_center.x, scaled_css_move_center.y, scaled_css_canvas_size.x, scaled_css_canvas_size.y])
			touch_controls.handle_web_pointer_event(["move", 701, scaled_css_move_drag.x, scaled_css_move_drag.y, scaled_css_canvas_size.x, scaled_css_canvas_size.y])
			passed = _assert_true(router.get_move_vector().y < -0.45, "Web pointer bridge must normalize CSS canvas coordinates to the Godot viewport after iOS rotate/stretch") and passed
			touch_controls.handle_web_pointer_event(["up", 701, scaled_css_move_drag.x, scaled_css_move_drag.y, scaled_css_canvas_size.x, scaled_css_canvas_size.y])
			passed = _assert_true(router.get_move_vector().length() < 0.001, "Scaled Web pointer release should clear move vector after iOS rotate/stretch") and passed
			var rotated_jump_touch := InputEventScreenTouch.new()
			rotated_jump_touch.index = 6
			rotated_jump_touch.pressed = true
			rotated_jump_touch.position = rotated_jump_rect.get_center()
			touch_controls._input(rotated_jump_touch)
			passed = _assert_true(router.consume_jump_pressed(), "Tap at rotated jump symbol center should still hit jump action") and passed

	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish(passed)

func _disable_audio_autoplay(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.autoplay = false
		player.stop()
		player.stream = null
	for child in node.get_children():
		_disable_audio_autoplay(child)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("test_candy_mobile_touch_controls_contract: PASS")
		quit(0)
	else:
		print("test_candy_mobile_touch_controls_contract: FAIL")
		quit(1)
