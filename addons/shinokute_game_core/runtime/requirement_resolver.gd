class_name ShinokuteRequirementResolver
extends RefCounted

func is_met(requirement, context: Dictionary = {}) -> bool:
	return _missing(requirement, context).is_empty()

func missing_requirements(requirement, context: Dictionary = {}) -> Array:
	return _missing(requirement, context)

func _missing(requirement, context: Dictionary) -> Array:
	if requirement == null:
		return []
	if requirement is Array:
		var missing_from_array: Array = []
		for item in requirement:
			missing_from_array.append_array(_missing(item, context))
		return missing_from_array
	if not (requirement is Dictionary):
		return []
	var req := Dictionary(requirement)
	if req.has("all"):
		var missing_all: Array = []
		for item in Array(req.get("all", [])):
			missing_all.append_array(_missing(item, context))
		return missing_all
	if req.has("any"):
		var collected_missing: Array = []
		for item in Array(req.get("any", [])):
			var item_missing := _missing(item, context)
			if item_missing.is_empty():
				return []
			collected_missing.append_array(item_missing)
		return collected_missing
	if req.has("not"):
		return [{"code": "not_failed"}] if _missing(req.get("not"), context).is_empty() else []
	if req.has("flag"):
		var flag := String(req.get("flag", ""))
		return [] if bool(Dictionary(context.get("flags", {})).get(flag, false)) else [{"code": "missing_flag", "flag": flag}]
	if req.has("tag"):
		var tag := String(req.get("tag", ""))
		return [] if Array(context.get("tags", [])).has(tag) else [{"code": "missing_tag", "tag": tag}]
	if req.has("count_group"):
		var group := String(req.get("count_group", ""))
		var key := String(req.get("key", ""))
		var minimum := int(req.get("min", 1))
		var count := int(Dictionary(Dictionary(context.get("counts", {})).get(group, {})).get(key, 0))
		return [] if count >= minimum else [{"code": "missing_count", "group": group, "key": key, "required": minimum, "actual": count}]
	return []
