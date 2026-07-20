class_name ShinokuteEvolutionResolver
extends RefCounted

const QuestConditionResolverScript := preload("res://addons/shinokute_game_core/runtime/quest_condition_resolver.gd")

var condition_resolver: RefCounted

func _init() -> void:
	condition_resolver = QuestConditionResolverScript.new()

func resolve_ready(evolutions: Array, counters: Dictionary, already_unlocked: Array = []) -> Dictionary:
	for item in evolutions:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		var id := String(entry.get("id", "")).strip_edges()
		if id.is_empty() or already_unlocked.has(id):
			continue
		var result_id := String(entry.get("result_id", "")).strip_edges()
		var requirements := Array(entry.get("requirements", []))
		var report: Dictionary = condition_resolver.evaluate_all(requirements, counters)
		if bool(report.get("passed", false)):
			return {"ready": true, "id": id, "result_id": result_id, "requirements": report.get("conditions", [])}
	return {"ready": false, "id": "", "result_id": "", "requirements": []}

func resolve_all_ready(evolutions: Array, counters: Dictionary, already_unlocked: Array = []) -> Array:
	var ready: Array = []
	var unlocked: Array = already_unlocked.duplicate()
	while true:
		var result: Dictionary = resolve_ready(evolutions, counters, unlocked)
		if not bool(result.get("ready", false)):
			break
		ready.append(result)
		unlocked.append(String(result.get("id", "")))
	return ready
