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
var _ad_states: Array = []
var _ad_failures: Array = []
var _ad_rewards: Array = []
var _theme_changes: Array = []

func _init() -> void:
	var theme = ThemeConfigScript.new()
	theme.theme_id = "neon"
	theme.colors = {"accent": Color(1, 0.5, 0)}
	theme.asset_paths = {"logo": "res://logo.png"}
	theme.audio_events = {"tap": "res://tap.wav"}
	theme.ui_metrics = {"button_size": Vector2(120, 44), "bad_metric": "large"}
	var theme_manager = ThemeManagerScript.new()
	theme_manager.connect("theme_changed", Callable(self, "_on_theme_changed"))
	theme_manager.call("configure", theme, {
		"save_key": "ui.theme",
		"token_schema": {
			"colors": {"accent": TYPE_COLOR},
			"assets": {"logo": TYPE_STRING, "missing_icon": TYPE_STRING},
			"metrics": {"button_size": TYPE_VECTOR2, "bad_metric": TYPE_VECTOR2}
		}
	})
	_assert_eq(_theme_changes[0]["theme_id"], "neon", "theme manager emits theme id on configure")
	_assert_eq(theme_manager.call("get_save_key"), "ui.theme", "theme manager exposes save key")
	_assert_eq(theme_manager.get_color("accent"), Color(1, 0.5, 0), "theme color lookup")
	_assert_eq(theme_manager.get_asset_path("logo"), "res://logo.png", "theme asset lookup")
	_assert_eq(theme_manager.get_audio_path("tap"), "res://tap.wav", "theme audio lookup")
	var token_set: Dictionary = theme_manager.call("resolve_token_set", [
		{"id": "primary", "category": "colors", "key": "accent"},
		{"id": "missing", "category": "assets", "key": "missing_icon"}
	])
	_assert_eq(Dictionary(token_set.get("primary", {})).get("value"), Color(1, 0.5, 0), "theme token set resolves color")
	_assert_eq(Dictionary(token_set.get("missing", {})).get("source"), "missing", "theme token set reports missing source without fallback")
	var token_errors: Array = theme_manager.call("validate_tokens")
	_assert_true(_has_error_code(token_errors, "type_mismatch"), "theme token schema reports type mismatch")
	_assert_true(_has_error_code(token_errors, "missing_token"), "theme token schema reports missing token")

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
	ads.ad_state_changed.connect(func(placement: String, state: String, payload: Dictionary): _ad_states.append({"placement": placement, "state": state, "payload": payload}))
	ads.ad_failed.connect(func(placement: String, reason: String, payload: Dictionary): _ad_failures.append({"placement": placement, "reason": reason, "payload": payload}))
	ads.ad_reward_claimed.connect(func(placement: String, reward_token: String, payload: Dictionary): _ad_rewards.append({"placement": placement, "reward_token": reward_token, "payload": payload}))
	ads.configure({"interstitial": {"cooldown_seconds": 30}, "revive_reward": {"cooldown_seconds": 0, "type": "rewarded"}}, true, {"provider": "test_provider", "rewarded": true})
	_assert_eq(String(ads.provider_status().get("provider", "")), "test_provider", "ads exposes provider-neutral capability status")
	_assert_true(ads.can_show("interstitial"), "first ad can show")
	_assert_eq(ads.request_ad("interstitial"), OK, "ad request returns OK")
	_assert_eq(_ad_events[0], "interstitial", "ad requested signal")
	_assert_eq(String(Dictionary(ads.placement_status("interstitial")).get("state", "")), "requested", "ad lifecycle records requested state")
	_assert_eq(String(Dictionary(_ad_states[0]).get("state", "")), "requested", "ad lifecycle emits requested state")
	_assert_true(not ads.can_show("interstitial"), "cooldown blocks repeat ad")
	_assert_eq(ads.fail_ad("interstitial", "provider_unavailable", {"network": "offline"}), OK, "ad failure returns OK")
	_assert_eq(String(Dictionary(ads.placement_status("interstitial")).get("state", "")), "failed", "ad lifecycle records failed state")
	_assert_eq(String(Dictionary(_ad_failures[0]).get("reason", "")), "provider_unavailable", "ad failure signal keeps reason")
	_assert_eq(ads.request_ad("revive_reward"), OK, "reward ad request returns OK")
	_assert_eq(ads.mark_showing("revive_reward", {"request_id": "revive_1"}), OK, "reward ad marks showing")
	_assert_eq(ads.complete_ad("revive_reward", true, "reward_1", {"source": "provider"}), OK, "reward ad completion returns OK")
	_assert_eq(_ad_rewards.size(), 1, "reward claim emits once")
	_assert_eq(ads.claim_reward("revive_reward", "reward_1", {}), ERR_ALREADY_EXISTS, "duplicate reward claim is blocked")
	_assert_eq(_ad_rewards.size(), 1, "duplicate reward claim does not emit")

	var localization = LocalizationScript.new()
	localization.configure("vi", {"vi": {"play": "Choi"}, "en": {"play": "Play"}})
	_assert_eq(localization.tr_key("play"), "Choi", "localized key")
	localization.configure("vi", {"vi": {}, "en": {"english_only": "English only"}})
	_assert_eq(localization.tr_key("english_only"), "english_only", "localization does not fallback to another locale")
	localization.configure("vi", {"vi": {"play": "Choi"}, "en": {"play": "Play"}})
	localization.set_locale("en")
	_assert_eq(localization.tr_key("play"), "Play", "locale switch")
	_assert_eq(localization.tr_key("missing"), "missing", "missing key returns key")

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

func _has_error_code(errors: Array, code: String) -> bool:
	for error in errors:
		if String(Dictionary(error).get("code", "")) == code:
			return true
	return false

func _on_theme_changed(theme_id: String, save_key: String) -> void:
	_theme_changes.append({"theme_id": theme_id, "save_key": save_key})

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
