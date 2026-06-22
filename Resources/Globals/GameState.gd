## Volatile state of the current run: score, best score, ad usage.
## Other systems listen to this autoload's signals to update the HUD or react
## to game-over events. Persistent values come from SaveManager.
extends Node

const POINTS_PER_CELL: int = 1
const POINTS_PER_CLEARED_CELL: int = 2
const MAX_AD_REWARDS: int = 2
# Cap on assisted refill re-rolls per run. Past this, the first random draw is
# accepted as-is so the difficulty curve isn't softened indefinitely.
const MAX_ASSISTS: int = 3

signal score_changed(new_score: int, delta: int)
signal best_changed(new_best: int)
signal game_over
signal game_reset

var current_score: int = 0
var best_score: int = 0
var ad_rewards_used: int = 0
var assists_used: int = 0
var is_game_over: bool = false


func _ready() -> void:
	best_score = SaveManager.get_best_score()


# Resets run-time state for a new game. Best score is preserved.
func reset_run() -> void:
	current_score = 0
	ad_rewards_used = 0
	assists_used = 0
	is_game_over = false
	score_changed.emit(current_score, 0)
	game_reset.emit()


# Adds the placement bonus and returns the credited delta.
func award_placement(cells_count: int) -> int:
	var delta: int = cells_count * POINTS_PER_CELL
	_add_score(delta)
	return delta


# Combo multiplier = number of clear events (row/col/quadrant) when >= 2, else 1.
func compute_combo(rows_cleared: int, cols_cleared: int, quadrants_cleared: int) -> int:
	var events: int = rows_cleared + cols_cleared + quadrants_cleared
	return events if events >= 2 else 1


# Credits the clear bonus (combo-multiplied) and returns the delta.
func award_clears(cells_cleared: int, combo: int) -> int:
	var delta: int = cells_cleared * POINTS_PER_CLEARED_CELL * max(1, combo)
	_add_score(delta)
	return delta


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	if current_score > best_score:
		best_score = current_score
		SaveManager.set_best_score(best_score)
		best_changed.emit(best_score)
	game_over.emit()


func consume_ad_reward() -> bool:
	if ad_rewards_used >= MAX_AD_REWARDS:
		return false
	ad_rewards_used += 1
	is_game_over = false
	return true


func _add_score(delta: int) -> void:
	if delta == 0:
		return
	current_score += delta
	score_changed.emit(current_score, delta)
	if current_score > best_score:
		best_score = current_score
		SaveManager.set_best_score(best_score)
		best_changed.emit(best_score)
