extends Node

signal score_changed(score: int, old_score: int)
signal best_changed(best: int)
signal game_reset()

var best_score: int = 0
var current_score: int = 0
var ad_rewards_used: int = 0
var is_game_over: bool = false

# Waternet-specific states
var current_level_id: int = 1
var max_unlocked_level_id: int = 1
var start_mode: String = "classic"
