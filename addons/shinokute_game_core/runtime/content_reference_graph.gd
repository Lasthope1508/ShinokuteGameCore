class_name ShinokuteContentReferenceGraph
extends RefCounted

var _errors: Array = []

func validate(tables: Dictionary, schemas: Dictionary) -> Dictionary:
	_errors = []
	for table_name in schemas.keys():
		var schema := Dictionary(schemas.get(table_name, {}))
		var table = tables.get(table_name)
		if table == null:
			continue
		for ref in Array(schema.get("refs", [])):
			if ref is Dictionary:
				_validate_ref(String(table_name), table, Dictionary(ref), tables)
	return {"valid": _errors.is_empty(), "errors": _errors.duplicate(true)}

func errors() -> Array:
	return _errors.duplicate(true)

func _validate_ref(source_table_name: String, source_table, ref: Dictionary, tables: Dictionary) -> void:
	var field := String(ref.get("field", ""))
	var target_table_name := String(ref.get("table", ""))
	if field.is_empty() or target_table_name.is_empty():
		return
	if not tables.has(target_table_name):
		_errors.append({"code": "missing_ref_table", "table": source_table_name, "field": field, "target_table": target_table_name})
		return
	var target_table = tables.get(target_table_name)
	for entry in source_table.entries(true):
		var source_entry := Dictionary(entry)
		if not source_entry.has(field):
			continue
		for value in _as_array(source_entry.get(field)):
			var target_id := String(value).strip_edges()
			if target_id.is_empty():
				continue
			if not target_table.has_id(target_id):
				_errors.append({
					"code": "missing_ref",
					"table": source_table_name,
					"id": String(source_entry.get(source_table.id_key(), "")),
					"field": field,
					"value": target_id,
					"target_table": target_table_name
				})

func _as_array(value) -> Array:
	if value is Array:
		return Array(value)
	return [value]
