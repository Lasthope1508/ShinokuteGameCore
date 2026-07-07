extends SceneTree

const SessionScript := preload("res://addons/shinokute_game_core/core/game_session.gd")
const RulesScript := preload("res://addons/shinokute_game_core/core/game_rules_adapter.gd")

class FakeRules:
	extends Node
	var moves: Array = []

	func start_run(context: Dictionary) -> void:
		moves.clear()
		moves.append({"start": context})

	func can_make_move(move: Dictionary) -> bool:
		return move.get("valid", false)

	func apply_move(move: Dictionary) -> Dictionary:
		moves.append(move)
		return {"score_delta": int(move.get("score", 0)), "events": ["move_applied"]}

	func is_game_over() -> bool:
		return moves.size() >= 3

	func get_result() -> Dictionary:
		return {"moves": moves.size()}

var _passed := true
var _score_events: Array = []
var _ended: Array = []

func _init() -> void:
	var base_rules = RulesScript.new()
	_assert_true(not base_rules.can_make_move({}), "base rules reject moves")
	_assert_eq(base_rules.apply_move({}), {}, "base rules apply empty result")

	var session = SessionScript.new()
	var rules = FakeRules.new()
	session.configure(rules)
	session.score_changed.connect(func(score: int, delta: int): _score_events.append({"score": score, "delta": delta}))
	session.session_ended.connect(func(result: Dictionary): _ended.append(result))

	_assert_eq(session.start_run("classic", {"seed": 7}), OK, "start run")
	_assert_eq(session.mode, "classic", "mode stored")
	_assert_true(session.is_running(), "session running")
	_assert_eq(session.apply_move({"valid": false, "score": 5}), ERR_INVALID_PARAMETER, "invalid move rejected")
	_assert_eq(session.apply_move({"valid": true, "score": 10}), OK, "valid move accepted")
	_assert_eq(session.score, 10, "score updated")
	_assert_eq(_score_events[0]["delta"], 10, "score signal delta")
	_assert_eq(session.apply_move({"valid": true, "score": 2}), OK, "second move accepted")
	_assert_true(not session.is_running(), "game over stops session")
	_assert_eq(_ended[0]["moves"], 3, "result from rules")
	_report("test_game_session_contract")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
