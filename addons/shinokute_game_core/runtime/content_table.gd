class_name ShinokuteContentTable
extends RefCounted

var _table_name := ""
var _id_key := "id"
var _raw_by_id: Dictionary = {}
var _order: Array[String] = []
var _resolved_by_id: Dictionary = {}
var _errors: Array = []

func configure(table_name: String, entries: Array, schema: Dictionary = {}) -> void:
	_table_name = table_name
	_id_key = String(schema.get("id_key", "id"))
	_raw_by_id = {}
	_order = []
	_resolved_by_id = {}
	_errors = []
	for index in range(entries.size()):
		if not (entries[index] is Dictionary):
			_errors.append({"code": "entry_not_dictionary", "table": _table_name, "index": index})
			continue
		var entry := Dictionary(entries[index]).duplicate(true)
		var id := String(entry.get(_id_key, "")).strip_edges()
		if id.is_empty():
			_errors.append({"code": "missing_id", "table": _table_name, "index": index, "field": _id_key})
			continue
		if _raw_by_id.has(id):
			_errors.append({"code": "duplicate_id", "table": _table_name, "index": index, "id": id})
			continue
		entry[_id_key] = id
		_raw_by_id[id] = entry
		_order.append(id)
	for id in _order:
		_resolve_entry(id, [])

func table_name() -> String:
	return _table_name

func id_key() -> String:
	return _id_key

func errors() -> Array:
	return _errors.duplicate(true)

func ids(include_abstract: bool = true) -> Array:
	var result: Array = []
	for id in _order:
		if not include_abstract and bool(Dictionary(_resolved_by_id.get(id, {})).get("abstract", false)):
			continue
		result.append(id)
	return result

func entries(include_abstract: bool = false) -> Array:
	var result: Array = []
	for id in _order:
		var entry := entry_for_id(id)
		if entry.is_empty():
			continue
		if not include_abstract and bool(entry.get("abstract", false)):
			continue
		result.append(entry)
	return result

func entry_for_id(id: String) -> Dictionary:
	if not _resolved_by_id.has(id):
		return {}
	return Dictionary(_resolved_by_id[id]).duplicate(true)

func has_id(id: String) -> bool:
	return _resolved_by_id.has(id)

func _resolve_entry(id: String, visiting: Array) -> Dictionary:
	if _resolved_by_id.has(id):
		return Dictionary(_resolved_by_id[id]).duplicate(true)
	if visiting.has(id):
		_errors.append({"code": "copy_from_cycle", "table": _table_name, "id": id, "chain": visiting.duplicate()})
		return {}
	if not _raw_by_id.has(id):
		_errors.append({"code": "copy_from_missing", "table": _table_name, "id": id})
		return {}
	var raw := Dictionary(_raw_by_id[id]).duplicate(true)
	var parent_id := String(raw.get("copy_from", "")).strip_edges()
	var resolved := raw
	if not parent_id.is_empty():
		if not _raw_by_id.has(parent_id):
			_errors.append({"code": "copy_from_missing", "table": _table_name, "id": id, "copy_from": parent_id})
		else:
			var next_visiting := visiting.duplicate()
			next_visiting.append(id)
			var parent := _resolve_entry(parent_id, next_visiting)
			resolved = _merge_dicts(parent, raw)
			if bool(parent.get("abstract", false)) and not raw.has("abstract"):
				resolved["abstract"] = false
	resolved[_id_key] = id
	_resolved_by_id[id] = resolved
	return resolved.duplicate(true)

func _merge_dicts(base: Dictionary, override: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	for key in override.keys():
		var key_string := String(key)
		var value = override[key]
		if key_string == "tags" and merged.has(key) and merged[key] is Array and value is Array:
			merged[key] = _merge_arrays_unique(Array(merged[key]), Array(value))
		elif merged.has(key) and merged[key] is Dictionary and value is Dictionary:
			merged[key] = _merge_dicts(Dictionary(merged[key]), Dictionary(value))
		else:
			merged[key] = value
	return merged

func _merge_arrays_unique(base: Array, override: Array) -> Array:
	var merged := base.duplicate(true)
	for item in override:
		if not merged.has(item):
			merged.append(item)
	return merged
