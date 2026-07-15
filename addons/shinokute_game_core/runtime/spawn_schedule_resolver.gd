class_name ShinokuteSpawnScheduleResolver
extends RefCounted

var _schedule: Array = []
var _stage_key := "wave"
var _weight_entries_key := "weights"
var _item_key := "id"
var _weight_key := "weight"
var _budget_sources: Array = []
var _weighted_picker_script: Script
var _budget_resolver_script: Script

func configure(schedule: Array, options: Dictionary = {}) -> void:
	_schedule = []
	for item in schedule:
		if item is Dictionary:
			_schedule.append(Dictionary(item).duplicate(true))
	_stage_key = String(options.get("stage_key", "wave"))
	_weight_entries_key = String(options.get("weight_entries_key", "weights"))
	_item_key = String(options.get("item_key", "id"))
	_weight_key = String(options.get("weight_key", "weight"))
	_budget_sources = Array(options.get("budget_sources", [])).duplicate(true)
	_weighted_picker_script = options.get("weighted_picker_script", null)
	_budget_resolver_script = options.get("budget_resolver_script", null)

func schedule_for_stage(stage_index: int) -> Dictionary:
	var selected: Dictionary = {}
	for item in _schedule:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		if int(entry.get(_stage_key, 0)) <= stage_index:
			selected = entry
	return selected.duplicate(true)

func value_for_stage(stage_index: int, key: String, fallback = null):
	var schedule := schedule_for_stage(stage_index)
	return schedule.get(key, fallback)

func pattern_for_stage(stage_index: int) -> Dictionary:
	return Dictionary(value_for_stage(stage_index, "spawn_pattern", {})).duplicate(true)

func weight_entries_for_stage(stage_index: int) -> Array:
	return Array(schedule_for_stage(stage_index).get(_weight_entries_key, [])).duplicate(true)

func budget_entries_for_stage(stage_index: int) -> Array:
	var schedule := schedule_for_stage(stage_index)
	var budgets: Array = []
	for item in Array(schedule.get("budgets", [])):
		if item is Dictionary:
			budgets.append(Dictionary(item).duplicate(true))
	for source_item in _budget_sources:
		if not (source_item is Dictionary):
			continue
		var source := Dictionary(source_item)
		var source_key := String(source.get("source_key", ""))
		var group := String(source.get("group", ""))
		var key_field := String(source.get("key_field", "key"))
		var max_field := String(source.get("max_field", "max"))
		if source_key.is_empty() or group.is_empty():
			continue
		for raw_limit in Array(schedule.get(source_key, [])):
			if not (raw_limit is Dictionary):
				continue
			var limit := Dictionary(raw_limit)
			var key := String(limit.get(key_field, ""))
			if key.is_empty():
				continue
			budgets.append({"group": group, "key": key, "max": int(limit.get(max_field, -1))})
	return budgets

func filter_candidates_for_stage(stage_index: int, candidates: Array, active_counts: Dictionary = {}, key_maps: Array = []) -> Array:
	var by_weight := _weight_allowed_ids(stage_index)
	var filtered: Array = []
	for item in candidates:
		if not (item is Dictionary):
			continue
		var candidate := Dictionary(item)
		var id := String(candidate.get(_item_key, ""))
		if not by_weight.is_empty() and not by_weight.has(id):
			continue
		filtered.append(candidate.duplicate(true))
	if active_counts.is_empty() or key_maps.is_empty() or _budget_resolver_script == null:
		return filtered
	var budget_resolver = _budget_resolver_script.new()
	budget_resolver.configure(budget_entries_for_stage(stage_index))
	return budget_resolver.filter_entries(filtered, active_counts, key_maps)

func select_entry_for_stage(stage_index: int, candidates: Array, fallback: Dictionary = {}, roll: float = -1.0, active_counts: Dictionary = {}, key_maps: Array = []) -> Dictionary:
	var allowed := filter_candidates_for_stage(stage_index, candidates, active_counts, key_maps)
	if allowed.is_empty() or _weighted_picker_script == null:
		return fallback.duplicate(true)
	var allowed_ids: Array = []
	for candidate in allowed:
		if candidate is Dictionary:
			allowed_ids.append(String(Dictionary(candidate).get(_item_key, "")))
	var weighted_entries: Array = []
	for weight_item in weight_entries_for_stage(stage_index):
		if not (weight_item is Dictionary):
			continue
		var weight_entry := Dictionary(weight_item)
		var id := String(weight_entry.get(_item_key, ""))
		if allowed_ids.has(id):
			weighted_entries.append(weight_entry.duplicate(true))
	if weighted_entries.is_empty():
		return fallback.duplicate(true)
	var picker = _weighted_picker_script.new()
	picker.configure(weighted_entries, _item_key, _weight_key)
	var selected: Dictionary = picker.pick(roll)
	var selected_id := String(selected.get(_item_key, ""))
	for candidate in allowed:
		if candidate is Dictionary and String(Dictionary(candidate).get(_item_key, "")) == selected_id:
			return Dictionary(candidate).duplicate(true)
	return fallback.duplicate(true)

func _weight_allowed_ids(stage_index: int) -> Array:
	var ids: Array = []
	for item in weight_entries_for_stage(stage_index):
		if item is Dictionary:
			var id := String(Dictionary(item).get(_item_key, ""))
			if not id.is_empty():
				ids.append(id)
	return ids
