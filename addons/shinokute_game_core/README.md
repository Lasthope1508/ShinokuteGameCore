# Shinokute Game Core Addon

Before using this addon in a reskin, read `../../docs/reskin_core_skin_boundary.md`. Core owns behavior; each game owns game skin and function skin.

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
cfg.translations = {"en": {"play": "Play"}, "vi": {"play": "Choi"}}

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
```

## Layers

- `core/`: `GameCore`, `GameCoreConfig`, `GameSession`, `GameRulesAdapter`, save/profile/geo/leaderboard.
- `services/`: theme, audio/haptics, ads, analytics, localization, remote config.
- `ux/`: scene router and overlay manager.
- `ui/`: reusable UI scenes.

## Rules

- Do not hardcode collection names in game scenes.
- Do not hardcode score sort direction in UI.
- Do not hardcode geolocation fallback country.
- Do not copy profile, save, leaderboard, ads, analytics, audio, localization, or routing code into game-specific scenes.
- Keep game-specific rules in a `GameRulesAdapter` implementation.
