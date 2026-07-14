# Shinokute Game Core Addon

Before using this addon in a reskin, read `../../docs/reskin_core_skin_boundary.md`. Core owns behavior; each game owns game skin and function skin. Every production game must provide its own UI/function skin for enabled shared features.

## Install

Copy or submodule `addons/shinokute_game_core` into a Godot 4.3 game project.

## Configure

Create a `GameCoreConfig` resource with game-specific values:

```gdscript
var cfg := GameCoreConfig.new()
cfg.game_id = "glyphflow_arrays"
cfg.firebase_project_id = "foodapp-7ff6b"
cfg.firestore_api_key = "<firebase-web-api-key>"
cfg.geolocation_url = "https://foodapp-7ff6b.web.app/api/location"
cfg.leaderboard_collections = {"classic": "glyphflow_classic"}
cfg.score_labels = {"classic": "moves"}
cfg.score_sort_directions = {"classic": "ASCENDING"}
cfg.scene_routes = {"menu": "res://Scenes/MainMenu.tscn", "game": "res://Scenes/Game.tscn"}
cfg.overlay_scenes = {"settings": "res://Scenes/Overlays/SettingsOverlay.tscn"}
cfg.ad_placements = {"interstitial": {"cooldown_seconds": 60}}
cfg.remote_defaults = {"ads_enabled": true, "level_time": 60}
cfg.input_bindings = {
	"jump": [{"type": "key", "keycode": KEY_SPACE}],
	"pause": [{"type": "key", "keycode": KEY_ESCAPE}]
}
cfg.preload_scene_paths = ["res://Scenes/MainMenu.tscn"]
cfg.translations = {"en": {"play": "Play"}, "vi": {"play": "Choi"}}
cfg.progression_catalog = preload("res://Resources/Data/Progression/my_game_progression.tres")

var skin := ShinokuteThemeConfig.new()
skin.theme_id = "neon"
skin.colors = {"accent": Color("#ff7300")}
skin.asset_paths = {"logo": "res://Assets/Sprites/logo.png"}
skin.audio_events = {"tap": "res://Audio/SFX/tap.wav"}
cfg.theme_config = skin
```

## Runtime

```gdscript
var core := GameCore.new()
add_child(core)
core.configure(cfg)
core.ensure_profile_ready()
core.configure_rules_adapter(MyGameRules.new())
core.start_run("classic", {"seed": 7})
core.submit_score({"mode": "classic", "value": moves})
core.fetch_leaderboard("world", "classic")
core.scene_router.request_route("game", {"mode": "classic"})
core.overlay_manager.request_overlay("settings")
core.audio_haptics.play_event("tap")
core.analytics.track("game_start", {"mode": "classic"})
core.pause_controller.set_paused(true)
var jump_key := InputEventKey.new()
jump_key.keycode = KEY_SPACE
core.input_bindings.rebind_action_to_event("jump", jump_key)
core.interaction_bus.publish("pickup", {"id": "coin"})
```

## Layers

- `core/`: `GameCore`, `GameCoreConfig`, `GameSession`, `GameRulesAdapter`, save/profile/geo/leaderboard.
- `core/progression_catalog.gd` and `core/progression_level.gd`: reusable progression, layout, environment, and difficulty schema. Games provide concrete route/prop data; core validates canonical keys and emits generic profiles.
- `controllers/`: reusable 3D runtime controllers. `character_3d_controller.gd` owns movement, jump, fall, progression reset, and Shift Lock facing; `follow_camera_3d.gd` owns rotate/zoom, scoped mouse capture, Shift Lock camera sync, and routed look/zoom; `mobile_touch_controls_3d.gd` owns touch pointer routing, guard zones, jump, look, pinch zoom, and the Web pointer-id bridge. Game scripts should inherit these controllers and only add skin-specific presentation/configuration.
- `runtime/`: reusable pause state, input rebinding, spawn pooling, channel-scoped interaction payloads, and preload/cache helpers. Games provide actor behavior, wave definitions, level data, projectile rules, VFX presentation, and UI/function skin.
- `services/`: theme, audio/haptics, ads, analytics, localization, remote config.
- `ux/`: scene router and overlay manager.
- `ui/`: reusable UI scenes.

## Rules

- Do not hardcode collection names in game scenes.
- Do not hardcode score sort direction in UI.
- Do not hardcode geolocation fallback country.
- Do not copy profile, save, leaderboard, ads, analytics, audio, localization, routing, pause, input rebinding, spawn pooling, interaction bus, preload cache, 3D character control, 3D follow camera, or mobile touch-control code into game-specific scenes.
- Keep game-specific rules in a `GameRulesAdapter` implementation.
