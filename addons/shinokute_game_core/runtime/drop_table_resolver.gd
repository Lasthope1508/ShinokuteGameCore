class_name ShinokuteDropTableResolver
extends RefCounted

var _requirement_resolver: RefCounted

func configure(requirement_resolver_path = null) -> void:
	_requirement_resolver = null
	if requirement_resolver_path == null:
		return
	var script: Script
	if requirement_resolver_path is Script:
		script = requirement_resolver_path
	else:
		script = load(String(requirement_resolver_path)) as Script
	if script != null:
		_requirement_resolver = script.new()

func resolve(entries: Array, context: Dictionary = {}, rolls: Array = []) -> Array:
	var drops: Array = []
	var roll_index := 0
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		if not _requirements_met(entry, context):
			continue
		var chance := clamp(float(entry.get("chance", 1.0)), 0.0, 1.0)
		var roll := _roll_at(rolls, roll_index)
		roll_index += 1
		if roll > chance:
			continue
		var drop := entry.duplicate(true)
		drop["quantity"] = int(max(1, int(drop.get("quantity", 1))))
		drops.append(drop)
	return drops

func _requirements_met(entry: Dictionary, context: Dictionary) -> bool:
	if not entry.has("requirements"):
		return true
	if _requirement_resolver == null or not _requirement_resolver.has_method("is_met"):
		return false
	return bool(_requirement_resolver.is_met(entry.get("requirements"), context))

func _roll_at(rolls: Array, index: int) -> float:
	if index >= 0 and index < rolls.size():
		return clamp(float(rolls[index]), 0.0, 1.0)
	return randf()
