class_name GameSession
extends Node

signal session_started(mode: String, context: Dictionary)
signal session_paused
signal session_resumed
signal score_changed(score: int, delta: int)
signal session_ended(result: Dictionary)

var rules_adapter: Node
var mode: String = "classic"
var score: int = 0
var context: Dictionary = {}
var started_at: int = 0
var ended_at: int = 0
var _running := false
var _paused := false

func configure(adapter: Node = null) -> void:
	rules_adapter = adapter

func start_run(run_mode: String = "classic", run_context: Dictionary = {}) -> int:
	if rules_adapter == null:
		return ERR_UNCONFIGURED
	mode = run_mode
	context = run_context.duplicate(true)
	score = 0
	started_at = int(Time.get_unix_time_from_system())
	ended_at = 0
	_running = true
	_paused = false
	if rules_adapter.has_method("start_run"):
		rules_adapter.start_run(context)
	session_started.emit(mode, context)
	return OK

func is_running() -> bool:
	return _running

func is_paused() -> bool:
	return _paused

func pause() -> int:
	if not _running:
		return ERR_UNAVAILABLE
	_paused = true
	session_paused.emit()
	return OK

func resume() -> int:
	if not _running:
		return ERR_UNAVAILABLE
	_paused = false
	session_resumed.emit()
	return OK

func apply_move(move: Dictionary) -> int:
	if not _running or _paused:
		return ERR_UNAVAILABLE
	if rules_adapter == null:
		return ERR_UNCONFIGURED
	if rules_adapter.has_method("can_make_move") and not rules_adapter.can_make_move(move):
		return ERR_INVALID_PARAMETER
	var result: Dictionary = {}
	if rules_adapter.has_method("apply_move"):
		result = rules_adapter.apply_move(move)
	var delta := _score_delta_from_result(result)
	if delta != 0:
		add_score(delta)
	if rules_adapter.has_method("is_game_over") and rules_adapter.is_game_over():
		end_run("game_over")
	return OK

func add_score(delta: int) -> void:
	score += delta
	score_changed.emit(score, delta)

func end_run(reason: String = "ended") -> Dictionary:
	if not _running:
		return {}
	_running = false
	_paused = false
	ended_at = int(Time.get_unix_time_from_system())
	var result := {
		"mode": mode,
		"score": score,
		"reason": reason,
		"duration_seconds": max(0, ended_at - started_at)
	}
	if rules_adapter != null and rules_adapter.has_method("get_result"):
		var adapter_result = rules_adapter.get_result()
		if adapter_result is Dictionary:
			for key in adapter_result.keys():
				result[key] = adapter_result[key]
	session_ended.emit(result)
	return result

func _score_delta_from_result(result: Dictionary) -> int:
	if rules_adapter != null and rules_adapter.has_method("calculate_score"):
		return int(rules_adapter.calculate_score(result))
	return int(result.get("score_delta", 0))
