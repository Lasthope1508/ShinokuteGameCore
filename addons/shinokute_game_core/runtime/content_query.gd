class_name ShinokuteContentQuery
extends RefCounted

var _requirement_resolver_script: Script

func configure(options: Dictionary = {}) -> void:
	_requirement_resolver_script = options.get("requirement_resolver_script", null)

func filter(entries: Array, criteria: Dictionary = {}) -> Array:
	var result: Array = []
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		if not _matches_type(entry, criteria):
			continue
		if not _matches_tags(entry, criteria):
			continue
		if not _matches_requirements(entry, criteria):
			continue
		result.append(entry.duplicate(true))
	return result

func _matches_type(entry: Dictionary, criteria: Dictionary) -> bool:
	if not criteria.has("type"):
		return true
	return String(entry.get("type", "")) == String(criteria.get("type", ""))

func _matches_tags(entry: Dictionary, criteria: Dictionary) -> bool:
	if not criteria.has("tags"):
		return true
	var required_tags := Array(criteria.get("tags", []))
	var entry_tags := Array(entry.get("tags", []))
	for tag in required_tags:
		if not entry_tags.has(tag):
			return false
	return true

func _matches_requirements(entry: Dictionary, criteria: Dictionary) -> bool:
	if not entry.has("requirements"):
		return true
	if _requirement_resolver_script == null:
		return true
	var resolver = _requirement_resolver_script.new()
	return resolver.is_met(entry.get("requirements"), Dictionary(criteria.get("context", {})))
