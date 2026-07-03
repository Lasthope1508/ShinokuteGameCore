extends RefCounted
class_name VfxTransitionState

const DIRECTIONS := [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

static func build(previous_flow_state: Dictionary, current_flow_state: Dictionary, changed_cell: Vector2i, event_time: float) -> Dictionary:
	var previous_copy := previous_flow_state.duplicate(true)
	var current_copy := current_flow_state.duplicate(true)
	return {
		"previous_flow_state": previous_copy,
		"current_flow_state": current_copy,
		"changed_cell": changed_cell,
		"entered_cells": _get_entered_cells(previous_copy, current_copy),
		"lost_cells": _get_lost_cells(previous_copy, current_copy),
		"entered_contacts": _get_entered_contacts(previous_copy, current_copy),
		"lost_contacts": _get_lost_contacts(previous_copy, current_copy),
		"event_time": event_time
	}

static func empty(event_time: float = 0.0) -> Dictionary:
	return build({}, {}, Vector2i(-1, -1), event_time)

static func _get_entered_cells(previous_flow_state: Dictionary, current_flow_state: Dictionary) -> Array:
	var entered := []
	for raw_cell_pos in current_flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		if not previous_flow_state.has(cell_pos):
			entered.append(cell_pos)
	return entered

static func _get_lost_cells(previous_flow_state: Dictionary, current_flow_state: Dictionary) -> Array:
	var lost := []
	for raw_cell_pos in previous_flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		if not current_flow_state.has(cell_pos):
			lost.append(cell_pos)
	return lost

static func _get_entered_contacts(previous_flow_state: Dictionary, current_flow_state: Dictionary) -> Array:
	return _subtract_contacts(_get_contacts(current_flow_state), _get_contacts(previous_flow_state))

static func _get_lost_contacts(previous_flow_state: Dictionary, current_flow_state: Dictionary) -> Array:
	return _subtract_contacts(_get_contacts(previous_flow_state), _get_contacts(current_flow_state))

static func _get_contacts(flow_state: Dictionary) -> Array:
	var contacts := []
	var seen := {}
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var dirs := []
		var input_dir := int(entry.get("input_dir", -1))
		if input_dir >= 0:
			dirs.append(input_dir)
		for raw_output_dir in entry.get("output_dirs", []):
			var output_dir := int(raw_output_dir)
			if output_dir >= 0:
				dirs.append(output_dir)
		for raw_dir in dirs:
			var direction := int(raw_dir)
			if direction < 0 or direction >= DIRECTIONS.size():
				continue
			var neighbor_pos: Vector2i = cell_pos + DIRECTIONS[direction]
			var key := _contact_key(cell_pos, direction, neighbor_pos)
			if seen.has(key):
				continue
			seen[key] = true
			contacts.append({
				"cell_pos": cell_pos,
				"direction": direction,
				"neighbor_pos": neighbor_pos
			})
	return contacts

static func _subtract_contacts(primary: Array, secondary: Array) -> Array:
	var secondary_keys := {}
	for contact in secondary:
		secondary_keys[_contact_key(contact.get("cell_pos", Vector2i(-999, -999)), int(contact.get("direction", -1)), contact.get("neighbor_pos", Vector2i(-999, -999)))] = true
	var result := []
	for contact in primary:
		var key := _contact_key(contact.get("cell_pos", Vector2i(-999, -999)), int(contact.get("direction", -1)), contact.get("neighbor_pos", Vector2i(-999, -999)))
		if not secondary_keys.has(key):
			result.append(contact)
	return result

static func _contact_key(cell_pos: Vector2i, direction: int, neighbor_pos: Vector2i) -> String:
	return "%d,%d:%d:%d,%d" % [cell_pos.x, cell_pos.y, direction, neighbor_pos.x, neighbor_pos.y]
