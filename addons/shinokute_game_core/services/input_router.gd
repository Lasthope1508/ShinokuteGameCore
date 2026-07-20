class_name ShinokuteInputRouter
extends Node

signal control_scheme_changed(scheme: String)

const SCHEME_KEYBOARD_MOUSE := "keyboard_mouse"
const SCHEME_TOUCH := "touch"
const SCHEME_GAMEPAD := "gamepad"
const KEYBOARD_ACTIONS := [
	"move_left",
	"move_right",
	"move_forward",
	"move_back",
	"jump",
	"camera_left",
	"camera_right",
	"camera_up",
	"camera_down",
	"zoom_in",
	"zoom_out",
]
const WEB_CODE_TO_ACTIONS := {
	"KeyA": ["move_left"],
	"KeyD": ["move_right"],
	"KeyW": ["move_forward"],
	"KeyS": ["move_back"],
	"Space": ["jump"],
	"ArrowLeft": ["camera_left"],
	"ArrowRight": ["camera_right"],
	"ArrowUp": ["camera_up"],
	"ArrowDown": ["camera_down"],
	"Equal": ["zoom_in"],
	"NumpadAdd": ["zoom_in"],
	"Minus": ["zoom_out"],
	"NumpadSubtract": ["zoom_out"],
}

@export var touch_detection_enabled := true

var active_control_scheme := SCHEME_KEYBOARD_MOUSE
var _touch_supported := false
var _force_touch_controls_enabled := false
var _virtual_move_vector := Vector2.ZERO
var _virtual_look_delta := Vector2.ZERO
var _virtual_zoom_delta := 0.0
var _virtual_jump_pressed := false
var _web_keyboard_callback

func _ready() -> void:
	set_process_input(true)
	clear_keyboard_input_state()
	_touch_supported = _detect_touch_supported()
	if _touch_supported:
		_set_active_control_scheme(SCHEME_TOUCH)
	_install_web_keyboard_safety_bridge()

func _input(event: InputEvent) -> void:
	process_input_event(event)

func set_force_touch_controls_enabled(value: bool) -> void:
	_force_touch_controls_enabled = value
	if value:
		_set_active_control_scheme(SCHEME_TOUCH)
	elif active_control_scheme == SCHEME_TOUCH and not _touch_supported:
		_set_active_control_scheme(SCHEME_KEYBOARD_MOUSE)

func is_touch_supported() -> bool:
	return _touch_supported or _force_touch_controls_enabled

func is_touch_control_active() -> bool:
	return _force_touch_controls_enabled or active_control_scheme == SCHEME_TOUCH

func get_active_control_scheme() -> String:
	return active_control_scheme

func set_virtual_move_vector(value: Vector2) -> void:
	_virtual_move_vector = value.limit_length(1.0)
	if _virtual_move_vector.length() > 0.001:
		_set_active_control_scheme(SCHEME_TOUCH)

func get_move_vector() -> Vector2:
	if is_touch_control_active():
		return _virtual_move_vector
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	).limit_length(1.0)

func set_virtual_look_delta(value: Vector2) -> void:
	_virtual_look_delta += value
	if value.length() > 0.001:
		_set_active_control_scheme(SCHEME_TOUCH)

func has_pending_look_delta() -> bool:
	return _virtual_look_delta.length() > 0.001

func consume_look_delta() -> Vector2:
	var result := _virtual_look_delta
	_virtual_look_delta = Vector2.ZERO
	return result

func set_virtual_zoom_delta(value: float) -> void:
	_virtual_zoom_delta += value
	if absf(value) > 0.001:
		_set_active_control_scheme(SCHEME_TOUCH)

func consume_zoom_delta() -> float:
	var result := _virtual_zoom_delta
	_virtual_zoom_delta = 0.0
	return result

func press_virtual_jump() -> void:
	_virtual_jump_pressed = true
	_set_active_control_scheme(SCHEME_TOUCH)

func consume_jump_pressed() -> bool:
	var pressed := _virtual_jump_pressed
	_virtual_jump_pressed = false
	if not is_touch_control_active() and InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		return true
	return pressed

func clear_virtual_input() -> void:
	_virtual_move_vector = Vector2.ZERO
	_virtual_look_delta = Vector2.ZERO
	_virtual_zoom_delta = 0.0
	_virtual_jump_pressed = false

func clear_keyboard_input_state() -> void:
	for action in KEYBOARD_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)

func handle_web_keyboard_safety_event(args: Array) -> void:
	if args.is_empty():
		clear_keyboard_input_state()
		return
	var event_type := str(args[0])
	if event_type == "clear":
		clear_keyboard_input_state()
	elif event_type == "release" and args.size() >= 2:
		_release_web_code_actions(str(args[1]))

func process_input_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_active_control_scheme(SCHEME_TOUCH)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_set_active_control_scheme(SCHEME_GAMEPAD)
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		if not _force_touch_controls_enabled:
			_set_active_control_scheme(SCHEME_KEYBOARD_MOUSE)

func _set_active_control_scheme(value: String) -> void:
	if active_control_scheme == value:
		return
	active_control_scheme = value
	control_scheme_changed.emit(active_control_scheme)

func _detect_touch_supported() -> bool:
	if not touch_detection_enabled:
		return false
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge"):
		var result = JavaScriptBridge.eval("(navigator.maxTouchPoints || 0) > 0 || (window.matchMedia && window.matchMedia('(pointer: coarse)').matches)", true)
		return bool(result)
	return false

func _release_web_code_actions(code: String) -> void:
	if not WEB_CODE_TO_ACTIONS.has(code):
		return
	for action in WEB_CODE_TO_ACTIONS[code]:
		if InputMap.has_action(action):
			Input.action_release(action)

func _install_web_keyboard_safety_bridge() -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	_web_keyboard_callback = JavaScriptBridge.create_callback(handle_web_keyboard_safety_event)
	JavaScriptBridge.get_interface("window").shinokuteKeyboardSafetyEvent = _web_keyboard_callback
	JavaScriptBridge.eval("""
(function(){
	if (window.__shinokuteKeyboardSafetyBridgeInstalled) return;
	window.__shinokuteKeyboardSafetyBridgeInstalled = true;
	function send(payload) {
		if (typeof window.shinokuteKeyboardSafetyEvent !== 'function') return;
		window.shinokuteKeyboardSafetyEvent(payload);
	}
	window.addEventListener('keyup', function(event) {
		send(['release', event.code || '']);
	}, true);
	window.addEventListener('blur', function() {
		send(['clear']);
	}, true);
	document.addEventListener('visibilitychange', function() {
		if (document.hidden) send(['clear']);
	}, true);
	document.addEventListener('compositionstart', function() {
		send(['clear']);
	}, true);
})();
""", true)
