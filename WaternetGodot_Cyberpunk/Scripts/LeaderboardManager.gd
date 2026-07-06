## Compatibility facade for legacy game code.
## Canonical leaderboard/profile behavior lives in ShinokuteGameCore through GameCoreManager.
extends Node

signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool)
signal geolocation_resolved

const GAME_CORE_CONFIG_PATH := "res://Resources/Data/glyphflow_game_core_config.tres"

var _core_config: Resource

func _ready() -> void:
	_core_config = load(GAME_CORE_CONFIG_PATH)
	if has_node("/root/GameCoreManager") and GameCoreManager.core != null:
		GameCoreManager.leaderboard_loaded.connect(func(tab: String, scores: Array, mode: String): leaderboard_loaded.emit(tab, scores, mode))
		GameCoreManager.score_submitted.connect(func(success: bool, _mode: String): score_submitted.emit(success))
		if GameCoreManager.core.geo_service != null:
			GameCoreManager.core.geo_service.geolocation_resolved.connect(func(_country_code: String, _country_name: String, _continent_code: String): geolocation_resolved.emit())

func resolve_geolocation() -> void:
	if has_node("/root/GameCoreManager"):
		var err := GameCoreManager.resolve_geolocation()
		if err != OK:
			geolocation_resolved.emit()

func submit_score(score: int, mode: String = GameState.start_mode) -> void:
	if score <= 0:
		return
	if not has_node("/root/GameCoreManager"):
		score_submitted.emit(false)
		return
	var err := GameCoreManager.submit_score(score, mode)
	if err != OK:
		score_submitted.emit(false)

func fetch_leaderboard(tab: String, mode: String = GameState.start_mode) -> void:
	if not has_node("/root/GameCoreManager"):
		leaderboard_loaded.emit(tab, [], mode)
		return
	var err := GameCoreManager.fetch_leaderboard(tab, mode)
	if err != OK:
		leaderboard_loaded.emit(tab, [], mode)
