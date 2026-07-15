class_name ShinokuteSceneTransitionLifecycle
extends RefCounted

var _routes: Dictionary = {}
var _state: Dictionary = {"phase": "idle", "key": "", "path": "", "payload": {}, "fade_out": 0.0, "fade_in": 0.0, "remaining": 0.0}

func configure(routes: Dictionary = {}) -> void:
	_routes = routes.duplicate(true)
	_state = {"phase": "idle", "key": "", "path": "", "payload": {}, "fade_out": 0.0, "fade_in": 0.0, "remaining": 0.0}

func request_transition(key: String, config: Dictionary = {}, payload: Dictionary = {}) -> Dictionary:
	if String(_state.get("phase", "idle")) != "idle":
		return {"status": "blocked", "reason": "active_transition", "active": String(_state.get("key", "")), "closed": []}
	var path := String(_routes.get(key, ""))
	if path.is_empty():
		return {"status": "blocked", "reason": "missing_route", "closed": []}
	_state = {
		"phase": "queued",
		"key": key,
		"path": path,
		"payload": payload.duplicate(true),
		"fade_out": float(config.get("fade_out", 0.0)),
		"fade_in": float(config.get("fade_in", 0.0)),
		"remaining": 0.0
	}
	return {"status": "queued", "key": key, "path": path, "closed": []}

func advance(delta: float) -> Dictionary:
	var phase := String(_state.get("phase", "idle"))
	if phase == "idle":
		return snapshot()
	if phase == "queued":
		_state["phase"] = "fade_out"
		_state["remaining"] = float(_state.get("fade_out", 0.0))
		return snapshot()
	var remaining := max(0.0, float(_state.get("remaining", 0.0)) - max(0.0, delta))
	_state["remaining"] = remaining
	if remaining > 0.0:
		return snapshot()
	match phase:
		"fade_out":
			_state["phase"] = "change_scene"
		"change_scene":
			_state["phase"] = "fade_in"
			_state["remaining"] = float(_state.get("fade_in", 0.0))
		"fade_in":
			_state["phase"] = "idle"
			_state["key"] = ""
			_state["path"] = ""
			_state["payload"] = {}
			_state["remaining"] = 0.0
	return snapshot()

func complete_change() -> Dictionary:
	if String(_state.get("phase", "")) == "change_scene":
		_state["phase"] = "fade_in"
		_state["remaining"] = float(_state.get("fade_in", 0.0))
	return snapshot()

func cancel() -> Dictionary:
	_state = {"phase": "idle", "key": "", "path": "", "payload": {}, "fade_out": 0.0, "fade_in": 0.0, "remaining": 0.0}
	return snapshot()

func snapshot() -> Dictionary:
	return _state.duplicate(true)
