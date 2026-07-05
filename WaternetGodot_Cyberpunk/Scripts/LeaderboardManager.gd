## Coordinates global and regional leaderboard score submissions and queries
## using GameCoreConfig as SSOT for Firebase and scoring contracts.
extends Node

signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool)
signal geolocation_resolved

const GAME_CORE_CONFIG_PATH := "res://Resources/Data/glyphflow_game_core_config.tres"

var player_country_code: String = ""
var player_country_name: String = ""
var player_continent_code: String = ""

var _core_config: Resource
var _geo_request: HTTPRequest
var _submit_request: HTTPRequest
var _query_request: HTTPRequest
var _is_submitting: bool = false
var _submit_queue: Array = []

func _ready() -> void:
	if not _load_core_config():
		return

	player_country_code = SaveManager.get_country_code()
	player_country_name = SaveManager.get_country_name()
	player_continent_code = SaveManager.get_continent_code()

	_geo_request = HTTPRequest.new()
	_geo_request.accept_gzip = false
	add_child(_geo_request)
	_geo_request.request_completed.connect(_on_geo_request_completed)

	_submit_request = HTTPRequest.new()
	_submit_request.accept_gzip = false
	add_child(_submit_request)
	_submit_request.request_completed.connect(_on_submit_request_completed)

	_query_request = HTTPRequest.new()
	_query_request.accept_gzip = false
	add_child(_query_request)
	_query_request.request_completed.connect(_on_query_request_completed)

	if player_country_code == "":
		resolve_geolocation()

	var best_classic := SaveManager.get_best_score("classic")
	if _is_score_better_than_previous(best_classic, SaveManager.get_last_submitted_score("classic"), "classic"):
		submit_score(best_classic, "classic")

func resolve_geolocation() -> void:
	if not _require_core_config("resolve geolocation"):
		return
	var geolocation_url := String(_core_config.get("geolocation_url"))
	if geolocation_url.strip_edges().is_empty():
		geolocation_resolved.emit()
		return
	print("LeaderboardManager: Resolving geolocation from: ", geolocation_url)
	var err := _geo_request.request(geolocation_url, PackedStringArray(["User-Agent: GodotGameClient"]))
	if err != OK:
		push_warning("LeaderboardManager: Failed to start geo request (err %d)" % err)

func submit_score(score: int, mode: String = GameState.start_mode) -> void:
	if score <= 0:
		return

	var last_submitted := SaveManager.get_last_submitted_score(mode)
	if not _is_score_better_than_previous(score, last_submitted, mode):
		print("LeaderboardManager: Score %d is not better than last submitted score (%d) for %s. Skipping." % [score, last_submitted, mode])
		return

	for item in _submit_queue:
		if item["mode"] == mode:
			if _is_score_better_than_previous(score, int(item["score"]), mode):
				item["score"] = score
			return

	_submit_queue.append({"score": score, "mode": mode})
	_process_submit_queue()

func fetch_leaderboard(tab: String, mode: String = GameState.start_mode) -> void:
	var best := SaveManager.get_best_score(mode)
	if _is_submitting:
		print("LeaderboardManager: A score submission is already in progress. Waiting for it...")
		await score_submitted
	elif _is_score_better_than_previous(best, SaveManager.get_last_submitted_score(mode), mode):
		print("LeaderboardManager: Found unsubmitted high score %d for %s. Submitting first..." % [best, mode])
		submit_score(best, mode)
		await score_submitted

	if not _require_core_config("fetch leaderboard"):
		leaderboard_loaded.emit(tab, [], mode)
		return

	var collection: String = _core_config.get_collection(mode)
	if collection.is_empty():
		push_error("LeaderboardManager: missing leaderboard collection for mode %s" % mode)
		leaderboard_loaded.emit(tab, [], mode)
		return

	var structured_query := {
		"structuredQuery": {
			"from": [{"collectionId": collection}],
			"orderBy": [{
				"field": {"fieldPath": "score"},
				"direction": _core_config.get_sort_direction(mode)
			}],
			"limit": int(_core_config.get("leaderboard_limit"))
		}
	}

	if tab == "continent" and player_continent_code != "":
		structured_query["structuredQuery"]["where"] = _region_filter("continent_code", player_continent_code)
	elif tab == "country" and player_country_code != "":
		structured_query["structuredQuery"]["where"] = _region_filter("country_code", player_country_code)

	_query_request.set_meta("active_tab", tab)
	_query_request.set_meta("active_mode", mode)

	print("LeaderboardManager: Fetching leaderboard tab: %s (mode: %s, collection: %s)..." % [tab, mode, collection])
	var err := _query_request.request(
		_get_firestore_docs_url() + ":runQuery?key=" + String(_core_config.get("firestore_api_key")),
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(structured_query)
	)
	if err != OK:
		push_warning("LeaderboardManager: Failed to start query request (err %d)" % err)
		leaderboard_loaded.emit(tab, [], mode)

func _process_submit_queue() -> void:
	if _is_submitting or _submit_queue.is_empty():
		return
	if not _require_core_config("submit score"):
		score_submitted.emit(false)
		return

	var next = _submit_queue.pop_front()
	var score := int(next["score"])
	var mode := String(next["mode"])
	var collection: String = _core_config.get_collection(mode)
	if collection.is_empty():
		push_error("LeaderboardManager: missing leaderboard collection for mode %s" % mode)
		score_submitted.emit(false)
		return

	var username := SaveManager.get_username()
	if username == "":
		username = "%s_%s" % [String(_core_config.get("default_username_prefix")), SaveManager.get_device_uuid().substr(0, 5)]
		SaveManager.set_username(username)

	var device_id := SaveManager.get_device_uuid()
	var document := {
		"fields": {
			"username": {"stringValue": username},
			"score": {"integerValue": str(score)},
			"score_label": {"stringValue": _core_config.get_score_label(mode)},
			"country_code": {"stringValue": player_country_code},
			"country_name": {"stringValue": player_country_name},
			"continent_code": {"stringValue": player_continent_code},
			"device_id": {"stringValue": device_id},
			"game_id": {"stringValue": String(_core_config.get("game_id"))},
			"mode": {"stringValue": mode},
			"timestamp": {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}

	_is_submitting = true
	_submit_request.set_meta("submitted_score", score)
	_submit_request.set_meta("submitted_mode", mode)

	var url := _get_firestore_docs_url() + "/" + collection + "/" + device_id + "?key=" + String(_core_config.get("firestore_api_key"))
	print("LeaderboardManager: Submitting score %d for %s (mode: %s, collection: %s, device: %s)..." % [score, username, mode, collection, device_id])
	var err := _submit_request.request(url, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_PATCH, JSON.stringify(document))
	if err != OK:
		_is_submitting = false
		push_warning("LeaderboardManager: Failed to start score submit request (err %d)" % err)
		score_submitted.emit(false)
		_process_submit_queue()

func _on_geo_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				player_country_code = String(data.get("country_code", ""))
				player_country_name = String(data.get("country_name", ""))
				player_continent_code = String(data.get("continent_code", ""))
				SaveManager.set_country_code(player_country_code)
				SaveManager.set_country_name(player_country_name)
				SaveManager.set_continent_code(player_continent_code)
				print("LeaderboardManager: Resolved geolocation to %s (%s, %s)" % [player_country_name, player_country_code, player_continent_code])
				geolocation_resolved.emit()
				return

	print("LeaderboardManager: Geolocation request failed. Keeping cached/blank region; no fallback country is invented.")
	geolocation_resolved.emit()

func _on_submit_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_submitting = false
	var submitted_mode := String(_submit_request.get_meta("submitted_mode", "classic"))
	var submitted_score := int(_submit_request.get_meta("submitted_score", 0))
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
		print("LeaderboardManager: Score submitted successfully for %s! Response code: %d" % [submitted_mode, response_code])
		if _is_score_better_than_previous(submitted_score, SaveManager.get_last_submitted_score(submitted_mode), submitted_mode):
			SaveManager.set_last_submitted_score(submitted_score, submitted_mode)
		score_submitted.emit(true)
	else:
		push_warning("LeaderboardManager: Score submission failed for %s (result %d, response code %d). Body: %s" % [submitted_mode, result, response_code, body.get_string_from_utf8()])
		score_submitted.emit(false)
	_process_submit_queue()

func _on_query_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tab := String(_query_request.get_meta("active_tab", "world"))
	var mode := String(_query_request.get_meta("active_mode", "classic"))
	var parsed_scores: Array = []

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Array:
				for item in data:
					if item is Dictionary and item.has("document"):
						var fields: Dictionary = item["document"].get("fields", {})
						parsed_scores.append({
							"username": fields.get("username", {}).get("stringValue", "Anonymous"),
							"score": int(fields.get("score", {}).get("integerValue", "0")),
							"score_label": fields.get("score_label", {}).get("stringValue", _core_config.get_score_label(mode)),
							"country_code": fields.get("country_code", {}).get("stringValue", ""),
							"country_name": fields.get("country_name", {}).get("stringValue", ""),
							"game_id": fields.get("game_id", {}).get("stringValue", ""),
							"mode": fields.get("mode", {}).get("stringValue", "")
						})
		print("LeaderboardManager: Fetched %d scores for tab %s (%s) successfully!" % [parsed_scores.size(), tab, mode])
	else:
		push_warning("LeaderboardManager: Query failed (result %d, response code %d). Body: %s" % [result, response_code, body.get_string_from_utf8()])
	leaderboard_loaded.emit(tab, parsed_scores, mode)

func _load_core_config() -> bool:
	_core_config = load(GAME_CORE_CONFIG_PATH)
	if _core_config == null:
		push_error("LeaderboardManager: missing GameCoreConfig at %s" % GAME_CORE_CONFIG_PATH)
		return false
	if _core_config.has_method("validate_config"):
		var errors: Array = _core_config.validate_config()
		if not errors.is_empty():
			push_error("LeaderboardManager: invalid GameCoreConfig: %s" % ", ".join(errors))
			return false
	return true

func _require_core_config(action: String) -> bool:
	if _core_config != null:
		return true
	push_error("LeaderboardManager: cannot %s without GameCoreConfig" % action)
	return false

func _get_firestore_docs_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % String(_core_config.get("firebase_project_id"))

func _is_score_better_than_previous(score: int, previous: int, mode: String) -> bool:
	if score <= 0:
		return false
	if previous <= 0:
		return true
	if _core_config != null and _core_config.get_sort_direction(mode) == "ASCENDING":
		return score < previous
	return score > previous

func _region_filter(field: String, value: String) -> Dictionary:
	return {
		"fieldFilter": {
			"field": {"fieldPath": field},
			"op": "EQUAL",
			"value": {"stringValue": value}
		}
	}
