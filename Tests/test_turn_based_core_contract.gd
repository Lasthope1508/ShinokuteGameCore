extends SceneTree

const TurnActionReportPath := "res://addons/shinokute_game_core/runtime/turn_action_report.gd"
const TurnEnergySchedulerPath := "res://addons/shinokute_game_core/runtime/turn_energy_scheduler.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_turn_action_report()
	_test_turn_energy_scheduler()
	_report("test_turn_based_core_contract")

func _test_turn_action_report() -> void:
	var script: Script = load(TurnActionReportPath)
	_assert_true(script != null, "turn action report script loads")
	if script == null:
		return
	var report = script.new()
	report.accept("player", "move", {"from": Vector2i.ZERO, "to": Vector2i.RIGHT}, 100.0)
	report.add_effect("move_actor", {"target": Vector2i.RIGHT})
	report.add_event("footstep", {"actor_id": "player"})
	report.add_message("player_moved", {"tone": "neutral"})
	var packed: Dictionary = report.to_dictionary()
	_assert_true(bool(packed.get("accepted", false)), "turn report stores accepted state")
	_assert_eq(String(packed.get("actor_id", "")), "player", "turn report stores actor id")
	_assert_eq(String(packed.get("action_id", "")), "move", "turn report stores action id")
	_assert_float_eq(float(packed.get("energy_cost", 0.0)), 100.0, 0.001, "turn report stores energy cost")
	_assert_eq(String(Dictionary(Array(packed.get("effects", []))[0]).get("type", "")), "move_actor", "turn report stores effects")
	_assert_eq(String(Dictionary(Array(packed.get("messages", []))[0]).get("key", "")), "player_moved", "turn report stores message keys")
	report.block("player", "move", "stunned", {"turn": 4})
	packed = report.to_dictionary()
	_assert_true(not bool(packed.get("accepted", true)), "blocked turn report clears accepted state")
	_assert_eq(String(packed.get("block_reason", "")), "stunned", "blocked turn report stores reason")

func _test_turn_energy_scheduler() -> void:
	var script: Script = load(TurnEnergySchedulerPath)
	_assert_true(script != null, "turn energy scheduler script loads")
	if script == null:
		return
	var scheduler = script.new()
	scheduler.configure([
		{"id": "player", "speed": 100.0, "energy": 0.0, "priority": 10},
		{"id": "slug", "speed": 50.0, "energy": 50.0, "priority": 0},
		{"id": "bat", "speed": 150.0, "energy": 0.0, "priority": 0}
	], {"ready_threshold": 100.0})
	var ready: Array = scheduler.advance(1.0)
	_assert_eq(_ids(ready), ["bat", "player", "slug"], "scheduler orders ready actors by energy then priority then stable order")
	_assert_true(scheduler.spend("bat", 100.0), "scheduler spends actor energy")
	_assert_float_eq(scheduler.energy_for("bat"), 50.0, 0.001, "scheduler leaves overflow energy after spend")
	_assert_true(scheduler.spend("player", 100.0), "scheduler spends player energy")
	_assert_true(scheduler.spend("slug", 100.0), "scheduler spends slug energy")
	ready = scheduler.advance(1.0)
	_assert_eq(_ids(ready), ["bat", "player"], "scheduler keeps slower actor below threshold after spend")
	var snapshot: Dictionary = scheduler.snapshot()
	scheduler.spend("bat", 100.0)
	_assert_float_eq(scheduler.energy_for("bat"), 100.0, 0.001, "scheduler mutates after snapshot")
	scheduler.restore(snapshot)
	_assert_float_eq(scheduler.energy_for("bat"), 200.0, 0.001, "scheduler restores actor energy")

func _ids(entries: Array) -> Array:
	var ids: Array = []
	for item in entries:
		if item is Dictionary:
			ids.append(String(Dictionary(item).get("id", "")))
	return ids

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error("FAIL: %s" % label)

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("FAIL: %s expected=%s actual=%s" % [label, str(expected), str(actual)])

func _assert_float_eq(actual: float, expected: float, epsilon: float, label: String) -> void:
	if abs(actual - expected) > epsilon:
		_passed = false
		push_error("FAIL: %s expected=%s actual=%s" % [label, str(expected), str(actual)])

func _report(label: String) -> void:
	if _passed:
		print("%s: PASS" % label)
		quit(0)
	else:
		print("%s: FAIL" % label)
		quit(1)
