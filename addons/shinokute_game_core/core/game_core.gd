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
const GameSessionScript := preload("game_session.gd")
const ThemeManagerScript := preload("../services/theme_manager.gd")
const SettingsScript := preload("../services/settings_manager.gd")
const AudioHapticsScript := preload("../services/audio_haptics_manager.gd")
const AnalyticsScript := preload("../services/analytics_tracker.gd")
const AdsScript := preload("../services/ads_manager.gd")
const LocalizationScript := preload("../services/localization_service.gd")
const RemoteConfigScript := preload("../services/remote_config_service.gd")
const SceneRouterScript := preload("../ux/scene_router.gd")
const OverlayManagerScript := preload("../ux/overlay_manager.gd")
const PauseControllerScript := preload("../runtime/pause_controller.gd")
const InputBindingManagerScript := preload("../runtime/input_binding_manager.gd")
const SpawnPoolScript := preload("../runtime/spawn_pool.gd")
const InteractionBusScript := preload("../runtime/interaction_bus.gd")
const ScenePreloadCacheScript := preload("../runtime/scene_preload_cache.gd")
const ResourceRegistryScript := preload("../runtime/resource_registry.gd")

var config: Resource
var save_store: Node
var profile: Node
var leaderboard: Node
var geo_service: Node
var session: Node
var theme_manager: Node
var settings: Node
var audio_haptics: Node
var analytics: Node
var ads: Node
var localization: Node
var remote_config: Node
var scene_router: Node
var overlay_manager: Node
var pause_controller: Node
var input_bindings: Node
var spawn_pool: Node
var interaction_bus: Node
var scene_preload_cache: Node
var resource_registry: Node

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

	theme_manager = ThemeManagerScript.new()
	add_child(theme_manager)
	if config.get("theme_config") != null:
		theme_manager.configure(config.get("theme_config"))

	settings = SettingsScript.new()
	add_child(settings)
	settings.configure(config, save_store)

	audio_haptics = AudioHapticsScript.new()
	add_child(audio_haptics)
	audio_haptics.configure(theme_manager)
	_apply_audio_settings()
	settings.setting_changed.connect(_on_setting_changed)

	analytics = AnalyticsScript.new()
	add_child(analytics)
	analytics.configure(config.get("analytics_config"))

	ads = AdsScript.new()
	add_child(ads)
	ads.configure(config.get("ad_placements"), bool(config.get("ads_enabled")))

	localization = LocalizationScript.new()
	add_child(localization)
	localization.configure(String(config.get("default_locale")), config.get("translations"), String(config.get("fallback_locale")))

	remote_config = RemoteConfigScript.new()
	add_child(remote_config)
	remote_config.configure_defaults(config.get("remote_defaults"))

	scene_router = SceneRouterScript.new()
	add_child(scene_router)
	scene_router.configure(config.get("scene_routes"))

	overlay_manager = OverlayManagerScript.new()
	add_child(overlay_manager)
	overlay_manager.configure(config.get("overlay_scenes"))

	pause_controller = PauseControllerScript.new()
	add_child(pause_controller)

	input_bindings = InputBindingManagerScript.new()
	add_child(input_bindings)
	input_bindings.configure(config.get("input_bindings"))
	input_bindings.apply_bindings()

	spawn_pool = SpawnPoolScript.new()
	add_child(spawn_pool)

	interaction_bus = InteractionBusScript.new()
	add_child(interaction_bus)

	scene_preload_cache = ScenePreloadCacheScript.new()
	add_child(scene_preload_cache)
	scene_preload_cache.preload_many(config.get("preload_scene_paths"))

	resource_registry = ResourceRegistryScript.new()
	add_child(resource_registry)
	resource_registry.configure(config.get("resource_registry"))

	session = GameSessionScript.new()
	add_child(session)

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

func _is_score_better(new_score: int, current: int, mode: String) -> bool:
	if new_score <= 0:
		return false
	if current <= 0:
		return true
	var direction: String = config.get_sort_direction(mode)
	if direction == "DESCENDING":
		return new_score > current
	return new_score < current

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

func configure_rules_adapter(rules_adapter: Node) -> void:
	if session != null:
		session.configure(rules_adapter)

func start_run(mode: String = "classic", context: Dictionary = {}) -> int:
	if session == null:
		return ERR_UNAVAILABLE
	return session.start_run(mode, context)

func _on_setting_changed(key: String, value: Variant) -> void:
	if audio_haptics == null:
		return
	if key == SettingsScript.KEY_SFX_ENABLED and audio_haptics.has_method("set_sfx_enabled"):
		audio_haptics.set_sfx_enabled(bool(value))
	elif key == SettingsScript.KEY_BGM_ENABLED and audio_haptics.has_method("set_bgm_enabled"):
		audio_haptics.set_bgm_enabled(bool(value))

func _apply_audio_settings() -> void:
	if settings == null or audio_haptics == null:
		return
	if audio_haptics.has_method("set_sfx_enabled"):
		audio_haptics.set_sfx_enabled(settings.is_sfx_enabled())
	if audio_haptics.has_method("set_bgm_enabled"):
		audio_haptics.set_bgm_enabled(settings.is_bgm_enabled())
