class_name ShinokuteContentTableValidator
extends RefCounted

func validate_table(entries: Array, schema: Dictionary) -> Dictionary:
	var errors: Array = []
	var normalized: Array = []
	var id_key := String(schema.get("id_key", "id"))
	var seen_ids := {}
	for index in range(entries.size()):
		if not (entries[index] is Dictionary):
			errors.append({"code": "entry_not_dictionary", "index": index})
			continue
		var entry := Dictionary(entries[index]).duplicate(true)
		normalized.append(entry)
		for field in Array(schema.get("required", [])):
			var field_name := String(field)
			if not entry.has(field_name) or str(entry.get(field_name, "")).is_empty():
				errors.append({"code": "missing_required", "index": index, "field": field_name})
		var id := str(entry.get(id_key, ""))
		if id.is_empty():
			errors.append({"code": "missing_id", "index": index, "field": id_key})
		elif seen_ids.has(id):
			errors.append({"code": "duplicate_id", "index": index, "id": id})
		else:
			seen_ids[id] = true
		for field_name in Dictionary(schema.get("types", {})).keys():
			if not entry.has(field_name):
				continue
			var expected_type := int(Dictionary(schema.get("types", {})).get(field_name, TYPE_NIL))
			if expected_type != TYPE_NIL and typeof(entry.get(field_name)) != expected_type:
				errors.append({"code": "type_mismatch", "index": index, "field": field_name, "expected": expected_type, "actual": typeof(entry.get(field_name))})
		for ref_item in Array(schema.get("refs", [])):
			if not (ref_item is Dictionary):
				continue
			var ref := Dictionary(ref_item)
			var field := String(ref.get("field", ""))
			if field.is_empty() or not entry.has(field):
				continue
			var value = entry.get(field)
			if not Array(ref.get("allowed", [])).has(value):
				errors.append({"code": "missing_ref", "index": index, "field": field, "value": value})
	return {"valid": errors.is_empty(), "errors": errors, "entries": normalized}
