class_name GameCoreConfig
extends Resource

@export var game_id: String = ""
@export var display_name: String = ""
@export var firebase_project_id: String = ""
@export var firestore_api_key: String = ""
@export var geolocation_url: String = ""

@export var username_min_length: int = 3
@export var username_max_length: int = 15
@export var allow_skip_username: bool = true
@export var require_username_on_first_launch: bool = true
@export var default_username_prefix: String = "Player"

@export var leaderboard_limit: int = 15
@export var leaderboard_collections: Dictionary = {}
@export var score_labels: Dictionary = {}
@export var score_sort_directions: Dictionary = {}

@export var theme_config: Resource
@export var theme_token_schema: Dictionary = {}
@export var scene_routes: Dictionary = {}
@export var overlay_scenes: Dictionary = {}
@export var ad_placements: Dictionary = {}
@export var analytics_config: Dictionary = {}
@export var remote_defaults: Dictionary = {}
@export var input_bindings: Dictionary = {}
@export var preload_scene_paths: Array = []
@export var resource_registry: Dictionary = {}
@export var settings_defaults: Dictionary = {
	"sfx_enabled": true,
	"bgm_enabled": true,
	"shift_lock_enabled": false
}
@export var translations: Dictionary = {}
@export var progression_catalog: Resource
@export var default_locale: String = "en"
@export var ads_enabled: bool = true

const SORT_ASCENDING := "ASCENDING"
const SORT_DESCENDING := "DESCENDING"

func validate_config() -> Array[String]:
	var errors: Array[String] = []
	if game_id.strip_edges().is_empty():
		errors.append("game_id is required")
	if firebase_project_id.strip_edges().is_empty():
		errors.append("firebase_project_id is required")
	if firestore_api_key.strip_edges().is_empty():
		errors.append("firestore_api_key is required")
	if leaderboard_collections.is_empty():
		errors.append("leaderboard_collections must define at least one mode")
	for mode in leaderboard_collections.keys():
		var collection := String(leaderboard_collections.get(mode, "")).strip_edges()
		if collection.is_empty():
			errors.append("collection for %s is empty" % String(mode))
		var direction := get_sort_direction(String(mode))
		if direction != SORT_ASCENDING and direction != SORT_DESCENDING:
			errors.append("sort direction for %s must be ASCENDING or DESCENDING" % String(mode))
	if username_min_length < 1:
		errors.append("username_min_length must be >= 1")
	if username_max_length < username_min_length:
		errors.append("username_max_length must be >= username_min_length")
	if progression_catalog != null and progression_catalog.has_method("validate"):
		for error in progression_catalog.validate():
			errors.append("progression_catalog: %s" % error)
	return errors

func is_username_required() -> bool:
	return require_username_on_first_launch

func get_collection(mode: String) -> String:
	var key := mode.strip_edges()
	if leaderboard_collections.has(key):
		return String(leaderboard_collections[key])
	if leaderboard_collections.has("default"):
		return String(leaderboard_collections["default"])
	return ""

func get_score_label(mode: String) -> String:
	var key := mode.strip_edges()
	if score_labels.has(key):
		return String(score_labels[key])
	if score_labels.has("default"):
		return String(score_labels["default"])
	return "score"

func get_sort_direction(mode: String) -> String:
	var key := mode.strip_edges()
	var value := String(score_sort_directions.get(key, score_sort_directions.get("default", SORT_DESCENDING))).to_upper()
	if value == SORT_ASCENDING:
		return SORT_ASCENDING
	return SORT_DESCENDING

func get_setting_default(key: String, missing_value: Variant = null) -> Variant:
	if settings_defaults.has(key):
		return settings_defaults[key]
	return missing_value

func validate_username(username: String) -> Array[String]:
	var errors: Array[String] = []
	var value := username.strip_edges()
	if value.length() < username_min_length:
		errors.append("Username must be at least %d characters." % username_min_length)
	if value.length() > username_max_length:
		errors.append("Username cannot exceed %d characters." % username_max_length)
	if value.contains("\n") or value.contains("\r") or value.contains("\t"):
		errors.append("Username cannot contain control whitespace.")
	return errors
