class_name ShinokuteStatusEffectRuntime
extends RefCounted

var _effects: Dictionary = {}

func add_effect(effect: Dictionary) -> void:
	var id: String = String(effect.get("id", ""))
	if id.is_empty():
		return
	var max_stacks: int = int(max(1, int(effect.get("max_stacks", 1))))
	var duration: float = max(0.0, float(effect.get("duration", effect.get("duration_seconds", 0.0))))
	var tick_interval: float = max(0.0, float(effect.get("tick_interval", 0.0)))
	if _effects.has(id):
		var active: Dictionary = Dictionary(_effects[id]).duplicate(true)
		active["stacks"] = min(max_stacks, int(active.get("stacks", 1)) + 1)
		active["remaining"] = duration
		active["duration"] = duration
		active["tick_interval"] = tick_interval
		active["tick_remaining"] = tick_interval
		active["max_stacks"] = max_stacks
		active["payload"] = Dictionary(effect.get("payload", active.get("payload", {}))).duplicate(true)
		_effects[id] = active
		return
	var stored: Dictionary = effect.duplicate(true)
	stored["id"] = id
	stored["duration"] = duration
	stored["remaining"] = duration
	stored["tick_interval"] = tick_interval
	stored["tick_remaining"] = tick_interval
	stored["stacks"] = int(max(1, int(effect.get("stacks", 1))))
	stored["max_stacks"] = max_stacks
	stored["payload"] = Dictionary(effect.get("payload", {})).duplicate(true)
	_effects[id] = stored

func advance(delta: float) -> Array:
	var events: Array = []
	var step: float = max(0.0, delta)
	var expired: Array = []
	for id in _effects.keys():
		var effect: Dictionary = Dictionary(_effects[id]).duplicate(true)
		var remaining: float = float(effect.get("remaining", 0.0)) - step
		var tick_interval: float = float(effect.get("tick_interval", 0.0))
		if tick_interval > 0.0:
			var tick_remaining: float = float(effect.get("tick_remaining", tick_interval)) - step
			while tick_remaining <= 0.0 and remaining >= 0.0:
				events.append(_event("tick", effect))
				tick_remaining += tick_interval
			effect["tick_remaining"] = tick_remaining
		effect["remaining"] = remaining
		if remaining <= 0.0:
			events.append(_event("expired", effect))
			expired.append(id)
		else:
			_effects[id] = effect
	for id in expired:
		_effects.erase(id)
	return events

func active_effect(id: String) -> Dictionary:
	if not _effects.has(id):
		return {}
	return Dictionary(_effects[id]).duplicate(true)

func active_effects() -> Array:
	var items: Array = []
	for id in _effects.keys():
		items.append(Dictionary(_effects[id]).duplicate(true))
	return items

func remove_effect(id: String) -> void:
	_effects.erase(id)

func clear() -> void:
	_effects.clear()

func _event(event_type: String, effect: Dictionary) -> Dictionary:
	return {
		"type": event_type,
		"id": String(effect.get("id", "")),
		"stacks": int(effect.get("stacks", 1)),
		"payload": Dictionary(effect.get("payload", {})).duplicate(true)
	}
