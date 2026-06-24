## coordinates global and regional leaderboard score submissions and queries
## using the Firebase Firestore REST API.
extends Node

signal leaderboard_loaded(tab: String, scores: Array)
signal score_submitted(success: bool)
signal geolocation_resolved

const FIRESTORE_API_KEY := "AIzaSyCn3QkPRiv1vq6jZ-TBfTDF9bDhEMYTpr0"
const FIRESTORE_DOCS_URL := "https://firestore.googleapis.com/v1/projects/foodapp-7ff6b/databases/(default)/documents"
const GEOLOCATION_URL := "https://foodapp-7ff6b.web.app/api/location"

var player_country_code: String = ""
var player_country_name: String = ""
var player_continent_code: String = ""

var _geo_request: HTTPRequest
var _submit_request: HTTPRequest
var _query_request: HTTPRequest
var _is_submitting: bool = false

func _ready() -> void:
	# Load cached geo data first
	player_country_code = SaveManager.get_country_code()
	player_country_name = SaveManager.get_country_name()
	player_continent_code = SaveManager.get_continent_code()
	
	# Instantiate HTTPRequest nodes
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
	
	# If no cached geolocation, fetch it
	if player_country_code == "":
		resolve_geolocation()
		
	# Auto-submit high score if it has not been submitted yet
	var best = SaveManager.get_best_score()
	if best > SaveManager.get_last_submitted_score():
		submit_score(best)



func resolve_geolocation() -> void:
	print("LeaderboardManager: Resolving geolocation from: ", GEOLOCATION_URL)
	var headers: PackedStringArray = ["User-Agent: GodotGameClient"]
	var err = _geo_request.request(GEOLOCATION_URL, headers)
	if err != OK:
		push_warning("LeaderboardManager: Failed to start geo request (err %d)" % err)


func submit_score(score: int) -> void:
	if score <= 0:
		return
		
	if score <= SaveManager.get_last_submitted_score():
		print("LeaderboardManager: Score %d is not higher than last submitted score (%d). Skipping." % [score, SaveManager.get_last_submitted_score()])
		return
		
	if _is_submitting:
		print("LeaderboardManager: Score submission already in progress. Skipping.")
		return
		
	var username = SaveManager.get_username()
	if username == "":
		username = "Player_%s" % SaveManager.get_device_uuid().substr(0, 5)
		SaveManager.set_username(username)
		
	var device_id = SaveManager.get_device_uuid()
	
	# Create document payload according to Firestore REST API JSON structure
	var document = {
		"fields": {
			"username": {"stringValue": username},
			"score": {"integerValue": str(score)},
			"country_code": {"stringValue": player_country_code},
			"country_name": {"stringValue": player_country_name},
			"continent_code": {"stringValue": player_continent_code},
			"device_id": {"stringValue": device_id},
			"timestamp": {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}
	
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	# We use the device_id as the document ID in Firestore!
	# This ensures each player (device) can only have ONE entry in the leaderboard collection,
	# and writing again will overwrite/update their score!
	var url = FIRESTORE_DOCS_URL + "/leaderboard/" + device_id + "?key=" + FIRESTORE_API_KEY
	
	_is_submitting = true
	_submit_request.set_meta("submitted_score", score)
	
	print("LeaderboardManager: Submitting score %d for %s (device: %s)..." % [score, username, device_id])
	# Send a PATCH request to create or replace the document (writes to Firestore)
	var err = _submit_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(document))
	if err != OK:
		_is_submitting = false
		push_warning("LeaderboardManager: Failed to start score submit request (err %d)" % err)
		score_submitted.emit(false)



func fetch_leaderboard(tab: String) -> void:
	# Auto-submit any unsubmitted high score first
	var best = SaveManager.get_best_score()
	if _is_submitting:
		print("LeaderboardManager: A score submission is already in progress. Waiting for it...")
		await score_submitted
	elif best > SaveManager.get_last_submitted_score():
		print("LeaderboardManager: Found unsubmitted high score %d. Submitting first..." % best)
		submit_score(best)
		await score_submitted
		
	# tab can be: "world", "continent", "country"
	var query_url = FIRESTORE_DOCS_URL + ":runQuery?key=" + FIRESTORE_API_KEY

	
	var structured_query = {
		"structuredQuery": {
			"from": [{"collectionId": "leaderboard"}],
			"orderBy": [{
				"field": {"fieldPath": "score"},
				"direction": "DESCENDING"
			}],
			"limit": 15
		}
	}
	
	# Add regional filters for continent/country tabs
	if tab == "continent" and player_continent_code != "":
		structured_query["structuredQuery"]["where"] = {
			"fieldFilter": {
				"field": {"fieldPath": "continent_code"},
				"op": "EQUAL",
				"value": {"stringValue": player_continent_code}
			}
		}
	elif tab == "country" and player_country_code != "":
		structured_query["structuredQuery"]["where"] = {
			"fieldFilter": {
				"field": {"fieldPath": "country_code"},
				"op": "EQUAL",
				"value": {"stringValue": player_country_code}
			}
		}
		
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	# Save the active tab as metadata in the request (so we can pass it to the callback)
	_query_request.set_meta("active_tab", tab)
	
	print("LeaderboardManager: Fetching leaderboard tab: %s..." % tab)
	var err = _query_request.request(query_url, headers, HTTPClient.METHOD_POST, JSON.stringify(structured_query))
	if err != OK:
		push_warning("LeaderboardManager: Failed to start query request (err %d)" % err)
		leaderboard_loaded.emit(tab, [])


# Callbacks
func _on_geo_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				player_country_code = data.get("country_code", "VN")
				player_country_name = data.get("country_name", "Vietnam")
				player_continent_code = data.get("continent_code", "AS")
				
				# Cache it
				SaveManager.set_country_code(player_country_code)
				SaveManager.set_country_name(player_country_name)
				SaveManager.set_continent_code(player_continent_code)
				
				print("LeaderboardManager: Resolved geolocation to %s (%s, %s)" % [player_country_name, player_country_code, player_continent_code])
				geolocation_resolved.emit()
				return
	
	# Fallback if request fails
	player_country_code = "VN"
	player_country_name = "Vietnam"
	player_continent_code = "AS"
	
	SaveManager.set_country_code(player_country_code)
	SaveManager.set_country_name(player_country_name)
	SaveManager.set_continent_code(player_continent_code)
	
	print("LeaderboardManager: Geolocation request failed. Saved fallback: Vietnam (VN, AS)")
	geolocation_resolved.emit()



func _on_submit_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_submitting = false
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
		print("LeaderboardManager: Score submitted successfully! Response code: %d" % response_code)
		var submitted_score = _submit_request.get_meta("submitted_score") if _submit_request.has_meta("submitted_score") else 0
		if submitted_score > SaveManager.get_last_submitted_score():
			SaveManager.set_last_submitted_score(submitted_score)
		score_submitted.emit(true)
	else:
		var body_str = body.get_string_from_utf8()
		push_warning("LeaderboardManager: Score submission failed (result %d, response code %d). Body: %s" % [result, response_code, body_str])
		score_submitted.emit(false)



func _on_query_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var tab = _query_request.get_meta("active_tab") if _query_request.has_meta("active_tab") else "world"
	var parsed_scores = []
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Array:
				for item in data:
					if item is Dictionary and item.has("document"):
						var doc = item["document"]
						if doc.has("fields"):
							var fields = doc["fields"]
							var username = fields.get("username", {}).get("stringValue", "Anonymous")
							var score = int(fields.get("score", {}).get("integerValue", "0"))
							var country_code = fields.get("country_code", {}).get("stringValue", "")
							var country_name = fields.get("country_name", {}).get("stringValue", "")
							parsed_scores.append({
								"username": username,
								"score": score,
								"country_code": country_code,
								"country_name": country_name
							})
		print("LeaderboardManager: Fetched %d scores for tab %s successfully!" % [parsed_scores.size(), tab])
	else:
		var body_str = body.get_string_from_utf8()
		push_warning("LeaderboardManager: Query failed (result %d, response code %d). Body: %s" % [result, response_code, body_str])
	leaderboard_loaded.emit(tab, parsed_scores)
