class_name ShinokuteWeightedPicker
extends RefCounted

var _entries: Array = []
var _item_key := "id"
var _weight_key := "weight"
var _stable_sort := false

func configure(entries: Array, item_key: String = "id", weight_key: String = "weight", config: Dictionary = {}) -> void:
	_entries = []
	_item_key = item_key
	_weight_key = weight_key
	_stable_sort = bool(config.get("stable_sort", false))
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var normalized := Dictionary(entry).duplicate(true)
		if float(normalized.get(_weight_key, 0.0)) <= 0.0:
			continue
		_entries.append(normalized)
	if _stable_sort:
		_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get(_item_key, "")) < String(b.get(_item_key, ""))
		)

func entries() -> Array:
	return _entries.duplicate(true)

func total_weight(excluded_items: Array = []) -> float:
	var total := 0.0
	for entry in _eligible_entries(excluded_items):
		total += float(Dictionary(entry).get(_weight_key, 0.0))
	return total

func pick(roll: float = -1.0, excluded_items: Array = []) -> Dictionary:
	var eligible := _eligible_entries(excluded_items)
	var total := total_weight(excluded_items)
	if eligible.is_empty() or total <= 0.0:
		return {}
	var raw_roll: float = roll
	if raw_roll < 0.0:
		raw_roll = randf()
	var clamped_roll: float = clamp(raw_roll, 0.0, 0.999999)
	var target: float = clamped_roll * total
	var cursor: float = 0.0
	for entry in eligible:
		var item := Dictionary(entry)
		cursor += float(item.get(_weight_key, 0.0))
		if target < cursor:
			return item.duplicate(true)
	return Dictionary(eligible[eligible.size() - 1]).duplicate(true)

func _eligible_entries(excluded_items: Array) -> Array:
	if excluded_items.is_empty():
		return _entries
	var eligible: Array = []
	for entry in _entries:
		var item := Dictionary(entry)
		if excluded_items.has(item.get(_item_key)):
			continue
		eligible.append(item)
	return eligible
