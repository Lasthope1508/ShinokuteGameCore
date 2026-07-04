# Shinokute Game Core Design

## Goal

Create a standalone Godot addon repo that owns common modules every Shinokute casual game needs: player identity, first-run username prompt, save-profile keys, geolocation cache, leaderboard submit/query, and score metric contracts.

## Scope

This first version provides logic and a base username prompt. It does not force any game-specific skin, layout, SFX, or score calculation. Each game supplies a `GameCoreConfig` resource and optionally wraps the base UI with its own theme.

## Architecture

`addons/shinokute_game_core/` is the only runtime addon folder. It exposes focused scripts:

- `core/game_core_config.gd`: SSOT resource for game id, Firebase project, REST API key, geolocation URL, username policy, collection names, score labels, and sort directions.
- `core/local_save_store.gd`: ConfigFile-backed storage adapter for username, device uuid, geolocation, best scores, and last submitted scores.
- `core/player_profile.gd`: validates/commits/skips usernames and emits `username_required` or `profile_ready`.
- `core/leaderboard_client.gd`: builds Firestore REST URLs/payloads/queries and owns HTTPRequest lifecycle for submit/fetch.
- `core/geo_service.gd`: resolves and caches geolocation, leaving unknown values empty when no response exists.
- `core/game_core.gd`: thin facade that wires config, save store, profile, geo, and leaderboard.
- `ui/username_prompt_overlay.gd` plus `.tscn`: reusable username prompt with strict validation.

## SSOT Rules

No game id, collection name, score label, sort direction, Firebase project, or geolocation fallback can be hardcoded inside feature modules. Those values come from `GameCoreConfig`.

Ascending games such as Glyphflow moves and descending games such as Bloxchain score both use the same leaderboard client. Sort direction is per mode.

## Integration Contract

A game copies or submodules this addon, creates `Resources/GameCoreConfig.tres`, then instantiates `GameCore` or adds it as an autoload. Gameplay submits only canonical score dictionaries:

```gdscript
GameCore.submit_score({
	"mode": "classic",
	"value": moves
})
```

Leaderboard UI asks:

```gdscript
GameCore.fetch_leaderboard("world", "classic")
```

First-run menus call:

```gdscript
GameCore.ensure_profile_ready()
```
