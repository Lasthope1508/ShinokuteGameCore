class_name ShinokuteRuntimeDebugSnapshot
extends RefCounted

func build_snapshot(sections: Dictionary = {}) -> Dictionary:
	var snapshot := {"created_unix": Time.get_unix_time_from_system()}
	for key in sections.keys():
		var value = sections.get(key)
		snapshot[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return snapshot

func node_names(parent: Node) -> Array:
	var names: Array = []
	if parent == null:
		return names
	for child in parent.get_children():
		names.append(String(child.name))
	return names
