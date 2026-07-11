extends SceneTree

const CORE_ADDON := "res://addons/shinokute_game_core/core/game_core.gd"
const CORE_CONFIG := "res://Resources/Data/Core/candy_sky_islands_game_core_config.tres"
const BRIDGE_SCRIPT := "res://scripts/candy_game_core_bridge.gd"
const LEADERBOARD_PANEL_SCRIPT := "res://scripts/candy_leaderboard_panel.gd"
const MAIN_SCENE := "res://scenes/main.tscn"

func _init() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(CORE_ADDON), "Candy should install ShinokuteGameCore addon") and passed
	passed = _assert_true(ResourceLoader.exists(CORE_CONFIG), "Candy should own a GameCoreConfig resource") and passed
	passed = _assert_true(FileAccess.file_exists(BRIDGE_SCRIPT), "Candy should own a thin GameCore bridge") and passed
	passed = _assert_true(FileAccess.file_exists(LEADERBOARD_PANEL_SCRIPT), "Candy should own a thin leaderboard UI panel") and passed
	passed = _assert_file_contains(MAIN_SCENE, "candy_game_core_bridge.gd", "Main scene should wire Candy bridge") and passed
	passed = _assert_file_contains(MAIN_SCENE, "candy_sky_islands_game_core_config.tres", "Main scene should bind GameCoreConfig as exported Resource") and passed
	passed = _assert_file_contains(MAIN_SCENE, "[node name=\"LeaderboardButton\" type=\"Button\" parent=\"HUD\"]", "HUD should expose a leaderboard button") and passed
	passed = _assert_file_contains(MAIN_SCENE, "[node name=\"LeaderboardPanel\" type=\"PanelContainer\" parent=\"HUD\"", "HUD should include a leaderboard panel") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "GameCoreScript.new()", "Bridge should instantiate core GameCore") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "core.ensure_profile_ready()", "Bridge should use core username/profile flow") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "core.submit_score", "Bridge should submit scores through core") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "core.fetch_leaderboard", "Bridge should fetch leaderboard through core") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "leaderboard_loaded.emit", "Bridge should forward core leaderboard_loaded signal") and passed
	passed = _assert_file_contains(BRIDGE_SCRIPT, "username_prompt_scene", "Bridge should use configured core username prompt scene") and passed
	passed = _assert_file_contains(LEADERBOARD_PANEL_SCRIPT, "fetch_leaderboard", "Leaderboard UI should fetch through bridge") and passed
	passed = _assert_file_contains(LEADERBOARD_PANEL_SCRIPT, "_on_leaderboard_loaded", "Leaderboard UI should render core leaderboard data") and passed
	passed = _assert_file_not_contains(LEADERBOARD_PANEL_SCRIPT, "HTTPRequest", "Leaderboard UI should not own HTTP requests") and passed
	passed = _assert_file_not_contains(LEADERBOARD_PANEL_SCRIPT, "firestore.googleapis", "Leaderboard UI should not hardcode Firestore URL") and passed
	passed = _assert_file_not_contains(LEADERBOARD_PANEL_SCRIPT, "leaderboard_collections", "Leaderboard UI should not hardcode leaderboard collections") and passed
	passed = _assert_file_not_contains(BRIDGE_SCRIPT, "HTTPRequest", "Bridge should not own HTTP requests") and passed
	passed = _assert_file_not_contains(BRIDGE_SCRIPT, "firestore.googleapis", "Bridge should not hardcode Firestore URL") and passed
	passed = _assert_file_not_contains(BRIDGE_SCRIPT, "leaderboard_collections", "Bridge should not hardcode leaderboard collections") and passed
	passed = _assert_file_not_contains(BRIDGE_SCRIPT, "firebase_project_id", "Bridge should not hardcode Firebase project") and passed
	passed = _assert_file_not_contains(BRIDGE_SCRIPT, "firestore_api_key", "Bridge should not hardcode Firestore key") and passed
	passed = _assert_file_not_contains("res://scripts", "LeaderboardManager", "Candy scripts should not add copied leaderboard manager") and passed

	var config = load(CORE_CONFIG) if ResourceLoader.exists(CORE_CONFIG) else null
	passed = _assert_true(config != null, "GameCoreConfig should load") and passed
	if config != null:
		passed = _assert_true(config.get_script().resource_path.ends_with("game_core_config.gd"), "Config should use Shinokute GameCoreConfig script") and passed
		passed = _assert_true(config.game_id == "candy_sky_islands", "Config should use Candy game id") and passed
		passed = _assert_true(config.display_name == "Candy Sky Islands", "Config should use Candy display name") and passed
		passed = _assert_true(config.leaderboard_collections.get("classic", "") == "candy_sky_islands_classic", "Config should own Candy leaderboard collection") and passed
		passed = _assert_true(config.score_labels.get("classic", "") == "level", "Config should label Candy score") and passed
		passed = _assert_true(config.score_sort_directions.get("classic", "") == "DESCENDING", "Config should sort level score descending") and passed
		passed = _assert_true(config.progression_catalog != null, "Config should reference Candy progression catalog") and passed

	if passed:
		print("test_shinokute_core_leaderboard_username_contract: PASS")
		quit(0)
	else:
		print("test_shinokute_core_leaderboard_username_contract: FAIL")
		quit(1)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if FileAccess.file_exists(path):
		var text := FileAccess.get_file_as_string(path)
		if text.contains(needle):
			push_error("%s: unexpected '%s'" % [message, needle])
			return false
		return true
	var dir := DirAccess.open(path)
	if dir == null:
		return true
	for file in dir.get_files():
		if file.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(path.path_join(file))
			if text.contains(needle):
				push_error("%s: unexpected '%s' in %s" % [message, needle, file])
				return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
