class_name ShinokuteSpawnTelegraphLifecycle
extends RefCounted

var _pending: Array = []

func request(spawn_request: Dictionary) -> void:
	var id := String(spawn_request.get("id", ""))
	if id.is_empty():
		return
	var pending := spawn_request.duplicate(true)
	pending["remaining"] = max(0.0, float(spawn_request.get("delay", spawn_request.get("delay_seconds", 0.0))))
	_pending.append(pending)

func advance(delta: float) -> Array:
	var ready: Array = []
	var kept: Array = []
	for item in _pending:
		var pending := Dictionary(item).duplicate(true)
		pending["remaining"] = float(pending.get("remaining", 0.0)) - max(0.0, delta)
		if float(pending.get("remaining", 0.0)) <= 0.0:
			pending.erase("remaining")
			ready.append(pending)
		else:
			kept.append(pending)
	_pending = kept
	return ready

func cancel(id: String) -> void:
	var kept: Array = []
	for item in _pending:
		var pending := Dictionary(item)
		if String(pending.get("id", "")) != id:
			kept.append(pending)
	_pending = kept

func pending_count() -> int:
	return _pending.size()

func clear() -> void:
	_pending.clear()
