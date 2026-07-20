class_name SkillProgressionResolver
extends RefCounted

var _requirement_resolver_script: Script

func configure(requirement_resolver_script_path = null) -> void:
	_requirement_resolver_script = null
	if requirement_resolver_script_path is Script:
		_requirement_resolver_script = requirement_resolver_script_path
	elif requirement_resolver_script_path is String and not String(requirement_resolver_script_path).strip_edges().is_empty():
		_requirement_resolver_script = load(String(requirement_resolver_script_path)) as Script

func next_level_entry(level_tables: Array, skill_id: String, current_levels: Dictionary = {}) -> Dictionary:
	var clean_skill_id := skill_id.strip_edges()
	if clean_skill_id.is_empty():
		return {"ready": false, "reason": "missing_skill_id"}
	var table := table_for_skill(level_tables, clean_skill_id)
	if table.is_empty():
		return {"ready": false, "reason": "missing_level_table", "skill_id": clean_skill_id}
	var current_level := int(current_levels.get(clean_skill_id, 0))
	var max_level := int(table.get("max_level", 0))
	if max_level > 0 and current_level >= max_level:
		return {"ready": false, "reason": "max_level", "skill_id": clean_skill_id, "level": current_level}
	var wanted_level := current_level + 1
	var level_entry := level_entry_for_level(table, wanted_level)
	if level_entry.is_empty():
		return {"ready": false, "reason": "missing_level_entry", "skill_id": clean_skill_id, "level": wanted_level}
	var result := level_entry.duplicate(true)
	result["ready"] = true
	result["skill_id"] = clean_skill_id
	result["from_level"] = current_level
	result["level"] = wanted_level
	result["taxonomy_id"] = String(table.get("taxonomy_id", result.get("taxonomy_id", "")))
	result["level_table_id"] = String(table.get("id", ""))
	return result

func table_for_skill(level_tables: Array, skill_id: String) -> Dictionary:
	for item in level_tables:
		if item is Dictionary:
			var entry := Dictionary(item)
			if String(entry.get("skill_id", "")).strip_edges() == skill_id:
				return entry.duplicate(true)
	return {}

func level_entry_for_level(level_table: Dictionary, level: int) -> Dictionary:
	for item in Array(level_table.get("levels", [])):
		if item is Dictionary:
			var entry := Dictionary(item)
			if int(entry.get("level", 0)) == level:
				return entry.duplicate(true)
	return {}

func resolve_ready_progression(definitions: Array, counters: Dictionary, already_unlocked: Array = []) -> Dictionary:
	var resolver = _requirement_resolver()
	for item in definitions:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		var id := String(entry.get("id", "")).strip_edges()
		if id.is_empty() or already_unlocked.has(id):
			continue
		var requirements := Array(entry.get("requirements", []))
		if _requirements_are_met(resolver, requirements, counters):
			var result := entry.duplicate(true)
			result["ready"] = true
			return result
	return {"ready": false, "id": "", "reason": "requirements_not_met"}

func resolve_all_ready_progressions(definitions: Array, counters: Dictionary, already_unlocked: Array = []) -> Array:
	var ready: Array = []
	var unlocked := already_unlocked.duplicate()
	while true:
		var result := resolve_ready_progression(definitions, counters, unlocked)
		if not bool(result.get("ready", false)):
			break
		ready.append(result)
		unlocked.append(String(result.get("id", "")))
	return ready

func _requirements_are_met(resolver, requirements: Array, counters: Dictionary) -> bool:
	if requirements.is_empty():
		return true
	for requirement in requirements:
		if not (requirement is Dictionary):
			return false
		var entry := Dictionary(requirement)
		if resolver != null and resolver.has_method("evaluate"):
			if not bool(resolver.evaluate(entry, counters).get("passed", false)):
				return false
		elif not _simple_requirement_met(entry, counters):
			return false
	return true

func _requirement_resolver():
	if _requirement_resolver_script == null:
		return null
	return _requirement_resolver_script.new()

func _simple_requirement_met(requirement: Dictionary, counters: Dictionary) -> bool:
	var key := String(requirement.get("counter", "")).strip_edges()
	if key.is_empty():
		return false
	var current := float(counters.get(key, 0.0))
	var required := float(requirement.get("value", 0.0))
	match String(requirement.get("operator", ">=")):
		">=":
			return current >= required
		">":
			return current > required
		"<=":
			return current <= required
		"<":
			return current < required
		"==":
			return is_equal_approx(current, required)
	return false
