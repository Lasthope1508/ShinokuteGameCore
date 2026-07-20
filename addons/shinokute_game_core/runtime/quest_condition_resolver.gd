class_name ShinokuteQuestConditionResolver
extends RefCounted

func evaluate(condition: Dictionary, counters: Dictionary) -> Dictionary:
	var id := String(condition.get("id", "")).strip_edges()
	var counter_key := String(condition.get("counter", "")).strip_edges()
	var operator := String(condition.get("operator", ">=")).strip_edges()
	var required := float(condition.get("value", 0.0))
	if counter_key.is_empty():
		return {"id": id, "passed": false, "error": "missing_counter", "current": 0.0, "required": required}
	var current := float(counters.get(counter_key, 0.0))
	var passed := false
	match operator:
		">=":
			passed = current >= required
		">":
			passed = current > required
		"<=":
			passed = current <= required
		"<":
			passed = current < required
		"==":
			passed = is_equal_approx(current, required)
		"!=":
			passed = not is_equal_approx(current, required)
		_:
			return {"id": id, "passed": false, "error": "unknown_operator", "current": current, "required": required}
	return {"id": id, "passed": passed, "counter": counter_key, "operator": operator, "current": current, "required": required}

func evaluate_all(conditions: Array, counters: Dictionary) -> Dictionary:
	var reports: Array = []
	var passed := true
	for item in conditions:
		if not (item is Dictionary):
			continue
		var report := evaluate(Dictionary(item), counters)
		reports.append(report)
		if not bool(report.get("passed", false)):
			passed = false
	return {"passed": passed, "conditions": reports}
