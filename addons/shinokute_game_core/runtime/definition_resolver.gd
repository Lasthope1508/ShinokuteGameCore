class_name ShinokuteDefinitionResolver
extends RefCounted

var _definitions_by_id: Dictionary = {}
var _resolved_entries: Array = []
var _missing_refs: Array[String] = []
var _validation_errors: Array[String] = []
var _weighted_picker_script: Script
var _id_key := "id"
var _weight_key := "weight"

func configure(
	definitions: Array,
	pool_refs: Array = [],
	weighted_picker_script: Script = null,
	id_key: String = "id",
	weight_key: String = "weight"
) -> void:
	_definitions_by_id = {}
	_resolved_entries = []
	_missing_refs = []
	_validation_errors = []
	_weighted_picker_script = weighted_picker_script
	_id_key = id_key
	_weight_key = weight_key

	for raw in definitions:
		if raw is Dictionary:
			_register_definition(Dictionary(raw))

	for raw in pool_refs:
		if not (raw is Dictionary):
			continue
		var pool_ref := Dictionary(raw)
		var resolved := _merge_pool_reference(pool_ref)
		if resolved.is_empty():
			continue
		_resolved_entries.append(resolved)

func definitions() -> Array:
	var entries: Array = []
	for id in _definitions_by_id.keys():
		entries.append(Dictionary(_definitions_by_id[id]).duplicate(true))
	return entries

func resolved_entries() -> Array:
	return _resolved_entries.duplicate(true)

func definition_for_id(id: String) -> Dictionary:
	if not _definitions_by_id.has(id):
		return {}
	return Dictionary(_definitions_by_id[id]).duplicate(true)

func missing_refs() -> Array[String]:
	return _missing_refs.duplicate()

func validation_errors() -> Array[String]:
	return _validation_errors.duplicate()

func pick_unique(count: int = 3, rolls: Array = []) -> Array:
	var remaining := _resolved_entries.duplicate(true)
	var selected: Array = []
	var option_count: int = int(min(max(0, count), remaining.size()))
	for i in range(option_count):
		var picked := _pick_one(remaining, _roll_at(rolls, i))
		if picked.is_empty():
			break
		selected.append(picked.duplicate(true))
		remaining = _without_id(remaining, String(picked.get(_id_key, "")))
	return selected

func _register_definition(raw: Dictionary) -> void:
	var id := String(raw.get(_id_key, "")).strip_edges()
	if id.is_empty():
		_validation_errors.append("definition missing %s" % _id_key)
		return
	if _definitions_by_id.has(id):
		_validation_errors.append("duplicate definition id: %s" % id)
		return
	_definitions_by_id[id] = _normalize_entry(raw)

func _merge_pool_reference(pool_ref: Dictionary) -> Dictionary:
	var id := String(pool_ref.get(_id_key, "")).strip_edges()
	if id.is_empty():
		_validation_errors.append("pool reference missing %s" % _id_key)
		return {}
	if not _definitions_by_id.has(id):
		_missing_refs.append(id)
		return {}
	var merged := Dictionary(_definitions_by_id[id]).duplicate(true)
	for key in pool_ref.keys():
		merged[key] = pool_ref[key]
	if not merged.has(_weight_key):
		merged[_weight_key] = 1
	return _normalize_entry(merged)

func _normalize_entry(raw: Dictionary) -> Dictionary:
	var normalized := Dictionary(raw).duplicate(true)
	normalized[_id_key] = String(normalized.get(_id_key, "")).strip_edges()
	if normalized.get(_weight_key, null) == null:
		normalized[_weight_key] = 1
	return normalized

func _pick_one(entries: Array, roll: float = -1.0) -> Dictionary:
	if entries.is_empty():
		return {}
	if _weighted_picker_script == null:
		return Dictionary(entries[0]).duplicate(true)
	var picker = _weighted_picker_script.new()
	picker.configure(entries, _id_key, _weight_key)
	return picker.pick(roll).duplicate(true)

func _without_id(entries: Array, id: String) -> Array:
	var filtered: Array = []
	for item in entries:
		var entry := Dictionary(item)
		if String(entry.get(_id_key, "")) != id:
			filtered.append(entry)
	return filtered

func _roll_at(rolls: Array, index: int) -> float:
	if index >= 0 and index < rolls.size():
		return float(rolls[index])
	return -1.0
