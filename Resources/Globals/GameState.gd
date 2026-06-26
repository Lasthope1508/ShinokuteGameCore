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
var current_streak: int = 0
var start_mode: String = "classic"
var turns_without_clear: int = 0

const ROTATION_ENERGY_COST: float = 30.0
var chain_energy: float = 0.0
signal chain_energy_changed(new_energy: float)


func _ready() -> void:
	best_score = SaveManager.get_best_score()


# Resets run-time state for a new game. Best score is preserved.
func reset_run() -> void:
	current_score = 0
	ad_rewards_used = 0
	assists_used = 0
	is_game_over = false
	current_streak = 0
	turns_without_clear = 0
	chain_energy = 0.0
	chain_energy_changed.emit(chain_energy)
	best_score = SaveManager.get_best_score(start_mode)
	score_changed.emit(current_score, 0)
	best_changed.emit(best_score)
	game_reset.emit()


func increment_streak() -> int:
	current_streak += 1
	return current_streak


func reset_streak() -> void:
	current_streak = 0


# Adds the placement bonus and returns the credited delta.
func award_placement(cells_count: int) -> int:
	var delta: int = cells_count * POINTS_PER_CELL
	_add_score(delta)
	return delta


# Combo multiplier = number of clear events (row/col) when >= 2, else 1.
func compute_combo(rows_cleared: int, cols_cleared: int) -> int:
	var events: int = rows_cleared + cols_cleared
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
		SaveManager.set_best_score(best_score, start_mode)
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
		SaveManager.set_best_score(best_score, start_mode)
		best_changed.emit(best_score)


# Cumulative score required to clear `level`. L0=0, L1=100, L2=250, L3=450, …
# Analytical level targets follow: 25 * level^2 + 75 * level
func get_target_for_level(level: int) -> int:
	return 25 * level * level + 75 * level


# Highest level whose target is ≤ score.
func get_level_for_score(score: int) -> int:
	if score <= 0:
		return 0
	# Quadratic formula solver for 25*L^2 + 75*L - S = 0
	# L = (-75 + sqrt(5625 + 100 * score)) / 50
	return int((-75.0 + sqrt(5625.0 + 100.0 * score)) / 50.0)

