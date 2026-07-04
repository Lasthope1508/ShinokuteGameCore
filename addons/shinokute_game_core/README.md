# Shinokute Game Core Addon

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
```

## Runtime

```gdscript
var core := GameCore.new()
add_child(core)
core.configure(cfg)
core.ensure_profile_ready()
core.submit_score({"mode": "classic", "value": moves})
core.fetch_leaderboard("world", "classic")
```

## Rules

- Do not hardcode collection names in game scenes.
- Do not hardcode score sort direction in UI.
- Do not hardcode geolocation fallback country.
- Do not copy profile/leaderboard code into game-specific scenes.
