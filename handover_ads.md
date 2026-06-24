# Handover: Cross-Platform Ad Integration Guide

This document is the implementation guide for the **Ad Integration Agent**.

The game's codebase is structured so that you **only need to edit a single file**:
- Autoload Script: [AdManager.gd](file:///c:/Users/Admin/Desktop/Game/Resources/Globals/AdManager.gd) (Registered as `AdManager` in [project.godot](file:///c:/Users/Admin/Desktop/Game/project.godot)).

Do **not** modify any gameplay or user interface scripts (like `GameOverOverlay.gd`). They are already fully wired to call `AdManager` and handle the success/failure callbacks correctly.

---

## 1. Autoload API & Signals

Your implementation in `AdManager.gd` must maintain the public methods and signals below.

### Signals
- `ad_loaded(ad_type: String)`: Emit when an ad is cached.
- `ad_failed_to_load(ad_type: String, error_code: int)`: Emit if caching fails.
- `ad_opened(ad_type: String)`: Emit when the ad covers the screen.
- `ad_closed(ad_type: String, reward_earned: bool)`: Emit when the user closes the ad.

### Public Methods
- `show_rewarded_video(callback_obj: Object, callback_method: String)`: Requests a rewarded ad. You must trigger the callback method on the target object with a boolean parameter indicating whether the reward was earned.
- `show_interstitial()`: Triggers a full-screen interstitial ad.
- `show_banner(show: bool)`: Shows or hides the banner ad.

---

## 2. Platform-Specific Integration Checklist

### Android / iOS (Mobile Native)
1. **Plugin Installation**:
   - Install the official **Godot AdMob Plugin** (or similar compatible native extension).
   - Configure the Ad Unit IDs inside `export_presets.cfg` or dynamically inside `AdManager.gd`.
2. **SDK Hookup**:
   - In `_init_android_admob()` and `_init_ios_admob()`, load the singleton:
     ```gdscript
     if Engine.has_singleton("AdMob"):
         var admob = Engine.get_singleton("AdMob")
         # Connect native signals to AdManager private methods
     ```
   - Map native signal completions to `_trigger_callback(true)`.

### Web / HTML5
1. **JavaScript SDK**:
   - The game is deployed to Firebase Hosting. Web ads (e.g. CrazyGames, GameDistribution, or Google AdSense) are loaded via HTML/JS scripts in `reskin_dashboard/index.html` or the shell page.
2. **Godot-JS Bridge**:
   - Inside `_show_web_rewarded()`, invoke the JS ad function:
     ```gdscript
     if JavaScriptBridge.has_feature("JavaScript"):
         JavaScriptBridge.eval("showWebRewardedAd();")
     ```
   - Create a global JS callback that notifies Godot when the ad finishes. In GDScript, expose a receiver:
     ```gdscript
     # Register callback in _init_web_ads()
     var callback = JavaScriptBridge.create_callback(_on_web_ad_callback)
     JavaScriptBridge.get_interface("window").onAdFinished = callback
     ```

### Fallback / Editor Mode
- `_show_mock_rewarded()` simulates a delay of `2.0` seconds and grants the reward automatically. This ensures gameplay can be fully tested in the Godot Editor without loading real ad networks.

---

## 3. Reference Implementation: Gameplay Callback Flow

For your reference, the Game Over screen (`GameOverOverlay.gd`) triggers the ad like this:

```gdscript
# Inside GameOverOverlay.gd
func _on_ad_pressed() -> void:
    countdown.stop()
    # Call global AdManager to show the rewarded video
    AdManager.show_rewarded_video(self, "_on_ad_completed")

func _on_ad_completed(success: bool) -> void:
    if success:
        ad_reward_granted.emit()
        await close()
    else:
        # If the ad failed or was cancelled, resume the countdown
        if _seconds_left > 0:
            countdown.start(1.0)
    ad_button.disabled = false
```

Your only job is to ensure that `AdManager.gd` calls the passed callback object and method with `true` when a rewarded ad completes, or `false` if it fails or is skipped.
