class_name GameRulesAdapter
extends Node

func start_run(_context: Dictionary) -> void:
	pass

func can_make_move(_move: Dictionary) -> bool:
	return false

func apply_move(_move: Dictionary) -> Dictionary:
	return {}

func is_game_over() -> bool:
	return false

func calculate_score(event: Dictionary) -> int:
	return int(event.get("score_delta", event.get("score", 0)))

func get_result() -> Dictionary:
	return {}
