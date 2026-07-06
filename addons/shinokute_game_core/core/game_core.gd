class_name GameCore
extends Node

signal username_required
signal profile_ready(username: String)
signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool, mode: String)

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
	profile.profile_ready.connect(func(_username: String): flush_pending_scores())

	leaderboard = LeaderboardClientScript.new()
	add_child(leaderboard)
	leaderboard.configure(config, save_store)
	leaderboard.leaderboard_loaded.connect(func(tab: String, scores: Array, mode: String): leaderboard_loaded.emit(tab, scores, mode))
	leaderboard.score_submitted.connect(func(success: bool, mode: String): score_submitted.emit(success, mode))

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
	_record_local_score(value, mode)
	save_store.set_pending_score(_best_pending_score(value, mode), mode)
	if save_store.get_username().strip_edges().is_empty():
		ensure_profile_ready()
		return ERR_UNAVAILABLE
	var err: int = leaderboard.submit_score(value, mode)
	if err != OK:
		return err
	return OK

func flush_pending_scores() -> int:
	if leaderboard == null or save_store == null:
		return ERR_UNAVAILABLE
	if save_store.get_username().strip_edges().is_empty():
		return ERR_UNAVAILABLE
	var modes: Array[String] = _configured_modes()
	var status: int = OK
	for mode in modes:
		var pending: int = save_store.get_pending_score(mode)
		if pending <= 0:
			continue
		var err: int = leaderboard.submit_score(pending, mode)
		if err != OK:
			status = err
	return status

func _record_local_score(value: int, mode: String) -> void:
	var best: int = save_store.get_best_score(mode)
	if _is_score_better(value, best, mode):
		save_store.set_best_score(value, mode)

func _best_pending_score(value: int, mode: String) -> int:
	var pending: int = save_store.get_pending_score(mode)
	if _is_score_better(value, pending, mode):
		return value
	return pending

func _is_score_better(candidate: int, current: int, mode: String) -> bool:
	if candidate <= 0:
		return false
	if current <= 0:
		return true
	var direction: String = config.get_sort_direction(mode)
	if direction == "DESCENDING":
		return candidate > current
	return candidate < current

func _configured_modes() -> Array[String]:
	var modes: Array[String] = []
	for mode in config.leaderboard_collections.keys():
		var key := String(mode)
		if key != "default" and not modes.has(key):
			modes.append(key)
	if modes.is_empty():
		modes.append("classic")
	return modes

func fetch_leaderboard(tab: String, mode: String = "classic") -> int:
	if leaderboard == null:
		return ERR_UNAVAILABLE
	return leaderboard.fetch_leaderboard(tab, mode)
