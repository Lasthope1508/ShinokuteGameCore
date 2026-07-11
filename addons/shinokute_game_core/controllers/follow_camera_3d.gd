class_name ShinokuteFollowCamera3D
extends Node3D

@export_group("Properties")
@export var target: Node

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10
@export var mouse_wheel_zoom_step = 1.5

@export_group("Rotation")
@export var rotation_speed = 120
@export var mouse_rotation_sensitivity = 0.25
@export var shift_lock_pitch_degrees := -30.0
@export var character_face_yaw_offset_degrees := 180.0
@export var input_router_path: NodePath = NodePath("")

var camera_rotation:Vector3
var zoom = 10
var right_mouse_dragging := false
var shift_lock_enabled := false
var os_mouse_capture_active := false
var last_mouse_capture_center_position := Vector2.ZERO
var _routed_look_diag_pending := false
var _last_routed_look_delta := Vector2.ZERO

@onready var camera = $Camera
@onready var input_router: Node = get_node_or_null(input_router_path)

func _ready():
	camera_rotation = rotation_degrees

func set_shift_lock_enabled(value: bool) -> void:
	shift_lock_enabled = value
	if shift_lock_enabled and target is Node3D:
		_sync_shift_lock_to_target_face(false)
		rotation_degrees = camera_rotation
	else:
		_release_os_mouse_capture()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_os_mouse_capture()

func is_os_mouse_capture_active() -> bool:
	return os_mouse_capture_active

func get_last_mouse_capture_center_position() -> Vector2:
	return last_mouse_capture_center_position

func _set_os_mouse_capture_active(value: bool) -> void:
	os_mouse_capture_active = value
	if value:
		_warp_mouse_to_viewport_center()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

func _release_os_mouse_capture() -> void:
	_set_os_mouse_capture_active(false)

func _warp_mouse_to_viewport_center() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	last_mouse_capture_center_position = viewport.get_visible_rect().size * 0.5
	viewport.warp_mouse(last_mouse_capture_center_position)

func get_target_face_yaw_degrees() -> float:
	if target is Node3D:
		return (target as Node3D).rotation_degrees.y + character_face_yaw_offset_degrees
	return camera_rotation.y

func get_shift_lock_target_yaw_degrees() -> float:
	return camera_rotation.y - character_face_yaw_offset_degrees

func _sync_shift_lock_to_target_face(preserve_continuity := true) -> void:
	var target_yaw := get_target_face_yaw_degrees()
	if preserve_continuity:
		target_yaw = _nearest_yaw_equivalent_degrees(target_yaw, camera_rotation.y)
	camera_rotation.y = target_yaw
	camera_rotation.x = shift_lock_pitch_degrees

func _nearest_yaw_equivalent_degrees(yaw_degrees: float, reference_degrees: float) -> float:
	return reference_degrees + wrapf(yaw_degrees - reference_degrees, -180.0, 180.0)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_dragging = event.pressed
			if shift_lock_enabled:
				_set_os_mouse_capture_active(event.pressed)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - mouse_wheel_zoom_step, zoom_maximum, zoom_minimum)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + mouse_wheel_zoom_step, zoom_maximum, zoom_minimum)
	elif event is InputEventMouseMotion:
		if _should_ignore_raw_mouse_look():
			return
		if shift_lock_enabled and target is Node3D:
			var yaw_delta: float = -event.relative.x * mouse_rotation_sensitivity
			if target.has_method("apply_shift_lock_look_delta_degrees"):
				target.apply_shift_lock_look_delta_degrees(yaw_delta)
			else:
				(target as Node3D).rotation_degrees.y += yaw_delta
			_sync_shift_lock_to_target_face()
			rotation_degrees = camera_rotation
		elif right_mouse_dragging:
			camera_rotation.y -= event.relative.x * mouse_rotation_sensitivity
			camera_rotation.x -= event.relative.y * mouse_rotation_sensitivity
			camera_rotation.x = clamp(camera_rotation.x, -80, -10)

func _physics_process(delta):
	self.position = self.position.lerp(target.position, delta * 4)
	var diag_rig_before := rotation_degrees
	var diag_camera_before := camera_rotation
	_routed_look_diag_pending = false
	_last_routed_look_delta = Vector2.ZERO
	handle_input(delta)
	if shift_lock_enabled and target is Node3D:
		_sync_shift_lock_to_target_face()
		rotation_degrees = camera_rotation
	else:
		rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	if _routed_look_diag_pending:
		_web_debug_log("cam frame shift=%s delta=%s cam=%s->%s rig=%s->%s touch=%s" % [
			str(shift_lock_enabled),
			_format_vec2(_last_routed_look_delta),
			_format_vec3(diag_camera_before),
			_format_vec3(camera_rotation),
			_format_vec3(diag_rig_before),
			_format_vec3(rotation_degrees),
			str(input_router != null and input_router.has_method("is_touch_control_active") and input_router.is_touch_control_active())
		])

	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)

func handle_input(delta):
	var input := Vector3.ZERO

	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")

	if not shift_lock_enabled:
		camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		camera_rotation.x = clamp(camera_rotation.x, -80, -10)
	_apply_routed_look_delta()

	zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
	_apply_routed_zoom_delta()
	zoom = clamp(zoom, zoom_maximum, zoom_minimum)

func _apply_routed_look_delta() -> void:
	if input_router == null or not input_router.has_method("consume_look_delta"):
		return
	var look_delta: Vector2 = input_router.consume_look_delta()
	if look_delta.length() <= 0.001:
		return
	_routed_look_diag_pending = true
	_last_routed_look_delta = look_delta
	var camera_before := camera_rotation
	var target_yaw_before := 0.0
	if target is Node3D:
		target_yaw_before = (target as Node3D).rotation_degrees.y
	if shift_lock_enabled and target is Node3D:
		var yaw_delta: float = -look_delta.x * mouse_rotation_sensitivity
		if target.has_method("apply_shift_lock_look_delta_degrees"):
			target.apply_shift_lock_look_delta_degrees(yaw_delta)
		else:
			(target as Node3D).rotation_degrees.y += yaw_delta
		_sync_shift_lock_to_target_face()
		rotation_degrees = camera_rotation
	else:
		camera_rotation.y -= look_delta.x * mouse_rotation_sensitivity
		camera_rotation.x -= look_delta.y * mouse_rotation_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -80, -10)
	_web_debug_log("cam look shift=%s delta=%s cam=%s->%s target_y=%.1f->%.1f" % [
		str(shift_lock_enabled),
		_format_vec2(look_delta),
		_format_vec3(camera_before),
		_format_vec3(camera_rotation),
		target_yaw_before,
		(target as Node3D).rotation_degrees.y if target is Node3D else 0.0
	])

func _apply_routed_zoom_delta() -> void:
	if input_router == null or not input_router.has_method("consume_zoom_delta"):
		return
	var zoom_delta: float = input_router.consume_zoom_delta()
	if absf(zoom_delta) <= 0.001:
		return
	zoom += zoom_delta

func _should_ignore_raw_mouse_look() -> bool:
	return input_router != null \
		and input_router.has_method("is_touch_control_active") \
		and input_router.is_touch_control_active()

func _format_vec2(value: Vector2) -> String:
	return "(%.1f,%.1f)" % [value.x, value.y]

func _format_vec3(value: Vector3) -> String:
	return "(%.1f,%.1f,%.1f)" % [value.x, value.y, value.z]

func _web_debug_log(message: String) -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("if(window.__shinokuteTouchDiagPush) window.__shinokuteTouchDiagPush(%s);" % JSON.stringify(message), true)
