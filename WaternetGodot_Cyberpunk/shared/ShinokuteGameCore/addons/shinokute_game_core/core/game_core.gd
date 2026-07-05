class_name GameCore
extends Node

signal username_required
signal profile_ready(username: String)
signal leaderboard_loaded(tab: String, scores: Array, mode: String)

const LocalSaveStoreScript := preload("local_save_store.gd")
const PlayerProfileScript := preload("player_profile.gd")
const LeaderboardClientScript := preload("leaderboard_client.gd")
const GeoServiceScript := preload("geo_service.gd")

var config: Resource
var save_store: Node
var profile: Node
var leaderboard: Node
var geo_service: Node

func configure(core_config: Resource, save_path: String = "user://shinokute_game_core.cfg") -> void:
	config = core_config
	save_store = LocalSaveStoreScript.new()
	save_store.save_path = save_path
	add_child(save_store)
	save_store.load_store()

	profile = PlayerProfileScript.new()
	add_child(profile)
	profile.configure(config, save_store)
	profile.username_required.connect(func(): username_required.emit())
	profile.profile_ready.connect(func(username: String): profile_ready.emit(username))

	leaderboard = LeaderboardClientScript.new()
	add_child(leaderboard)
	leaderboard.configure(config, save_store)
	leaderboard.leaderboard_loaded.connect(func(tab: String, scores: Array, mode: String): leaderboard_loaded.emit(tab, scores, mode))

	geo_service = GeoServiceScript.new()
	add_child(geo_service)
	geo_service.configure(save_store, config.geolocation_url)

func ensure_profile_ready() -> void:
	profile.ensure_profile_ready()

func submit_score(score_data: Dictionary) -> int:
	if leaderboard == null:
		return ERR_UNAVAILABLE
	var mode := String(score_data.get("mode", "classic"))
	var value := int(score_data.get("value", 0))
	if value <= 0:
		return ERR_INVALID_PARAMETER
	var best: int = save_store.get_best_score(mode)
	var direction: String = config.get_sort_direction(mode)
	var is_better := false
	if direction == "DESCENDING":
		is_better = value > best
	else:
		is_better = best == 0 or value < best
	if is_better:
		save_store.set_best_score(value, mode)
	return leaderboard.submit_score(value, mode)

func fetch_leaderboard(tab: String, mode: String = "classic") -> int:
	if leaderboard == null:
		return ERR_UNAVAILABLE
	return leaderboard.fetch_leaderboard(tab, mode)
