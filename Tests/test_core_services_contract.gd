extends SceneTree

const ThemeConfigScript := preload("res://addons/shinokute_game_core/services/shinokute_theme_config.gd")
const ThemeManagerScript := preload("res://addons/shinokute_game_core/services/theme_manager.gd")
const AudioHapticsScript := preload("res://addons/shinokute_game_core/services/audio_haptics_manager.gd")
const AnalyticsScript := preload("res://addons/shinokute_game_core/services/analytics_tracker.gd")
const AdsScript := preload("res://addons/shinokute_game_core/services/ads_manager.gd")
const LocalizationScript := preload("res://addons/shinokute_game_core/services/localization_service.gd")
const RemoteConfigScript := preload("res://addons/shinokute_game_core/services/remote_config_service.gd")

var _passed := true
var _tracked_events: Array = []
var _ad_events: Array = []

func _init() -> void:
	var theme = ThemeConfigScript.new()
	theme.theme_id = "neon"
	theme.colors = {"accent": Color(1, 0.5, 0)}
	theme.asset_paths = {"logo": "res://logo.png"}
	theme.audio_events = {"tap": "res://tap.wav"}
	var theme_manager = ThemeManagerScript.new()
	theme_manager.configure(theme)
	_assert_eq(theme_manager.get_color("accent"), Color(1, 0.5, 0), "theme color lookup")
	_assert_eq(theme_manager.get_asset_path("logo"), "res://logo.png", "theme asset lookup")
	_assert_eq(theme_manager.get_audio_path("tap"), "res://tap.wav", "theme audio lookup")

	var audio = AudioHapticsScript.new()
	audio.configure(theme_manager)
	_assert_eq(audio.get_audio_path("tap"), "res://tap.wav", "audio event resolves from theme")
	audio.set_haptics_enabled(false)
	_assert_true(not audio.is_haptics_enabled(), "haptics toggle")

	var analytics = AnalyticsScript.new()
	analytics.event_tracked.connect(func(name: String, params: Dictionary): _tracked_events.append({"name": name, "params": params}))
	analytics.track("game_start", {"mode": "classic"})
	_assert_eq(_tracked_events[0]["name"], "game_start", "analytics event name")
	_assert_eq(_tracked_events[0]["params"]["mode"], "classic", "analytics params")

	var ads = AdsScript.new()
	ads.ad_requested.connect(func(placement: String): _ad_events.append(placement))
	ads.configure({"interstitial": {"cooldown_seconds": 30}})
	_assert_true(ads.can_show("interstitial"), "first ad can show")
	_assert_eq(ads.request_ad("interstitial"), OK, "ad request returns OK")
	_assert_eq(_ad_events[0], "interstitial", "ad requested signal")
	_assert_true(not ads.can_show("interstitial"), "cooldown blocks repeat ad")

	var localization = LocalizationScript.new()
	localization.configure("vi", {"vi": {"play": "Choi"}, "en": {"play": "Play"}})
	_assert_eq(localization.tr_key("play"), "Choi", "localized key")
	localization.set_locale("en")
	_assert_eq(localization.tr_key("play"), "Play", "locale switch")
	_assert_eq(localization.tr_key("missing"), "missing", "missing key fallback")

	var remote = RemoteConfigScript.new()
	remote.configure_defaults({"ads_enabled": true, "level_time": 60})
	remote.apply_overrides({"level_time": 45})
	_assert_true(remote.get_bool("ads_enabled", false), "remote default bool")
	_assert_eq(remote.get_int("level_time", 0), 45, "remote override int")
	_cleanup_nodes([theme_manager, audio, analytics, ads, localization, remote])
	theme = null
	_report("test_core_services_contract")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _cleanup_nodes(objects: Array) -> void:
	for object in objects:
		if object is Node:
			object.free()

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
