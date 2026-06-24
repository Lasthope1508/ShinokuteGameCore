extends Node

# AdManager.gd
# Abstract interface for cross-platform ad integration.
# Handed over to the Ad Integration Agent for final SDK implementation.

# Signals to notify the game of ad events
signal ad_loaded(ad_type: String)
signal ad_failed_to_load(ad_type: String, error_code: int)
signal ad_opened(ad_type: String)
signal ad_closed(ad_type: String, reward_earned: bool)

# Callback system for direct ad invocation
var _ad_callback_obj: Object = null
var _ad_callback_method: String = ""

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

# Placeholder initialization for Android (AdMob plugin)
func _init_android_admob() -> void:
	print("[AdManager] Android platform detected. Waiting for Ad SDK configuration...")
	# The Ad Integration Agent will load native AdMob plugins here.
	# Example:
	# if Engine.has_singleton("AdMob"):
	#     var admob = Engine.get_singleton("AdMob")
	#     # connect signals...

# Placeholder initialization for iOS (AdMob plugin)
func _init_ios_admob() -> void:
	print("[AdManager] iOS platform detected. Waiting for Ad SDK configuration...")

# Placeholder initialization for Web/HTML5
func _init_web_ads() -> void:
	print("[AdManager] Web platform detected. Waiting for JavaScript Bridge configuration...")

# Fallback/Mock ads for Editor or unsupported platforms
func _init_mock_ads() -> void:
	print("[AdManager] Mock ads initialized for editor/desktop testing.")

# Show a Rewarded Video Ad
# - callback_obj: The object containing the callback method.
# - callback_method: The method to call upon ad completion. Takes a single bool argument (reward_earned).
func show_rewarded_video(callback_obj: Object, callback_method: String) -> void:
	_ad_callback_obj = callback_obj
	_ad_callback_method = callback_method
	
	print("[AdManager] Requesting Rewarded Video Ad...")
	match OS.get_name():
		"Android":
			_show_android_rewarded()
		"iOS":
			_show_ios_rewarded()
		"Web":
			_show_web_rewarded()
		_:
			_show_mock_rewarded()

# Show an Interstitial Ad (Non-rewarded full-screen ad)
func show_interstitial() -> void:
	print("[AdManager] Requesting Interstitial Ad...")
	match OS.get_name():
		"Android":
			_show_android_interstitial()
		"iOS":
			_show_ios_interstitial()
		"Web":
			_show_web_interstitial()
		_:
			_show_mock_interstitial()

# Show a Banner Ad at the bottom or top of the screen
func show_banner(show: bool) -> void:
	print("[AdManager] Requesting banner visibility: ", show)
	# Platform specific banner logic...

# Internal helpers
func _show_android_rewarded() -> void:
	# Implementation will call AdMob plugin
	_trigger_callback(true) # Temp mock auto-reward

func _show_ios_rewarded() -> void:
	_trigger_callback(true)

func _show_web_rewarded() -> void:
	# Implementation will call JavaScriptBridge.eval("...") or interface
	_trigger_callback(true)

func _show_mock_rewarded() -> void:
	# Simulate delay and trigger callback
	print("[AdManager] Simulating mock rewarded video ad (2 seconds)...")
	await get_tree().create_timer(2.0).timeout
	_trigger_callback(true)

func _show_android_interstitial() -> void:
	pass

func _show_ios_interstitial() -> void:
	pass

func _show_web_interstitial() -> void:
	pass

func _show_mock_interstitial() -> void:
	print("[AdManager] Simulating mock interstitial ad...")

func _trigger_callback(reward_earned: bool) -> void:
	emit_signal("ad_closed", "rewarded", reward_earned)
	if _ad_callback_obj and _ad_callback_obj.has_method(_ad_callback_method):
		_ad_callback_obj.call(_ad_callback_method, reward_earned)
	_ad_callback_obj = null
	_ad_callback_method = ""
