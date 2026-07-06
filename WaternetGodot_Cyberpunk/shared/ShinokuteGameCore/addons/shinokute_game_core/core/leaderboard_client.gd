class_name LeaderboardClient
extends Node

signal score_submitted(success: bool, mode: String)
signal leaderboard_loaded(tab: String, scores: Array, mode: String)

var config: Resource
var save_store: Node

var _submit_request: HTTPRequest
var _query_request: HTTPRequest

func configure(core_config: Resource, store: Node) -> void:
	config = core_config
	save_store = store

func build_submit_url(mode: String, device_id: String) -> String:
	return "%s/%s/%s?key=%s" % [
		_docs_url(),
		config.get_collection(mode),
		device_id.uri_encode(),
		config.firestore_api_key
	]

func build_query_url() -> String:
	return "%s:runQuery?key=%s" % [_docs_url(), config.firestore_api_key]

func build_score_document(score: int, mode: String, device_id: String) -> Dictionary:
	return {
		"fields": {
			"username": {"stringValue": _username_for_submit()},
			"score": {"integerValue": str(score)},
			"score_label": {"stringValue": config.get_score_label(mode)},
			"country_code": {"stringValue": save_store.get_country_code()},
			"country_name": {"stringValue": save_store.get_country_name()},
			"continent_code": {"stringValue": save_store.get_continent_code()},
			"device_id": {"stringValue": device_id},
			"game_id": {"stringValue": config.game_id},
			"mode": {"stringValue": mode},
			"timestamp": {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}

func build_query_payload(tab: String, mode: String) -> Dictionary:
	var query := {
		"structuredQuery": {
			"from": [{"collectionId": config.get_collection(mode)}],
			"orderBy": [{
				"field": {"fieldPath": "score"},
				"direction": config.get_sort_direction(mode)
			}],
			"limit": config.leaderboard_limit
		}
	}
	if tab == "continent" and not save_store.get_continent_code().is_empty():
		query["structuredQuery"]["where"] = _region_filter("continent_code", save_store.get_continent_code())
	elif tab == "country" and not save_store.get_country_code().is_empty():
		query["structuredQuery"]["where"] = _region_filter("country_code", save_store.get_country_code())
	return query

func submit_score(score: int, mode: String = "classic") -> int:
	if config == null or save_store == null:
		return ERR_UNAVAILABLE
	if score <= 0:
		return ERR_INVALID_PARAMETER
	if _username_for_submit().is_empty():
		return ERR_UNAVAILABLE
	if _submit_request == null:
		_submit_request = HTTPRequest.new()
		_submit_request.accept_gzip = false
		add_child(_submit_request)
		_submit_request.request_completed.connect(_on_submit_request_completed)
	var device_id: String = save_store.get_device_uuid()
	_submit_request.set_meta("mode", mode)
	_submit_request.set_meta("score", score)
	var headers := PackedStringArray(["Content-Type: application/json"])
	return _submit_request.request(
		build_submit_url(mode, device_id),
		headers,
		HTTPClient.METHOD_PATCH,
		JSON.stringify(build_score_document(score, mode, device_id))
	)

func fetch_leaderboard(tab: String, mode: String = "classic") -> int:
	if config == null or save_store == null:
		return ERR_UNAVAILABLE
	if _query_request == null:
		_query_request = HTTPRequest.new()
		_query_request.accept_gzip = false
		add_child(_query_request)
		_query_request.request_completed.connect(_on_query_request_completed)
	_query_request.set_meta("tab", tab)
	_query_request.set_meta("mode", mode)
	var headers := PackedStringArray(["Content-Type: application/json"])
	return _query_request.request(
		build_query_url(),
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(build_query_payload(tab, mode))
	)

func _on_submit_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var mode := String(_submit_request.get_meta("mode", "classic"))
	var score := int(_submit_request.get_meta("score", 0))
	var success := result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204)
	if success:
		var last_submitted: int = save_store.get_last_submitted_score(mode)
		if _is_score_better_or_equal(score, last_submitted, mode):
			save_store.set_last_submitted_score(score, mode)
		var pending: int = save_store.get_pending_score(mode)
		if pending > 0 and _is_score_better_or_equal(score, pending, mode):
			save_store.clear_pending_score(mode)
	score_submitted.emit(success, mode)

func _on_query_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tab := String(_query_request.get_meta("tab", "world"))
	var mode := String(_query_request.get_meta("mode", "classic"))
	var scores: Array = []
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		scores = parse_firestore_scores(body.get_string_from_utf8())
	leaderboard_loaded.emit(tab, scores, mode)

func parse_firestore_scores(json_text: String) -> Array:
	var parsed: Array = []
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return parsed
	var data = json.get_data()
	if not (data is Array):
		return parsed
	for item in data:
		if not (item is Dictionary) or not item.has("document"):
			continue
		var fields: Dictionary = item["document"].get("fields", {})
		parsed.append({
			"username": fields.get("username", {}).get("stringValue", "Anonymous"),
			"score": int(fields.get("score", {}).get("integerValue", "0")),
			"score_label": fields.get("score_label", {}).get("stringValue", "score"),
			"country_code": fields.get("country_code", {}).get("stringValue", ""),
			"country_name": fields.get("country_name", {}).get("stringValue", ""),
			"game_id": fields.get("game_id", {}).get("stringValue", ""),
			"mode": fields.get("mode", {}).get("stringValue", "")
		})
	return parsed

func _docs_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % config.firebase_project_id

func _username_for_submit() -> String:
	var username: String = save_store.get_username().strip_edges()
	return username

func _is_score_better_or_equal(candidate: int, current: int, mode: String) -> bool:
	if candidate <= 0:
		return false
	if current <= 0:
		return true
	var direction: String = config.get_sort_direction(mode)
	if direction == "DESCENDING":
		return candidate >= current
	return candidate <= current

func _region_filter(field: String, value: String) -> Dictionary:
	return {
		"fieldFilter": {
			"field": {"fieldPath": field},
			"op": "EQUAL",
			"value": {"stringValue": value}
		}
	}
