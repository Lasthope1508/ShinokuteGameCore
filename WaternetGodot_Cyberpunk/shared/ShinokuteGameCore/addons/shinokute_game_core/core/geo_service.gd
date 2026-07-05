class_name GeoService
extends Node

signal geolocation_resolved(country_code: String, country_name: String, continent_code: String)

var save_store: Node
var geolocation_url: String = ""
var _request: HTTPRequest

func configure(store: Node, url: String = "") -> void:
	save_store = store
	geolocation_url = url

func resolve_geolocation() -> int:
	if geolocation_url.strip_edges().is_empty():
		return ERR_UNAVAILABLE
	if _request == null:
		_request = HTTPRequest.new()
		_request.accept_gzip = false
		add_child(_request)
		_request.request_completed.connect(_on_request_completed)
	return _request.request(geolocation_url, PackedStringArray(["User-Agent: GodotGameClient"]))

func apply_geolocation_response(data: Dictionary) -> bool:
	if save_store == null:
		return false
	var country_code := String(data.get("country_code", "")).strip_edges()
	var country_name := String(data.get("country_name", "")).strip_edges()
	var continent_code := String(data.get("continent_code", "")).strip_edges()
	if country_code.is_empty() and country_name.is_empty() and continent_code.is_empty():
		return false
	save_store.set_geolocation(country_code, country_name, continent_code)
	geolocation_resolved.emit(country_code, country_name, continent_code)
	return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		geolocation_resolved.emit(save_store.get_country_code(), save_store.get_country_name(), save_store.get_continent_code())
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK and json.get_data() is Dictionary:
		apply_geolocation_response(json.get_data())
	else:
		geolocation_resolved.emit(save_store.get_country_code(), save_store.get_country_name(), save_store.get_continent_code())
