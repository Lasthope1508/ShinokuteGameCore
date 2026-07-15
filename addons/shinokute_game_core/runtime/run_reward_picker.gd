class_name ShinokuteRunRewardPicker
extends RefCounted

const RequirementResolverScript := preload("res://addons/shinokute_game_core/runtime/requirement_resolver.gd")

var _entries: Array = []
var _weighted_picker_script: Script
var _requirement_resolver := RequirementResolverScript.new()

func configure(entries: Array, weighted_picker_script: Script = null) -> void:
	_entries = []
	_weighted_picker_script = weighted_picker_script
	for item in entries:
		if item is Dictionary:
			_entries.append(Dictionary(item).duplicate(true))

func pick_options(count: int, context: Dictionary = {}, state: Dictionary = {}, rolls: Array = []) -> Array:
	var available := _available_entries(context, state)
	var selected: Array = []
	var excluded: Array = []
	var option_count: int = int(min(max(0, count), available.size()))
	for i in range(option_count):
		var picked := _pick_one(available, excluded, _roll_at(rolls, i))
		if picked.is_empty():
			break
		selected.append(picked.duplicate(true))
		excluded.append(picked.get("id"))
	return selected

func _available_entries(context: Dictionary, state: Dictionary) -> Array:
	var banished := Array(state.get("banished", []))
	var counts := Dictionary(state.get("counts", {}))
	var available: Array = []
	for item in _entries:
		var entry := Dictionary(item)
		var id := String(entry.get("id", ""))
		if id.is_empty() or banished.has(id):
			continue
		var max_quantity := int(entry.get("max_quantity", 0))
		if max_quantity > 0 and int(counts.get(id, 0)) >= max_quantity:
			continue
		if entry.has("requirements") and not _requirement_resolver.is_met(entry.get("requirements"), context):
			continue
		if float(entry.get("weight", 0.0)) <= 0.0:
			continue
		available.append(entry.duplicate(true))
	return available

func _pick_one(entries: Array, excluded: Array, roll: float) -> Dictionary:
	if entries.is_empty():
		return {}
	if _weighted_picker_script == null:
		for item in entries:
			var entry := Dictionary(item)
			if not excluded.has(entry.get("id")):
				return entry.duplicate(true)
		return {}
	var picker = _weighted_picker_script.new()
	picker.configure(entries)
	return picker.pick(roll, excluded)

func _roll_at(rolls: Array, index: int) -> float:
	if index >= 0 and index < rolls.size():
		return float(rolls[index])
	return -1.0
