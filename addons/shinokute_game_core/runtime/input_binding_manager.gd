class_name ShinokuteInputBindingManager
extends Node

signal bindings_changed(bindings: Dictionary)
signal action_rebound(action: String, event: InputEvent)

var _bindings: Dictionary = {}

func configure(default_bindings: Dictionary = {}, saved_bindings: Dictionary = {}) -> void:
	_bindings = default_bindings.duplicate(true)
	for action in saved_bindings.keys():
		_bindings[String(action)] = saved_bindings[action]

func apply_bindings() -> void:
	for action in _bindings.keys():
		_apply_action_bindings(String(action), _bindings[action])

func rebind_action_to_event(action: String, event: InputEvent) -> int:
	var key := action.strip_edges()
	if key.is_empty() or event == null:
		return ERR_INVALID_PARAMETER
	_ensure_action(key)
	InputMap.action_erase_events(key)
	InputMap.action_add_event(key, event)
	_bindings[key] = [_event_to_spec(event)]
	action_rebound.emit(key, event)
	bindings_changed.emit(serialize_bindings())
	return OK

func serialize_bindings() -> Dictionary:
	return _bindings.duplicate(true)

func get_action_specs(action: String) -> Array:
	var key := action.strip_edges()
	if not _bindings.has(key):
		return []
	return _bindings[key]

func _apply_action_bindings(action: String, specs: Array) -> void:
	if action.strip_edges().is_empty():
		return
	_ensure_action(action)
	InputMap.action_erase_events(action)
	for spec in specs:
		if spec is Dictionary:
			var event := _event_from_spec(spec)
			if event != null:
				InputMap.action_add_event(action, event)

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _event_from_spec(spec: Dictionary) -> InputEvent:
	var event_type := String(spec.get("type", "key"))
	if event_type == "key":
		var event := InputEventKey.new()
		event.keycode = int(spec.get("keycode", 0))
		event.physical_keycode = int(spec.get("physical_keycode", 0))
		return event
	if event_type == "joypad_button":
		var event := InputEventJoypadButton.new()
		event.button_index = int(spec.get("button_index", 0))
		return event
	if event_type == "mouse_button":
		var event := InputEventMouseButton.new()
		event.button_index = int(spec.get("button_index", 0))
		return event
	return null

func _event_to_spec(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode
		}
	if event is InputEventJoypadButton:
		return {
			"type": "joypad_button",
			"button_index": event.button_index
		}
	if event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index
		}
	return {"type": "unknown"}
