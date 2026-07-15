class_name ShinokuteBudgetResolver
extends RefCounted

var _budgets: Array = []
var _validation_errors: Array[String] = []

func configure(budgets: Array) -> void:
	_budgets = []
	_validation_errors = []
	for item in budgets:
		if not (item is Dictionary):
			_validation_errors.append("budget entry must be a dictionary")
			continue
		var raw := Dictionary(item)
		var group := String(raw.get("group", ""))
		var key := String(raw.get("key", ""))
		var max_count := int(raw.get("max", -1))
		if group.is_empty():
			_validation_errors.append("budget group is required")
			continue
		if key.is_empty():
			_validation_errors.append("budget key is required")
			continue
		if max_count < 0:
			_validation_errors.append("budget max must be zero or greater")
			continue
		_budgets.append({"group": group, "key": key, "max": max_count})

func budgets() -> Array:
	return _budgets.duplicate(true)

func validation_errors() -> Array[String]:
	return _validation_errors.duplicate()

func filter_entries(entries: Array, counts: Dictionary = {}, key_maps: Array = []) -> Array:
	var filtered: Array = []
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		if is_allowed(entry, counts, key_maps):
			filtered.append(entry.duplicate(true))
	return filtered

func is_allowed(entry: Dictionary, counts: Dictionary = {}, key_maps: Array = []) -> bool:
	for item in key_maps:
		if not (item is Dictionary):
			continue
		var key_map := Dictionary(item)
		var group := String(key_map.get("group", ""))
		var entry_key := String(key_map.get("entry_key", ""))
		var count_group := String(key_map.get("count_group", group))
		if group.is_empty() or entry_key.is_empty():
			continue
		var key := String(entry.get(entry_key, ""))
		if key.is_empty():
			continue
		var max_count := _max_for(group, key)
		if max_count < 0:
			continue
		var active_count := _count_for(counts, count_group, key)
		if active_count >= max_count:
			return false
	return true

func _max_for(group: String, key: String) -> int:
	for item in _budgets:
		var budget := Dictionary(item)
		if String(budget.get("group", "")) == group and String(budget.get("key", "")) == key:
			return int(budget.get("max", -1))
	return -1

func _count_for(counts: Dictionary, count_group: String, key: String) -> int:
	var group_counts := Dictionary(counts.get(count_group, {}))
	return int(group_counts.get(key, 0))
