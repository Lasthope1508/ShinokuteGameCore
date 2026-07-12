class_name ShinokuteMobileTouchControls3D
extends Control

const MOUSE_POINTER_INDEX := -100000
const MOVE_GUARD_PADDING := 72.0
const JUMP_GUARD_PADDING := 84.0

@export var input_router_path: NodePath = NodePath("")
@export var theme_config: Resource
@export var look_sensitivity := 1.0
@export var pinch_zoom_sensitivity := 0.015

var _router: Node
var _manual_visibility := false
var _move_touch_index := -1
var _look_touch_index := -1
var _move_touch_start := Vector2.ZERO
var _move_touch_current := Vector2.ZERO
var _jump_touch_indices := []
var _active_pointer_positions := {}
var _pinch_touch_indices := []
var _pinch_last_distance := 0.0
var _web_pointer_callback
var _web_touch_callback
var _web_pointer_mode_active := false
var _web_pointer_last_positions := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	_sync_to_viewport()
	_router = get_node_or_null(input_router_path)
	if _router != null and _router.has_signal("control_scheme_changed"):
		_router.control_scheme_changed.connect(func(_scheme: String): _refresh_visibility())
	var viewport := get_viewport()
	if viewport != null and viewport.has_signal("size_changed") and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_install_web_pointer_bridge()
	_refresh_visibility()

func configure(input_router: Node) -> void:
	_router = input_router
	_refresh_visibility()

func set_touch_controls_visible(value: bool) -> void:
	_manual_visibility = true
	visible = value
	_publish_web_touch_controls_enabled()
	_sync_to_viewport()
	if _router != null and _router.has_method("set_force_touch_controls_enabled"):
		_router.set_force_touch_controls_enabled(value)
	queue_redraw()

func get_move_stick_rect() -> Rect2:
	var viewport_size := _viewport_size()
	var stick_size := clampf(minf(viewport_size.x, viewport_size.y) * 0.22, 112.0, 156.0)
	return Rect2(Vector2(48.0, viewport_size.y - stick_size - 48.0), Vector2(stick_size, stick_size))

func get_move_guard_rect() -> Rect2:
	return get_move_stick_rect().grow(MOVE_GUARD_PADDING)

func get_jump_button_rect() -> Rect2:
	var viewport_size := _viewport_size()
	var button_size := clampf(minf(viewport_size.x, viewport_size.y) * 0.15, 82.0, 116.0)
	return Rect2(Vector2(viewport_size.x - button_size - 64.0, viewport_size.y - button_size - 62.0), Vector2(button_size, button_size))

func get_jump_guard_rect() -> Rect2:
	return get_jump_button_rect().grow(JUMP_GUARD_PADDING)

func get_look_area_rect() -> Rect2:
	var viewport_size := _viewport_size()
	var move_guard := get_move_guard_rect()
	return Rect2(Vector2(move_guard.end.x + 28.0, 0.0), Vector2(viewport_size.x - move_guard.end.x - 28.0, viewport_size.y))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _web_pointer_mode_active:
		if event is InputEventScreenTouch \
			or event is InputEventScreenDrag \
			or event is InputEventMouseButton \
			or event is InputEventMouseMotion:
			return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)

func _draw() -> void:
	if not visible:
		return
	var move_rect := get_move_stick_rect()
	var jump_rect := get_jump_button_rect()
	var move_center := move_rect.get_center()
	var jump_center := jump_rect.get_center()
	var stick_radius := move_rect.size.x * 0.5
	var knob_radius := stick_radius * 0.36
	var knob_offset := Vector2.ZERO
	if _move_touch_index >= 0:
		knob_offset = (_move_touch_current - _move_touch_start).limit_length(stick_radius * 0.62)
	var dark := Color(0.152941, 0.188235, 0.262745, 0.72)
	var cream := Color(1.0, 0.949, 0.78, 0.42)
	var coral := Color(1.0, 0.435, 0.38, 0.62)
	var mint := Color(0.482, 0.878, 0.678, 0.72)
	if theme_config != null:
		dark = Color(theme_config.get("palette_text"), 0.72)
		coral = Color(theme_config.get("palette_primary"), 0.62)
		mint = Color(theme_config.get("palette_accent"), 0.72)
	draw_circle(move_center, stick_radius, cream)
	draw_arc(move_center, stick_radius, 0.0, TAU, 64, dark, 4.0)
	draw_circle(move_center + knob_offset, knob_radius, mint)
	draw_arc(move_center + knob_offset, knob_radius, 0.0, TAU, 48, dark, 3.0)
	draw_circle(jump_center, jump_rect.size.x * 0.5, coral)
	draw_arc(jump_center, jump_rect.size.x * 0.5, 0.0, TAU, 48, dark, 4.0)
	_draw_jump_chevron(jump_center, jump_rect.size.x * 0.24, dark)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_active_pointer_positions[event.index] = event.position
		if get_move_guard_rect().has_point(event.position):
			if _move_touch_index < 0:
				_capture_move_touch(event.index, event.position)
		elif get_jump_guard_rect().has_point(event.position):
			_capture_jump_touch(event.index)
		elif _is_look_start_allowed(event.position) and _look_touch_index < 0:
			_look_touch_index = event.index
		elif _is_look_start_allowed(event.position) and _look_touch_index >= 0:
			_start_pinch(_look_touch_index, event.index)
	else:
		_active_pointer_positions.erase(event.index)
		if event.index == _move_touch_index:
			_move_touch_index = -1
			_move_touch_start = Vector2.ZERO
			_move_touch_current = Vector2.ZERO
			if _router != null and _router.has_method("set_virtual_move_vector"):
				_router.set_virtual_move_vector(Vector2.ZERO)
		elif event.index == _look_touch_index:
			_look_touch_index = -1
		if _jump_touch_indices.has(event.index):
			_jump_touch_indices.erase(event.index)
		if _pinch_touch_indices.has(event.index):
			_clear_pinch()
	queue_redraw()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_active_pointer_positions[event.index] = event.position
	if _jump_touch_indices.has(event.index):
		pass
	elif _pinch_touch_indices.has(event.index):
		_emit_pinch_zoom()
	elif event.index == _move_touch_index:
		_move_touch_current = event.position
		_emit_move_vector()
	elif event.index == _look_touch_index:
		if _router != null and _router.has_method("set_virtual_look_delta"):
			_router.set_virtual_look_delta(event.relative * look_sensitivity)
	queue_redraw()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if get_move_guard_rect().has_point(event.position):
			if _move_touch_index < 0:
				_capture_move_touch(MOUSE_POINTER_INDEX, event.position)
		elif get_jump_guard_rect().has_point(event.position):
			_capture_jump_touch(MOUSE_POINTER_INDEX)
	else:
		if _move_touch_index == MOUSE_POINTER_INDEX:
			_move_touch_index = -1
			_move_touch_start = Vector2.ZERO
			_move_touch_current = Vector2.ZERO
			if _router != null and _router.has_method("set_virtual_move_vector"):
				_router.set_virtual_move_vector(Vector2.ZERO)
		if _look_touch_index == MOUSE_POINTER_INDEX:
			_look_touch_index = -1
		if _jump_touch_indices.has(MOUSE_POINTER_INDEX):
			_jump_touch_indices.erase(MOUSE_POINTER_INDEX)
	queue_redraw()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _jump_touch_indices.has(MOUSE_POINTER_INDEX):
		pass
	elif _move_touch_index == MOUSE_POINTER_INDEX:
		_move_touch_current = event.position
		_emit_move_vector()
	queue_redraw()

func handle_web_pointer_event(args: Array) -> void:
	if not visible:
		return
	var payload := _web_event_payload(args)
	if payload.size() < 4:
		return
	_activate_web_pointer_mode()
	var event_type := str(payload[0])
	var index := int(payload[1])
	var position := _web_pointer_position_from_args(payload)
	_web_debug_log("gd pointer %s id=%d pos=%s raw=%s" % [event_type, index, _format_vec2(position), str(payload)])
	if event_type == "down":
		_handle_web_pointer_down(index, position)
	elif event_type == "move":
		_handle_web_pointer_move(index, position)
	elif event_type == "up" or event_type == "cancel":
		_handle_web_pointer_up(index)
	queue_redraw()

func handle_web_touch_event(args: Array) -> void:
	if not visible:
		return
	var payload := _web_event_payload(args)
	if payload.size() < 4:
		return
	_activate_web_pointer_mode()
	var event_type := str(payload[0])
	var index := int(payload[1])
	var position := _web_pointer_position_from_args(payload)
	_web_debug_log("gd touch %s id=%d pos=%s raw=%s" % [event_type, index, _format_vec2(position), str(payload)])
	if event_type == "start":
		_handle_web_pointer_down(index, position)
	elif event_type == "move":
		_handle_web_pointer_move(index, position)
	elif event_type == "end" or event_type == "cancel":
		_handle_web_pointer_up(index)
	queue_redraw()

func _handle_web_pointer_down(index: int, position: Vector2) -> void:
	_web_pointer_last_positions[index] = position
	_active_pointer_positions[index] = position
	if get_move_guard_rect().has_point(position):
		if _move_touch_index < 0:
			_capture_move_touch(index, position)
			_web_debug_log("gd down role=move id=%d move_rect=%s" % [index, str(get_move_stick_rect())])
		else:
			_web_debug_log("gd down role=move_ignored id=%d owner=%d" % [index, _move_touch_index])
	elif get_jump_guard_rect().has_point(position):
		_capture_jump_touch(index)
		_web_debug_log("gd down role=jump id=%d jump_rect=%s" % [index, str(get_jump_button_rect())])
	elif _is_look_start_allowed(position) and _look_touch_index < 0:
		_look_touch_index = index
		_web_debug_log("gd down role=look id=%d look_rect=%s" % [index, str(get_look_area_rect())])
	elif _is_look_start_allowed(position) and _look_touch_index >= 0:
		_start_pinch(_look_touch_index, index)
		_web_debug_log("gd down role=pinch id=%d first=%d" % [index, _look_touch_index])
	else:
		_web_debug_log("gd down role=ignored id=%d move_guard=%s jump_guard=%s look=%s" % [index, str(get_move_guard_rect()), str(get_jump_guard_rect()), str(get_look_area_rect())])

func _handle_web_pointer_move(index: int, position: Vector2) -> void:
	var previous: Vector2 = _web_pointer_last_positions.get(index, position)
	_web_pointer_last_positions[index] = position
	_active_pointer_positions[index] = position
	if _jump_touch_indices.has(index):
		pass
	elif _pinch_touch_indices.has(index):
		_emit_pinch_zoom()
	elif index == _move_touch_index:
		_move_touch_current = position
		_emit_move_vector()
		_web_debug_log("gd move role=move id=%d delta=%s" % [index, _format_vec2(position - previous)])
	elif index == _look_touch_index:
		if _router != null and _router.has_method("set_virtual_look_delta"):
			_router.set_virtual_look_delta((position - previous) * look_sensitivity)
			_web_debug_log("gd move role=look id=%d delta=%s" % [index, _format_vec2((position - previous) * look_sensitivity)])
	else:
		_web_debug_log("gd move role=none id=%d delta=%s owners move=%d look=%d pinch=%s" % [index, _format_vec2(position - previous), _move_touch_index, _look_touch_index, str(_pinch_touch_indices)])

func _handle_web_pointer_up(index: int) -> void:
	_web_pointer_last_positions.erase(index)
	_active_pointer_positions.erase(index)
	if index == _move_touch_index:
		_move_touch_index = -1
		_move_touch_start = Vector2.ZERO
		_move_touch_current = Vector2.ZERO
		if _router != null and _router.has_method("set_virtual_move_vector"):
			_router.set_virtual_move_vector(Vector2.ZERO)
	elif index == _look_touch_index:
		_look_touch_index = -1
	if _jump_touch_indices.has(index):
		_jump_touch_indices.erase(index)
	if _pinch_touch_indices.has(index):
		_clear_pinch()
	if _web_pointer_last_positions.is_empty():
		_web_pointer_mode_active = false
		_web_debug_log("gd bridge idle")

func _web_pointer_position_from_args(args: Array) -> Vector2:
	var position := Vector2(float(args[2]), float(args[3]))
	if args.size() < 6:
		return position
	var css_size := Vector2(float(args[4]), float(args[5]))
	if css_size.x <= 0.0 or css_size.y <= 0.0:
		return position
	var viewport_size := _viewport_size()
	return Vector2(
		position.x * viewport_size.x / css_size.x,
		position.y * viewport_size.y / css_size.y
	)

func _web_event_payload(args: Array) -> Array:
	if args.size() == 1 and args[0] is Array:
		return args[0] as Array
	return args

func _format_vec2(value: Vector2) -> String:
	return "(%.1f,%.1f)" % [value.x, value.y]

func _web_debug_log(message: String) -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("if(window.__shinokuteTouchDiagPush) window.__shinokuteTouchDiagPush(%s);" % JSON.stringify(message), true)

func _publish_web_touch_controls_enabled() -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("window.__shinokuteTouchControlsEnabled = %s;" % ("true" if visible else "false"), true)

func _activate_web_pointer_mode() -> void:
	if _web_pointer_mode_active:
		return
	_clear_touch_state()
	_web_pointer_mode_active = true

func _emit_move_vector() -> void:
	if _router == null or not _router.has_method("set_virtual_move_vector"):
		return
	var move_rect := get_move_stick_rect()
	var radius := move_rect.size.x * 0.5
	var delta := (_move_touch_current - _move_touch_start) / maxf(radius, 1.0)
	_router.set_virtual_move_vector(Vector2(delta.x, delta.y).limit_length(1.0))

func _capture_move_touch(index: int, position: Vector2) -> void:
	_move_touch_index = index
	_move_touch_start = position
	_move_touch_current = position
	_emit_move_vector()

func _capture_jump_touch(index: int) -> void:
	if not _jump_touch_indices.has(index):
		_jump_touch_indices.append(index)
	if _router != null and _router.has_method("press_virtual_jump"):
		_router.press_virtual_jump()

func _is_look_start_allowed(position: Vector2) -> bool:
	if get_move_guard_rect().has_point(position):
		return false
	if get_jump_guard_rect().has_point(position):
		return false
	return get_look_area_rect().has_point(position)

func _start_pinch(first_index: int, second_index: int) -> void:
	if not _active_pointer_positions.has(first_index) or not _active_pointer_positions.has(second_index):
		return
	_pinch_touch_indices = [first_index, second_index]
	_pinch_last_distance = _pinch_distance()

func _clear_pinch() -> void:
	_pinch_touch_indices = []
	_pinch_last_distance = 0.0

func _pinch_distance() -> float:
	if _pinch_touch_indices.size() != 2:
		return 0.0
	var first_index: int = int(_pinch_touch_indices[0])
	var second_index: int = int(_pinch_touch_indices[1])
	if not _active_pointer_positions.has(first_index) or not _active_pointer_positions.has(second_index):
		return 0.0
	return (_active_pointer_positions[first_index] as Vector2).distance_to(_active_pointer_positions[second_index] as Vector2)

func _emit_pinch_zoom() -> void:
	if _router == null or not _router.has_method("set_virtual_zoom_delta"):
		return
	var next_distance := _pinch_distance()
	if next_distance <= 0.0 or _pinch_last_distance <= 0.0:
		_pinch_last_distance = next_distance
		return
	var distance_delta := next_distance - _pinch_last_distance
	_pinch_last_distance = next_distance
	if absf(distance_delta) <= 0.1:
		return
	_router.set_virtual_zoom_delta(-distance_delta * pinch_zoom_sensitivity)

func _draw_jump_chevron(center: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -size),
		center + Vector2(size * 0.78, size * 0.18),
		center + Vector2(size * 0.28, size * 0.18),
		center + Vector2(size * 0.28, size),
		center + Vector2(-size * 0.28, size),
		center + Vector2(-size * 0.28, size * 0.18),
		center + Vector2(-size * 0.78, size * 0.18)
	])
	draw_colored_polygon(points, color)

func _refresh_visibility() -> void:
	if _manual_visibility:
		return
	visible = _router != null and _router.has_method("is_touch_control_active") and _router.is_touch_control_active()
	_publish_web_touch_controls_enabled()
	_sync_to_viewport()
	queue_redraw()

func _viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2(1280.0, 720.0)
	return viewport.get_visible_rect().size

func _on_viewport_size_changed() -> void:
	_sync_to_viewport()
	_clear_touch_state()
	queue_redraw()

func _sync_to_viewport() -> void:
	var viewport_size := _viewport_size()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	global_position = Vector2.ZERO
	size = viewport_size

func _clear_touch_state() -> void:
	_web_pointer_mode_active = false
	_move_touch_index = -1
	_look_touch_index = -1
	_move_touch_start = Vector2.ZERO
	_move_touch_current = Vector2.ZERO
	_jump_touch_indices = []
	_active_pointer_positions.clear()
	_web_pointer_last_positions.clear()
	_clear_pinch()
	if _router != null and _router.has_method("clear_virtual_input"):
		_router.clear_virtual_input()

func _install_web_pointer_bridge() -> void:
	if not OS.has_feature("web") or not ClassDB.class_exists("JavaScriptBridge"):
		return
	_web_pointer_callback = JavaScriptBridge.create_callback(handle_web_pointer_event)
	_web_touch_callback = JavaScriptBridge.create_callback(handle_web_touch_event)
	JavaScriptBridge.get_interface("window").shinokutePointerEvent = _web_pointer_callback
	JavaScriptBridge.get_interface("window").shinokuteTouchEvent = _web_touch_callback
	JavaScriptBridge.eval("""
(function(){
	if (window.__shinokutePointerBridgeInstalled) return;
	window.__shinokutePointerBridgeInstalled = true;
	window.__shinokuteTouchControlsEnabled = true;
	var diagEnabled = /[?&]touchdiag=1(?:&|$)/.test(window.location.search);
	var activeBridge = null;
	var activePointerIds = {};
	var activeTouchIds = {};
	function diag(line) {
		if (!diagEnabled) return;
		if (!window.__shinokuteTouchDiagLog) window.__shinokuteTouchDiagLog = [];
		var item = (Date.now() % 100000) + ' ' + line;
		window.__shinokuteTouchDiagLog.push(item);
		if (window.__shinokuteTouchDiagLog.length > 160) window.__shinokuteTouchDiagLog.shift();
		if (window.__shinokuteTouchDiagPre) window.__shinokuteTouchDiagPre.textContent = window.__shinokuteTouchDiagLog.slice(-80).join(String.fromCharCode(10));
		console.log('[touchdiag] ' + item);
	}
	window.__shinokuteTouchDiagPush = diag;
	function installDiagOverlay() {
		if (!diagEnabled || document.getElementById('shinokute-touch-diag')) return;
		var box = document.createElement('div');
		box.id = 'shinokute-touch-diag';
		box.style.cssText = 'position:fixed;left:0;right:0;bottom:0;z-index:999999;background:rgba(0,0,0,.78);color:#7CFFB2;font:11px monospace;max-height:42vh;overflow:auto;padding:6px;white-space:pre-wrap;touch-action:auto;';
		var buttons = document.createElement('div');
		var copy = document.createElement('button');
		copy.textContent = 'Copy touch log';
		copy.onclick = function(){ navigator.clipboard && navigator.clipboard.writeText((window.__shinokuteTouchDiagLog || []).join(String.fromCharCode(10))); };
		var clear = document.createElement('button');
		clear.textContent = 'Clear';
		clear.onclick = function(){ window.__shinokuteTouchDiagLog = []; if (window.__shinokuteTouchDiagPre) window.__shinokuteTouchDiagPre.textContent = ''; };
		buttons.appendChild(copy);
		buttons.appendChild(clear);
		var pre = document.createElement('pre');
		pre.style.cssText = 'margin:4px 0 0 0;white-space:pre-wrap;';
		window.__shinokuteTouchDiagPre = pre;
		box.appendChild(buttons);
		box.appendChild(pre);
		document.body.appendChild(box);
		diag('diag overlay installed ' + navigator.userAgent);
	}
	function activeCount(map) {
		var count = 0;
		for (var key in map) if (Object.prototype.hasOwnProperty.call(map, key)) count++;
		return count;
	}
	function clearBridgeIfIdle() {
		if (activeCount(activePointerIds) === 0 && activeCount(activeTouchIds) === 0) activeBridge = null;
	}
	function canvasPointFromClient(clientX, clientY) {
		var canvas = document.getElementById('canvas') || document.querySelector('canvas');
		if (!canvas) return null;
		var rect = canvas.getBoundingClientRect();
		var scaleX = canvas.clientWidth ? rect.width / canvas.clientWidth : 1;
		var scaleY = canvas.clientHeight ? rect.height / canvas.clientHeight : 1;
		return {
			x: (clientX - rect.left) / Math.max(scaleX, 0.0001),
			y: (clientY - rect.top) / Math.max(scaleY, 0.0001),
			w: canvas.clientWidth || rect.width,
			h: canvas.clientHeight || rect.height
		};
	}
	function sendPointer(type, event) {
		if (event.pointerType === 'mouse') return;
		if (window.__shinokuteTouchControlsEnabled === false) { activeBridge = null; return; }
		if (activeBridge && activeBridge !== 'pointer') { diag('js pointer ignored activeBridge=' + activeBridge + ' type=' + type + ' id=' + event.pointerId); return; }
		if (typeof window.shinokutePointerEvent !== 'function') return;
		var point = canvasPointFromClient(event.clientX, event.clientY);
		if (!point) return;
		activeBridge = 'pointer';
		if (type === 'down') activePointerIds[event.pointerId] = true;
		event.preventDefault();
		diag('js pointer ' + type + ' id=' + event.pointerId + ' ptype=' + event.pointerType + ' client=(' + event.clientX + ',' + event.clientY + ') point=(' + point.x.toFixed(1) + ',' + point.y.toFixed(1) + ') css=(' + point.w + ',' + point.h + ')');
		window.shinokutePointerEvent(type, event.pointerId, point.x, point.y, point.w, point.h);
		if (type === 'up' || type === 'cancel') {
			delete activePointerIds[event.pointerId];
			clearBridgeIfIdle();
		}
	}
	function sendTouches(type, event) {
		if (window.__shinokuteTouchControlsEnabled === false) { activeBridge = null; return; }
		if (activeBridge && activeBridge !== 'touch') { diag('js touch ignored activeBridge=' + activeBridge + ' type=' + type); return; }
		if (typeof window.shinokuteTouchEvent !== 'function') return;
		var touches = event.changedTouches || [];
		if (!touches.length) return;
		activeBridge = 'touch';
		event.preventDefault();
		for (var i = 0; i < touches.length; i++) {
			var touch = touches[i];
			var point = canvasPointFromClient(touch.clientX, touch.clientY);
			if (!point) continue;
			if (type === 'start') activeTouchIds[touch.identifier] = true;
			diag('js touch ' + type + ' id=' + touch.identifier + ' client=(' + touch.clientX + ',' + touch.clientY + ') point=(' + point.x.toFixed(1) + ',' + point.y.toFixed(1) + ') css=(' + point.w + ',' + point.h + ') changed=' + touches.length);
			window.shinokuteTouchEvent(type, touch.identifier, point.x, point.y, point.w, point.h);
			if (type === 'end' || type === 'cancel') delete activeTouchIds[touch.identifier];
		}
		if (type === 'end' || type === 'cancel') clearBridgeIfIdle();
	}
	function bind() {
		var canvas = document.getElementById('canvas') || document.querySelector('canvas');
		if (!canvas || canvas.__shinokutePointerBridgeBound) return;
		canvas.__shinokutePointerBridgeBound = true;
		canvas.style.touchAction = 'none';
		diag('bind canvas id=' + (canvas.id || '') + ' client=(' + canvas.clientWidth + ',' + canvas.clientHeight + ')');
		canvas.addEventListener('pointerdown', function(event) {
			try { canvas.setPointerCapture(event.pointerId); } catch (error) {}
			sendPointer('down', event);
		}, { passive: false });
		canvas.addEventListener('pointermove', function(event) { sendPointer('move', event); }, { passive: false });
		canvas.addEventListener('pointerup', function(event) { sendPointer('up', event); }, { passive: false });
		canvas.addEventListener('pointercancel', function(event) { sendPointer('cancel', event); }, { passive: false });
		canvas.addEventListener('touchstart', function(event) { sendTouches('start', event); }, { passive: false });
		canvas.addEventListener('touchmove', function(event) { sendTouches('move', event); }, { passive: false });
		canvas.addEventListener('touchend', function(event) { sendTouches('end', event); }, { passive: false });
		canvas.addEventListener('touchcancel', function(event) { sendTouches('cancel', event); }, { passive: false });
	}
	bind();
	document.addEventListener('DOMContentLoaded', bind, { once: true });
	window.addEventListener('load', bind, { once: true });
	document.addEventListener('DOMContentLoaded', installDiagOverlay, { once: true });
	window.addEventListener('load', installDiagOverlay, { once: true });
	installDiagOverlay();
})();
""", true)
