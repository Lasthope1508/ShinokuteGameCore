class_name ShinokuteModalLifecycle
extends RefCounted

var _definitions: Dictionary = {}
var _active_key := ""
var _active_payload: Dictionary = {}

func configure(definitions: Dictionary) -> void:
	_definitions = definitions.duplicate(true)
	_active_key = ""
	_active_payload = {}

func request(key: String, payload: Dictionary = {}) -> Dictionary:
	if key.is_empty():
		return {"status": "blocked", "reason": "empty_key", "closed": []}
	var closed: Array = []
	if not _active_key.is_empty():
		if _can_supersede(key, _active_key):
			closed.append(_active_key)
			_active_key = ""
			_active_payload = {}
		elif _is_blocking(_active_key):
			return {"status": "blocked", "reason": "active_blocking_modal", "active": _active_key, "closed": []}
	_active_key = key
	_active_payload = payload.duplicate(true)
	return {"status": "shown", "key": key, "payload": _active_payload.duplicate(true), "closed": closed}

func close(key: String = "") -> Dictionary:
	if _active_key.is_empty():
		return {"status": "noop", "closed": []}
	if not key.is_empty() and key != _active_key:
		return {"status": "noop", "closed": []}
	var closed := [_active_key]
	_active_key = ""
	_active_payload = {}
	return {"status": "closed", "closed": closed}

func active_key() -> String:
	return _active_key

func active_payload() -> Dictionary:
	return _active_payload.duplicate(true)

func state() -> Dictionary:
	return {"active_key": _active_key, "active_payload": _active_payload.duplicate(true)}

func _is_blocking(key: String) -> bool:
	return bool(Dictionary(_definitions.get(key, {})).get("blocking", true))

func _can_supersede(next_key: String, active_key: String) -> bool:
	return Array(Dictionary(_definitions.get(next_key, {})).get("supersedes", [])).has(active_key)
