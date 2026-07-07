class_name ExampleRules
extends GameRulesAdapter

var _score := 0
var _moves := 0
var _max_moves := 20

func start_run(context: Dictionary) -> void:
	_score = 0
	_moves = 0
	_max_moves = int(context.get("max_moves", 20))

func can_make_move(move: Dictionary) -> bool:
	return move.has("value") and int(move.get("value", 0)) > 0

func apply_move(move: Dictionary) -> Dictionary:
	_moves += 1
	var delta := int(move.get("value", 0))
	_score += delta
	return {
		"score_delta": delta,
		"events": ["move_applied"]
	}

func is_game_over() -> bool:
	return _moves >= _max_moves

func get_result() -> Dictionary:
	return {
		"score": _score,
		"moves": _moves
	}
