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

	var view := scene.get_node_or_null("View")
	passed = _assert_true(view != null, "View camera rig should exist") and passed
	if view != null:
		passed = _assert_true(absf(view.character_face_yaw_offset_degrees - 180.0) < 0.01, "CHR077 shift lock camera offset should default behind the Godot visual face axis") and passed

		var initial_zoom: float = view.zoom
		var wheel_up := InputEventMouseButton.new()
		wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel_up.pressed = true
		view._input(wheel_up)
		passed = _assert_true(view.zoom < initial_zoom, "Mouse wheel up should zoom in") and passed

		var after_zoom_in: float = view.zoom
		var wheel_down := InputEventMouseButton.new()
		wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel_down.pressed = true
		view._input(wheel_down)
		passed = _assert_true(view.zoom > after_zoom_in, "Mouse wheel down should zoom out") and passed

		var router := scene.get_node_or_null("CandyGameCore/ShinokuteInputRouter")
		passed = _assert_true(router != null and router.has_method("set_virtual_zoom_delta"), "View should receive mobile pinch zoom through ShinokuteInputRouter") and passed
		if router != null and router.has_method("set_virtual_zoom_delta"):
			var before_pinch_zoom: float = view.zoom
			router.set_virtual_zoom_delta(-1.0)
			view.handle_input(0.016)
			passed = _assert_true(view.zoom < before_pinch_zoom, "Mobile pinch zoom-in delta should reduce camera zoom like mouse wheel up") and passed
			var key_scheme_restore := InputEventKey.new()
			key_scheme_restore.pressed = true
			key_scheme_restore.physical_keycode = KEY_W
			router.process_input_event(key_scheme_restore)

		var initial_rotation: Vector3 = view.camera_rotation
		view.set_shift_lock_enabled(false)
		passed = _assert_true(not view.is_os_mouse_capture_active(), "Shift lock off should keep mouse cursor visible/free") and passed
		var right_down := InputEventMouseButton.new()
		right_down.button_index = MOUSE_BUTTON_RIGHT
		right_down.pressed = true
		view._input(right_down)
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(24.0, -16.0)
		view._input(motion)
		var right_up := InputEventMouseButton.new()
		right_up.button_index = MOUSE_BUTTON_RIGHT
		right_up.pressed = false
		view._input(right_up)
		passed = _assert_true(view.camera_rotation != initial_rotation, "Right mouse drag should rotate camera") and passed

		var player := scene.get_node("Player")
		if router != null and router.has_method("set_virtual_look_delta"):
			router.set_force_touch_controls_enabled(true)
			router.clear_virtual_input()
			view.set_shift_lock_enabled(false)
			player.rotation_degrees.y = 45.0
			player.rotation_direction = deg_to_rad(45.0)
			view.camera_rotation = Vector3(-35.0, 120.0, 0.0)
			view.rotation_degrees = view.camera_rotation
			var free_touch_camera_rotation: Vector3 = view.camera_rotation
			var free_touch_rig_rotation: Vector3 = view.rotation_degrees
			var free_touch_player_yaw: float = player.rotation_degrees.y
			router.set_virtual_look_delta(Vector2(32.0, 0.0))
			view._physics_process(0.016)
			passed = _assert_true(absf(view.camera_rotation.y - free_touch_camera_rotation.y) > 0.01, "Shift lock off mobile right-hand look should update free camera yaw") and passed
			passed = _assert_true(absf(view.rotation_degrees.y - free_touch_rig_rotation.y) > 0.01, "Shift lock off mobile right-hand look should move the visible camera rig in the same physics frame") and passed
			passed = _assert_true(absf(player.rotation_degrees.y - free_touch_player_yaw) < 0.01, "Shift lock off mobile right-hand look should not rotate character yaw directly") and passed
			router.set_force_touch_controls_enabled(false)
			router.clear_virtual_input()

		player.rotation_degrees.y = 90.0
		view.character_face_yaw_offset_degrees = 180.0
		view.camera_rotation = Vector3(-35.0, 25.0, 0.0)
		view.rotation_degrees = view.camera_rotation
		view.set_shift_lock_enabled(true)
		passed = _assert_true(not view.is_os_mouse_capture_active(), "Shift lock enable should not capture the OS mouse") and passed
		passed = _assert_true(absf(view.camera_rotation.y - 270.0) < 0.01, "Shift lock should align camera behind CHR077 visual facing when enabled") and passed
		passed = _assert_true(absf(view.rotation_degrees.y - 270.0) < 0.01, "Shift lock should snap the camera rig behind CHR077 visual facing immediately") and passed
		passed = _assert_true(absf(view.camera_rotation.x - view.shift_lock_pitch_degrees) < 0.01, "Shift lock should enter the over-back camera pitch") and passed
		passed = _assert_true(_camera_is_behind_character_face(view, player), "Shift lock camera should sit behind the actual character face direction") and passed

		player.rotation_degrees.y = 90.0
		player.rotation_direction = deg_to_rad(90.0)
		view._physics_process(0.016)
		var shift_mouse_rotation: Vector3 = view.camera_rotation
		var shift_mouse_yaw: float = player.rotation_degrees.y
		var shift_right_down := InputEventMouseButton.new()
		shift_right_down.button_index = MOUSE_BUTTON_RIGHT
		shift_right_down.pressed = true
		view._input(shift_right_down)
		passed = _assert_true(view.is_os_mouse_capture_active(), "Shift lock right mouse down inside game window should lock the mouse to center") and passed
		passed = _assert_true(view.has_method("get_last_mouse_capture_center_position"), "Shift lock view should expose the last mouse center-lock position for contract validation") and passed
		if view.has_method("get_last_mouse_capture_center_position"):
			var expected_mouse_center: Vector2 = view.get_viewport().get_visible_rect().size * 0.5
			passed = _assert_true(view.get_last_mouse_capture_center_position().distance_to(expected_mouse_center) < 0.01, "Shift lock right mouse capture should immediately warp and lock the pointer at the center of the game viewport") and passed
		var shift_motion := InputEventMouseMotion.new()
		shift_motion.relative = Vector2(20.0, 0.0)
		view._input(shift_motion)
		passed = _assert_true(_yaw_delta(player.rotation_degrees.y, shift_mouse_yaw) < 0.0, "Shift lock mouse movement right should turn character right without requiring right mouse button") and passed
		passed = _assert_true(_yaw_close(rad_to_deg(player.rotation_direction), player.rotation_degrees.y), "Shift lock mouse movement should update internal facing direction") and passed
		passed = _assert_true(_yaw_delta(view.camera_rotation.y, shift_mouse_rotation.y) != 0.0, "Shift lock mouse movement should rotate the locked camera with the character") and passed
		passed = _assert_true(_yaw_close(view.camera_rotation.y, player.rotation_degrees.y + 180.0), "Shift lock mouse movement should keep camera behind the new character facing") and passed

		var shift_right_up := InputEventMouseButton.new()
		shift_right_up.button_index = MOUSE_BUTTON_RIGHT
		shift_right_up.pressed = false
		view._input(shift_right_up)
		passed = _assert_true(not view.is_os_mouse_capture_active(), "Shift lock right mouse release should release OS mouse capture") and passed

		view._input(shift_right_down)
		view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		passed = _assert_true(not view.is_os_mouse_capture_active(), "Shift lock should keep OS mouse capture released when the game loses focus") and passed

		view.camera_rotation = Vector3(-35.0, 25.0, 0.0)
		view.rotation_degrees = view.camera_rotation
		player.rotation_degrees.y = 70.0
		view._physics_process(0.016)
		passed = _assert_true(_yaw_close(view.camera_rotation.y, 250.0), "Shift lock camera yaw should follow behind CHR077 character facing") and passed
		passed = _assert_true(absf(player.rotation_degrees.y - 70.0) < 0.01, "Shift lock should not rotate character from camera yaw") and passed

		player.rotation_degrees.y = 90.0
		player.rotation_direction = deg_to_rad(90.0)
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		Input.action_press("move_forward")
		player._physics_process(0.016)
		Input.action_release("move_forward")
		passed = _assert_true(absf(player.rotation_degrees.y - 90.0) < 8.0, "Shift lock forward input should drive character facing") and passed
		view._physics_process(0.016)
		passed = _assert_true(absf(_yaw_delta(view.camera_rotation.y, player.rotation_degrees.y + 180.0)) < 8.0, "Shift lock camera should follow behind input-driven CHR077 character facing") and passed

		player.rotation_degrees.y = 90.0
		player.rotation_direction = deg_to_rad(90.0)
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		view.camera_rotation = Vector3(view.shift_lock_pitch_degrees, 270.0, 0.0)
		view.rotation_degrees = view.camera_rotation
		Input.action_press("move_back")
		player._physics_process(0.016)
		Input.action_release("move_back")
		passed = _assert_true(absf(player.rotation_degrees.y - 90.0) < 0.01, "Shift lock move_back should move backward without flipping character facing") and passed

		player.rotation_degrees.y = 135.0
		player.rotation_direction = 0.0
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		view.rotation_degrees = Vector3(view.shift_lock_pitch_degrees, 20.0, 0.0)
		view.camera_rotation = Vector3(view.shift_lock_pitch_degrees, 315.0, 0.0)
		Input.action_press("move_back")
		player._physics_process(0.016)
		view._physics_process(0.016)
		Input.action_release("move_back")
		passed = _assert_true(absf(player.rotation_degrees.y - 135.0) < 0.01, "Shift lock move_back should preserve current character facing even if cached rotation direction is stale") and passed
		passed = _assert_true(absf(player.rotation_direction - 0.0) < 0.01, "Shift lock move_back should not rewrite internal facing direction") and passed
		passed = _assert_true(absf(view.camera_rotation.y - 315.0) < 0.01, "Shift lock move_back should not reset camera yaw from stale rotation direction") and passed
		passed = _assert_true(_movement_is_linear_backpedal(player), "Shift lock move_back should move linearly backward from character facing, not from camera lerp yaw") and passed

		player._physics_process(0.016)
		view._physics_process(0.016)
		passed = _assert_true(absf(player.rotation_degrees.y - 135.0) < 0.01, "Shift lock move_back release should not rotate from residual backward velocity") and passed
		passed = _assert_true(absf(view.camera_rotation.y - 315.0) < 0.01, "Shift lock move_back release should keep camera behind current facing") and passed

		player.rotation_degrees.y = 180.0
		player.rotation_direction = deg_to_rad(180.0)
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		view.camera_rotation = Vector3(view.shift_lock_pitch_degrees, 0.0, 0.0)
		view.rotation_degrees = view.camera_rotation
		if router != null and router.has_method("set_virtual_move_vector") and router.has_method("set_virtual_look_delta"):
			var right_hand_look := Vector2(20.0, 0.0)
			var expected_yaw_after_right_hand_look: float = 180.0 - right_hand_look.x * view.mouse_rotation_sensitivity
			router.set_force_touch_controls_enabled(true)
			router.set_virtual_move_vector(Vector2(0.65, -1.0))
			router.set_virtual_look_delta(right_hand_look)
			player._physics_process(0.016)
			view._physics_process(0.016)
			router.set_virtual_move_vector(Vector2.ZERO)
			passed = _assert_true(_yaw_close(player.rotation_degrees.y, expected_yaw_after_right_hand_look), "Shift lock mobile right-hand look while moving should be the only yaw source; left stick x must not add camera reset/spin") and passed
			passed = _assert_true(_yaw_close(rad_to_deg(player.rotation_direction), expected_yaw_after_right_hand_look), "Shift lock right-hand look should keep internal facing equal to visual yaw while moving") and passed
			passed = _assert_true(_yaw_close(view.camera_rotation.y, expected_yaw_after_right_hand_look + 180.0), "Shift lock camera should stay behind right-hand look yaw while moving") and passed
			passed = _assert_true(_yaw_close(view.rotation_degrees.y, view.camera_rotation.y), "Shift lock camera rig should not lag or loop after simultaneous move/look") and passed
			player.rotation_degrees.y = 180.0
			player.rotation_direction = deg_to_rad(180.0)
			view.camera_rotation = Vector3(view.shift_lock_pitch_degrees, 0.0, 0.0)
			view.rotation_degrees = view.camera_rotation
			view.set_shift_lock_enabled(true)
			var touch_mode_raw_mouse_yaw: float = player.rotation_degrees.y
			var touch_mode_raw_mouse_camera_yaw: float = view.camera_rotation.y
			var touch_mode_raw_mouse_motion := InputEventMouseMotion.new()
			touch_mode_raw_mouse_motion.relative = Vector2(180.0, 0.0)
			view._input(touch_mode_raw_mouse_motion)
			passed = _assert_true(_yaw_close(player.rotation_degrees.y, touch_mode_raw_mouse_yaw), "Shift lock touch mode must ignore raw MouseMotion so iOS pointer fallback cannot spin the character/camera outside the touch router") and passed
			passed = _assert_true(_yaw_close(view.camera_rotation.y, touch_mode_raw_mouse_camera_yaw), "Shift lock touch mode must ignore raw MouseMotion camera yaw and only accept routed touch look delta") and passed
			router.set_force_touch_controls_enabled(false)
			player._physics_process(0.016)
			player._physics_process(0.016)

			router.set_force_touch_controls_enabled(true)
			player.rotation_degrees.y = 179.0
			player.rotation_direction = deg_to_rad(179.0)
			player.velocity = Vector3.ZERO
			player.movement_velocity = Vector3.ZERO
			player.gravity = -1.0
			player.jump_single = false
			player.jump_double = true
			view.camera_rotation = Vector3(view.shift_lock_pitch_degrees, 359.0, 0.0)
			view.rotation_degrees = view.camera_rotation
			var airborne_turn_camera_yaw: float = view.camera_rotation.y
			router.set_virtual_move_vector(Vector2(-1.0, 0.0))
			player._physics_process(0.016)
			view._physics_process(0.016)
			passed = _assert_true(absf(view.camera_rotation.y - airborne_turn_camera_yaw) < 16.0, "Shift lock airborne left-turn should keep raw camera yaw continuous near 180-degree wrap") and passed
			var airborne_look_camera_yaw: float = view.camera_rotation.y
			router.set_virtual_look_delta(Vector2(-32.0, 0.0))
			player._physics_process(0.016)
			view._physics_process(0.016)
			router.set_virtual_move_vector(Vector2.ZERO)
			passed = _assert_true(absf(view.camera_rotation.y - airborne_look_camera_yaw) < 16.0, "Shift lock airborne right-hand look after left air-turn should not reset camera yaw across 360 degrees") and passed
			passed = _assert_true(_yaw_close(view.camera_rotation.y, player.rotation_degrees.y + 180.0), "Shift lock airborne camera should remain behind character after air-turn plus right-hand look") and passed
			router.set_force_touch_controls_enabled(false)
			player._shift_lock_look_control_frames = 0

		player.rotation_degrees.y = 180.0
		player.rotation_direction = deg_to_rad(180.0)
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		view.rotation_degrees = Vector3(view.shift_lock_pitch_degrees, 90.0, 0.0)
		view.camera_rotation = view.rotation_degrees
		var left_turn_start_face := _horizontal(player.global_transform.basis.z)
		var left_turn_target := _horizontal(player.global_transform.basis.x)
		Input.action_press("move_left")
		player._physics_process(0.016)
		view._physics_process(0.016)
		Input.action_release("move_left")
		passed = _assert_true(_yaw_delta(player.rotation_degrees.y, 180.0) > 0.0, "Shift lock move_left should turn character left in the player-facing camera view") and passed
		passed = _assert_true(_turned_toward(player.global_transform.basis.z, left_turn_start_face, left_turn_target), "Shift lock move_left should turn the actual visual face toward player-facing left") and passed
		passed = _assert_true(_yaw_close(rad_to_deg(player.rotation_direction), player.rotation_degrees.y), "Shift lock move_left should update internal facing direction") and passed
		passed = _assert_true(_yaw_close(view.camera_rotation.y, player.rotation_degrees.y + 180.0), "Shift lock move_left should rotate camera behind character facing") and passed
		passed = _assert_true(_yaw_close(view.rotation_degrees.y, view.camera_rotation.y), "Shift lock move_left should lock the actual camera rig behind character without yaw lerp lag") and passed
		passed = _assert_true(_movement_is_zero(player), "Shift lock move_left should turn in place without strafing") and passed

		player.rotation_degrees.y = 180.0
		player.rotation_direction = deg_to_rad(180.0)
		player.velocity = Vector3.ZERO
		player.movement_velocity = Vector3.ZERO
		view.rotation_degrees = Vector3(view.shift_lock_pitch_degrees, 90.0, 0.0)
		view.camera_rotation = view.rotation_degrees
		var right_turn_start_face := _horizontal(player.global_transform.basis.z)
		var right_turn_target := _horizontal(-player.global_transform.basis.x)
		Input.action_press("move_right")
		player._physics_process(0.016)
		view._physics_process(0.016)
		Input.action_release("move_right")
		passed = _assert_true(_yaw_delta(player.rotation_degrees.y, 180.0) < 0.0, "Shift lock move_right should turn character right in the player-facing camera view") and passed
		passed = _assert_true(_turned_toward(player.global_transform.basis.z, right_turn_start_face, right_turn_target), "Shift lock move_right should turn the actual visual face toward player-facing right") and passed
		passed = _assert_true(_yaw_close(rad_to_deg(player.rotation_direction), player.rotation_degrees.y), "Shift lock move_right should update internal facing direction") and passed
		passed = _assert_true(_yaw_close(view.camera_rotation.y, player.rotation_degrees.y + 180.0), "Shift lock move_right should rotate camera behind character facing") and passed
		passed = _assert_true(_yaw_close(view.rotation_degrees.y, view.camera_rotation.y), "Shift lock move_right should lock the actual camera rig behind character without yaw lerp lag") and passed
		passed = _assert_true(_movement_is_zero(player), "Shift lock move_right should turn in place without strafing") and passed

		view.character_face_yaw_offset_degrees = 90.0
		player.rotation_degrees.y = 10.0
		view.camera_rotation = Vector3(-10.0, 0.0, 0.0)
		view.rotation_degrees = view.camera_rotation
		view.set_shift_lock_enabled(true)
		passed = _assert_true(absf(view.camera_rotation.y - 100.0) < 0.01, "Shift lock should use configured mesh face yaw offset") and passed
		view.camera_rotation.y = 140.0
		view._physics_process(0.016)
		passed = _assert_true(absf(player.rotation_degrees.y - 10.0) < 0.01, "Shift lock offset camera sync should not rotate the controller") and passed
		passed = _assert_true(absf(view.camera_rotation.y - 100.0) < 0.01, "Shift lock offset camera sync should keep following visual face yaw") and passed

	_disable_audio_autoplay(scene)
	if view != null and view.has_method("set_shift_lock_enabled"):
		view.set_shift_lock_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish(passed)

func _camera_is_behind_character_face(view: Node3D, player: Node3D) -> bool:
	var camera := view.get_node("Camera") as Camera3D
	var face_forward := player.global_transform.basis.z.normalized()
	var camera_direction := (camera.global_position - player.global_position).normalized()
	return camera_direction.dot(face_forward) < -0.65 and camera.global_position.y > player.global_position.y

func _movement_is_linear_backpedal(player: Node3D) -> bool:
	var character := player as CharacterBody3D
	var movement := Vector3(character.movement_velocity.x, 0.0, character.movement_velocity.z)
	if movement.length() <= 0.0001:
		return false
	var face_backward := -player.global_transform.basis.z.normalized()
	return movement.normalized().dot(face_backward) > 0.95

func _movement_is_zero(player: Node3D) -> bool:
	var character := player as CharacterBody3D
	var movement := Vector3(character.movement_velocity.x, 0.0, character.movement_velocity.z)
	return movement.length() <= 0.0001

func _horizontal(vector: Vector3) -> Vector3:
	var flat := Vector3(vector.x, 0.0, vector.z)
	if flat.length() <= 0.0001:
		return Vector3.ZERO
	return flat.normalized()

func _turned_toward(actual_face: Vector3, start_face: Vector3, target_side: Vector3) -> bool:
	var actual := _horizontal(actual_face)
	return actual.dot(target_side) > start_face.dot(target_side) + 0.001

func _yaw_close(actual: float, expected: float) -> bool:
	return absf(wrapf(actual - expected, -180.0, 180.0)) < 0.01

func _yaw_delta(actual: float, expected: float) -> float:
	return wrapf(actual - expected, -180.0, 180.0)

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
		print("test_camera_mouse_input_contract: PASS")
		quit(0)
	else:
		print("test_camera_mouse_input_contract: FAIL")
		quit(1)
