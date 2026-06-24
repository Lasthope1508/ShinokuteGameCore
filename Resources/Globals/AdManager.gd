extends Node

# AdManager.gd
# Cross-platform ad integration with support for:
# - Android (Native AdMob singleton)
# - Web/HTML5 (GameDistribution, CrazyGames, GameMonetize SDKs via JS Bridge)
# - Fallback/Mock for Editor & Desktop

# Signals to notify the game of ad events
signal ad_loaded(ad_type: String)
signal ad_failed_to_load(ad_type: String, error_code: int)
signal ad_opened(ad_type: String)
signal ad_closed(ad_type: String, reward_earned: bool)

# HTML5 Web Platforms
enum WebPlatform { GAMEDISTRIBUTION, CRAZYGAMES, GAMEMONETIZE }
@export var web_platform: WebPlatform = WebPlatform.GAMEDISTRIBUTION

# Standard AdMob Test Ad Unit IDs for Android
var banner_id: String = "ca-app-pub-3940256099942544/6300978111"
var interstitial_id: String = "ca-app-pub-3940256099942544/1033173712"
var rewarded_id: String = "ca-app-pub-3940256099942544/5224354917"

# Callback system for direct ad invocation
var _ad_callback_obj: Object = null
var _ad_callback_method: String = ""

# Internal state tracking
var _android_admob: Object = null
var _android_reward_earned: bool = false
var _web_reward_earned: bool = false
var _web_ad_callback: Variant = null

func _ready() -> void:
	print("[AdManager] Initializing for platform: ", OS.get_name())
	_initialize_platform_ads()

# Primary function to initialize platform-specific ad SDKs
func _initialize_platform_ads() -> void:
	match OS.get_name():
		"Android":
			_init_android_admob()
		"iOS":
			_init_ios_admob()
		"Web":
			_init_web_ads()
		_:
			_init_mock_ads()

# Native Android AdMob Initialization
func _init_android_admob() -> void:
	print("[AdManager] Android platform detected. Configuring AdMob SDK...")
	if Engine.has_singleton("AdMob"):
		_android_admob = Engine.get_singleton("AdMob")
		print("[AdManager] Native AdMob singleton found.")
		
		# Connect signals defensively
		_connect_admob_signals()
		
		# Initialize AdMob SDK if needed
		if _android_admob.has_method("initialize"):
			_android_admob.initialize()
		
		# Preload ads
		_load_android_ads()
	else:
		print("[AdManager] Native AdMob singleton NOT found. Falling back to mock ads.")

func _connect_admob_signals() -> void:
	if not _android_admob:
		return
	
	# Connect Rewarded signals defensively
	var rewarded_signals = {
		"rewarded_video_ad_loaded": "_on_android_rewarded_loaded",
		"rewarded_loaded": "_on_android_rewarded_loaded",
		"rewarded_video_ad_failed_to_load": "_on_android_rewarded_failed",
		"rewarded_failed_to_load": "_on_android_rewarded_failed",
		"rewarded_video_ad_opened": "_on_android_rewarded_opened",
		"rewarded_opened": "_on_android_rewarded_opened",
		"rewarded_video_ad_closed": "_on_android_rewarded_closed",
		"rewarded_closed": "_on_android_rewarded_closed",
		"rewarded_video_ad_completed": "_on_android_rewarded_completed",
		"rewarded_user_earned_reward": "_on_android_rewarded_earned"
	}
	
	for sig in rewarded_signals:
		if _android_admob.has_signal(sig):
			_android_admob.connect(sig, Callable(self, rewarded_signals[sig]))
			print("[AdManager] Connected AdMob signal: ", sig)
	
	# Connect Interstitial signals defensively
	var interstitial_signals = {
		"interstitial_loaded": "_on_android_interstitial_loaded",
		"interstitial_failed_to_load": "_on_android_interstitial_failed",
		"interstitial_opened": "_on_android_interstitial_opened",
		"interstitial_closed": "_on_android_interstitial_closed"
	}
	
	for sig in interstitial_signals:
		if _android_admob.has_signal(sig):
			_android_admob.connect(sig, Callable(self, interstitial_signals[sig]))
			print("[AdManager] Connected AdMob signal: ", sig)

	# Connect Banner signals defensively
	var banner_signals = {
		"banner_loaded": "_on_android_banner_loaded",
		"banner_failed_to_load": "_on_android_banner_failed"
	}
	
	for sig in banner_signals:
		if _android_admob.has_signal(sig):
			_android_admob.connect(sig, Callable(self, banner_signals[sig]))
			print("[AdManager] Connected AdMob signal: ", sig)

func _load_android_ads() -> void:
	_load_android_rewarded()
	_load_android_interstitial()

func _load_android_rewarded() -> void:
	if _android_admob:
		if _android_admob.has_method("load_rewarded"):
			_android_admob.load_rewarded(rewarded_id)
		elif _android_admob.has_method("load_rewarded_video"):
			_android_admob.load_rewarded_video(rewarded_id)

func _load_android_interstitial() -> void:
	if _android_admob and _android_admob.has_method("load_interstitial"):
		_android_admob.load_interstitial(interstitial_id)

# iOS AdMob Initialization
func _init_ios_admob() -> void:
	print("[AdManager] iOS platform detected. Falling back to mock ads (not configured).")

# Web Ads Javascript Bridge Setup
var _last_scene_name: String = ""

func _init_web_ads() -> void:
	print("[AdManager] Web platform detected. Initializing JS Bridge.")
	if OS.has_feature("web"):
		# Register callback on the global window object to receive events from index.html
		_web_ad_callback = JavaScriptBridge.create_callback(_on_web_ad_callback)
		JavaScriptBridge.get_interface("window").onAdEvent = _web_ad_callback
		print("[AdManager] window.onAdEvent registered.")
		
		# Auto-detect platform
		var has_crazy = JavaScriptBridge.eval("typeof CrazyGames !== 'undefined'")
		var has_monetize = JavaScriptBridge.eval("typeof sdk !== 'undefined' || typeof SDK_OPTIONS !== 'undefined'")
		if has_crazy:
			web_platform = WebPlatform.CRAZYGAMES
		elif has_monetize:
			web_platform = WebPlatform.GAMEMONETIZE
		else:
			web_platform = WebPlatform.GAMEDISTRIBUTION
		print("[AdManager] Auto-detected web platform: ", WebPlatform.keys()[web_platform])
		
		set_process(true)
	else:
		print("[AdManager] JavaScriptBridge not available.")

func _process(_delta: float) -> void:
	if not OS.has_feature("web") or web_platform != WebPlatform.CRAZYGAMES:
		set_process(false)
		return
		
	var current_scene = get_tree().current_scene
	if current_scene:
		var current_name = current_scene.name
		if current_name != _last_scene_name:
			_on_scene_changed(_last_scene_name, current_name)
			_last_scene_name = current_name

func _on_scene_changed(from_scene: String, to_scene: String) -> void:
	print("[AdManager] Scene changed from ", from_scene, " to ", to_scene)
	if to_scene == "Game":
		JavaScriptBridge.eval("if (typeof CrazyGames !== 'undefined') CrazyGames.SDK.game.gameplayStart();")
		print("[AdManager] CrazyGames gameplayStart() called automatically.")
	elif from_scene == "Game":
		JavaScriptBridge.eval("if (typeof CrazyGames !== 'undefined') CrazyGames.SDK.game.gameplayStop();")
		print("[AdManager] CrazyGames gameplayStop() called automatically.")

# Fallback/Mock ads for Editor or unsupported platforms
func _init_mock_ads() -> void:
	print("[AdManager] Mock ads initialized for editor/desktop testing.")

# Show a Rewarded Video Ad
func show_rewarded_video(callback_obj: Object, callback_method: String) -> void:
	_ad_callback_obj = callback_obj
	_ad_callback_method = callback_method
	
	print("[AdManager] Requesting Rewarded Video Ad...")
	match OS.get_name():
		"Android":
			if _android_admob:
				_show_android_rewarded()
			else:
				_show_mock_rewarded()
		"iOS":
			_show_mock_rewarded()
		"Web":
			_show_web_rewarded()
		_:
			_show_mock_rewarded()

# Show an Interstitial Ad (Non-rewarded full-screen ad)
func show_interstitial() -> void:
	print("[AdManager] Requesting Interstitial Ad...")
	match OS.get_name():
		"Android":
			if _android_admob:
				_show_android_interstitial()
			else:
				_show_mock_interstitial()
		"iOS":
			_show_mock_interstitial()
		"Web":
			_show_web_interstitial()
		_:
			_show_mock_interstitial()

# Show a Banner Ad
func show_banner(show: bool) -> void:
	print("[AdManager] Requesting banner visibility: ", show)
	match OS.get_name():
		"Android":
			if _android_admob:
				if show:
					if _android_admob.has_method("load_banner"):
						_android_admob.load_banner(banner_id, false)
					if _android_admob.has_method("show_banner"):
						_android_admob.show_banner()
				else:
					if _android_admob.has_method("hide_banner"):
						_android_admob.hide_banner()
		"Web":
			_show_web_banner(show)
		_:
			print("[AdManager] Mock banner visibility changed to: ", show)

# Internal Android Callbacks
func _on_android_rewarded_loaded() -> void:
	print("[AdManager] Android rewarded ad loaded successfully.")
	emit_signal("ad_loaded", "rewarded")

func _on_android_rewarded_failed(error_code: int = 0) -> void:
	print("[AdManager] Android rewarded ad failed to load: ", error_code)
	emit_signal("ad_failed_to_load", "rewarded", error_code)

func _on_android_rewarded_opened() -> void:
	print("[AdManager] Android rewarded ad opened.")
	emit_signal("ad_opened", "rewarded")
	_android_reward_earned = false

func _on_android_reward_completed() -> void: # Compatibility with older signals
	print("[AdManager] Android rewarded ad completed.")
	_android_reward_earned = true

func _on_android_rewarded_completed() -> void:
	print("[AdManager] Android rewarded ad completed.")
	_android_reward_earned = true

func _on_android_rewarded_earned(_type: String = "", _amount: int = 0) -> void:
	print("[AdManager] Android rewarded ad earned reward callback.")
	_android_reward_earned = true

func _on_android_rewarded_closed() -> void:
	print("[AdManager] Android rewarded ad closed. Reward earned: ", _android_reward_earned)
	emit_signal("ad_closed", "rewarded", _android_reward_earned)
	_trigger_callback(_android_reward_earned)
	_android_reward_earned = false
	_load_android_rewarded() # Reload for next time

func _on_android_interstitial_loaded() -> void:
	print("[AdManager] Android interstitial loaded.")
	emit_signal("ad_loaded", "interstitial")

func _on_android_interstitial_failed(error_code: int = 0) -> void:
	print("[AdManager] Android interstitial failed to load: ", error_code)
	emit_signal("ad_failed_to_load", "interstitial", error_code)

func _on_android_interstitial_opened() -> void:
	print("[AdManager] Android interstitial opened.")
	emit_signal("ad_opened", "interstitial")

func _on_android_interstitial_closed() -> void:
	print("[AdManager] Android interstitial closed.")
	emit_signal("ad_closed", "interstitial", false)
	_load_android_interstitial() # Reload for next time

func _on_android_banner_loaded() -> void:
	print("[AdManager] Android banner loaded.")
	emit_signal("ad_loaded", "banner")

func _on_android_banner_failed(error_code: int = 0) -> void:
	print("[AdManager] Android banner failed to load: ", error_code)
	emit_signal("ad_failed_to_load", "banner", error_code)

func _show_android_rewarded() -> void:
	if _android_admob:
		var has_show = false
		if _android_admob.has_method("show_rewarded"):
			_android_admob.show_rewarded()
			has_show = true
		elif _android_admob.has_method("show_rewarded_video"):
			_android_admob.show_rewarded_video()
			has_show = true
		
		if has_show:
			return
	_show_mock_rewarded()

func _show_android_interstitial() -> void:
	if _android_admob and _android_admob.has_method("show_interstitial"):
		_android_admob.show_interstitial()
	else:
		_show_mock_interstitial()

# Internal Web Callbacks & Triggers
func _show_web_rewarded() -> void:
	if not OS.has_feature("web"):
		_show_mock_rewarded()
		return
		
	_web_reward_earned = false
	print("[AdManager] Showing Web Rewarded Ad for platform: ", WebPlatform.keys()[web_platform])
	
	match web_platform:
		WebPlatform.GAMEDISTRIBUTION:
			JavaScriptBridge.eval("if (typeof gdsdk !== 'undefined') gdsdk.showAd(gdsdk.AdType.Rewarded); else window.onAdEvent(['rewarded_failed']);")
		WebPlatform.CRAZYGAMES:
			JavaScriptBridge.eval("""
				if (typeof CrazyGames !== 'undefined') {
					CrazyGames.SDK.ad.requestAd('rewarded', {
						adFinished: () => { window.onAdEvent(['rewarded_complete']); },
						adError: (error) => { window.onAdEvent(['rewarded_failed']); },
						adStarted: () => { window.onAdEvent(['ad_started']); }
					});
				} else {
					window.onAdEvent(['rewarded_failed']);
				}
			""")
		WebPlatform.GAMEMONETIZE:
			# GameMonetize does not always have separate rewarded API, using main SDK showBanner as fallback
			JavaScriptBridge.eval("if (typeof sdk !== 'undefined') sdk.showBanner(); else window.onAdEvent(['rewarded_failed']);")

func _show_web_interstitial() -> void:
	if not OS.has_feature("web"):
		_show_mock_interstitial()
		return
		
	print("[AdManager] Showing Web Interstitial Ad for platform: ", WebPlatform.keys()[web_platform])
	
	match web_platform:
		WebPlatform.GAMEDISTRIBUTION:
			JavaScriptBridge.eval("if (typeof gdsdk !== 'undefined') gdsdk.showAd(gdsdk.AdType.Interstitial);")
		WebPlatform.CRAZYGAMES:
			JavaScriptBridge.eval("""
				if (typeof CrazyGames !== 'undefined') {
					CrazyGames.SDK.ad.requestAd('midgame', {
						adFinished: () => { window.onAdEvent(['ad_closed']); },
						adError: (error) => { window.onAdEvent(['ad_error']); },
						adStarted: () => { window.onAdEvent(['ad_started']); }
					});
				}
			""")
		WebPlatform.GAMEMONETIZE:
			JavaScriptBridge.eval("if (typeof sdk !== 'undefined') sdk.showBanner();")

func _show_web_banner(show: bool) -> void:
	if not OS.has_feature("web"):
		return
	print("[AdManager] Requesting Web Banner display: ", show)

func _on_web_ad_callback(args: Array) -> void:
	if args.size() == 0:
		return
	var event_name = args[0]
	print("[AdManager] JS Callback event received: ", event_name)
	
	match event_name:
		"ad_started", "SDK_GAME_PAUSE":
			emit_signal("ad_opened", "web")
		"rewarded_complete", "SDK_REWARDED_WATCH_COMPLETE":
			_web_reward_earned = true
		"rewarded_failed", "ad_error":
			_web_reward_earned = false
			emit_signal("ad_failed_to_load", "web", 0)
			_trigger_callback(false)
		"ad_closed", "ad_dismissed", "SDK_GAME_START":
			emit_signal("ad_closed", "web", _web_reward_earned)
			_trigger_callback(_web_reward_earned)
			_web_reward_earned = false

# Internal Mock / Fallback Ads
func _show_mock_rewarded() -> void:
	print("[AdManager] Simulating mock rewarded video ad (2 seconds)...")
	emit_signal("ad_opened", "mock")
	await get_tree().create_timer(2.0).timeout
	print("[AdManager] Mock rewarded video ad finished.")
	_trigger_callback(true)

func _show_mock_interstitial() -> void:
	print("[AdManager] Simulating mock interstitial ad...")
	emit_signal("ad_opened", "mock")
	await get_tree().create_timer(0.5).timeout
	emit_signal("ad_closed", "mock", false)

func _trigger_callback(reward_earned: bool) -> void:
	if _ad_callback_obj and _ad_callback_obj.has_method(_ad_callback_method):
		_ad_callback_obj.call(_ad_callback_method, reward_earned)
	_ad_callback_obj = null
	_ad_callback_method = ""

