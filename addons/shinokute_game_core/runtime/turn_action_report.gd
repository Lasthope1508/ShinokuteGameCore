class_name ShinokuteTurnActionReport
extends RefCounted

var _accepted := false
var _actor_id := ""
var _action_id := ""
var _block_reason := ""
var _context: Dictionary = {}
var _energy_cost := 0.0
var _effects: Array = []
var _events: Array = []
var _messages: Array = []

func accept(actor_id: String, action_id: String, context: Dictionary = {}, energy_cost: float = 0.0) -> void:
	_accepted = true
	_actor_id = actor_id.strip_edges()
	_action_id = action_id.strip_edges()
	_block_reason = ""
	_context = context.duplicate(true)
	_energy_cost = max(0.0, energy_cost)
	_effects = []
	_events = []
	_messages = []

func block(actor_id: String, action_id: String, reason: String, context: Dictionary = {}) -> void:
	_accepted = false
	_actor_id = actor_id.strip_edges()
	_action_id = action_id.strip_edges()
	_block_reason = reason.strip_edges()
	_context = context.duplicate(true)
	_energy_cost = 0.0
	_effects = []
	_events = []
	_messages = []

func add_effect(effect_type: String, payload: Dictionary = {}) -> void:
	var key := effect_type.strip_edges()
	if key.is_empty():
		return
	_effects.append({"type": key, "payload": payload.duplicate(true)})

func add_event(event_name: String, payload: Dictionary = {}) -> void:
	var key := event_name.strip_edges()
	if key.is_empty():
		return
	_events.append({"name": key, "payload": payload.duplicate(true)})

func add_message(message_key: String, payload: Dictionary = {}) -> void:
	var key := message_key.strip_edges()
	if key.is_empty():
		return
	_messages.append({"key": key, "payload": payload.duplicate(true)})

func to_dictionary() -> Dictionary:
	return {
		"accepted": _accepted,
		"actor_id": _actor_id,
		"action_id": _action_id,
		"block_reason": _block_reason,
		"context": _context.duplicate(true),
		"energy_cost": _energy_cost,
		"effects": _effects.duplicate(true),
		"events": _events.duplicate(true),
		"messages": _messages.duplicate(true)
	}
