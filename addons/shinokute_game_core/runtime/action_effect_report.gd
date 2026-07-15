class_name ShinokuteActionEffectReport
extends RefCounted

var _accepted := false
var _block_reason := ""
var _context: Dictionary = {}
var _effects: Array = []
var _events: Array = []

func accept(context: Dictionary = {}) -> void:
	_accepted = true
	_block_reason = ""
	_context = context.duplicate(true)

func block(reason: String, context: Dictionary = {}) -> void:
	_accepted = false
	_block_reason = reason
	_context = context.duplicate(true)

func add_effect(effect_type: String, payload: Dictionary = {}) -> void:
	_effects.append({"type": effect_type, "payload": payload.duplicate(true)})

func add_event(event_name: String, payload: Dictionary = {}) -> void:
	_events.append({"name": event_name, "payload": payload.duplicate(true)})

func to_dictionary() -> Dictionary:
	return {
		"accepted": _accepted,
		"block_reason": _block_reason,
		"context": _context.duplicate(true),
		"effects": _effects.duplicate(true),
		"events": _events.duplicate(true)
	}
