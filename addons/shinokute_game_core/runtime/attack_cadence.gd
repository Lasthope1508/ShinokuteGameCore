class_name ShinokuteAttackCadence
extends RefCounted

var _defaults: Dictionary = {}

func configure(defaults: Dictionary = {}) -> void:
	_defaults = defaults.duplicate(true)

func initial_state(config: Dictionary = {}) -> Dictionary:
	var merged := _merged_config(config)
	return {
		"phase": String(merged.get("phase", "ready")),
		"phase_remaining": float(merged.get("phase_remaining", 0.0)),
		"cooldown_remaining": float(merged.get("cooldown_remaining", 0.0))
	}

func can_request(state: Dictionary) -> bool:
	return String(state.get("phase", "ready")) == "ready" and float(state.get("cooldown_remaining", 0.0)) <= 0.0

func request(state: Dictionary, config: Dictionary = {}) -> Dictionary:
	var current := state.duplicate(true)
	if not can_request(current):
		var reason := "cooldown" if String(current.get("phase", "ready")) == "ready" else "phase_active"
		return {"status": "blocked", "reason": reason, "state": current}
	var merged := _merged_config(config)
	var next_phase := "anticipate"
	var remaining := float(merged.get("anticipate", 0.0))
	var events: Array = []
	if remaining <= 0.0:
		next_phase = "duration"
		remaining = float(merged.get("duration", 0.0))
		events.append("execute")
	current["phase"] = next_phase
	current["phase_remaining"] = remaining
	current["cooldown_remaining"] = 0.0
	return {"status": "accepted", "state": current, "events": events}

func advance(state: Dictionary, delta: float, config: Dictionary = {}) -> Dictionary:
	var merged := _merged_config(config)
	var next := state.duplicate(true)
	var events: Array = []
	var remaining_delta := max(0.0, delta)
	if String(next.get("phase", "ready")) == "ready":
		next["cooldown_remaining"] = max(0.0, float(next.get("cooldown_remaining", 0.0)) - remaining_delta)
		next["events"] = events
		return next
	while remaining_delta >= 0.0 and String(next.get("phase", "ready")) != "ready":
		var phase_remaining := float(next.get("phase_remaining", 0.0))
		if remaining_delta < phase_remaining:
			next["phase_remaining"] = phase_remaining - remaining_delta
			break
		remaining_delta -= phase_remaining
		_advance_phase(next, merged, events)
		if remaining_delta <= 0.0:
			break
	next["events"] = events
	return next

func snapshot(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

func restore(snapshot: Dictionary) -> Dictionary:
	return snapshot.duplicate(true)

func _advance_phase(state: Dictionary, config: Dictionary, events: Array) -> void:
	match String(state.get("phase", "ready")):
		"anticipate":
			state["phase"] = "duration"
			state["phase_remaining"] = float(config.get("duration", 0.0))
			events.append("execute")
		"duration":
			state["phase"] = "recovery"
			state["phase_remaining"] = float(config.get("recovery", 0.0))
			events.append("recover")
		"recovery":
			state["phase"] = "ready"
			state["phase_remaining"] = 0.0
			state["cooldown_remaining"] = float(config.get("cooldown", 0.0))
			events.append("ready")
		_:
			state["phase"] = "ready"
			state["phase_remaining"] = 0.0

func _merged_config(config: Dictionary) -> Dictionary:
	var merged := _defaults.duplicate(true)
	for key in config.keys():
		merged[key] = config[key]
	return merged
