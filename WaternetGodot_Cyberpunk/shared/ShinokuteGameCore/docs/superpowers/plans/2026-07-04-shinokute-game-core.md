# Shinokute Game Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Godot addon containing reusable player profile, first-run username, save, geolocation, and leaderboard modules for Shinokute games.

**Architecture:** Create a small Godot 4.3 project containing an addon under `addons/shinokute_game_core`. Keep each module focused and configured by `GameCoreConfig`; games provide config resources and theme-specific UI wrappers.

**Tech Stack:** Godot 4.3, GDScript, ConfigFile, HTTPRequest, Firestore REST payloads.

---

### Task 1: Core Config And Score Contract

**Files:**
- Create: `addons/shinokute_game_core/core/game_core_config.gd`
- Test: `Tests/test_game_core_config.gd`

- [ ] Write failing tests for collection, score label, sort direction, username policy, and validation.
- [ ] Implement `GameCoreConfig`.
- [ ] Run `test_game_core_config.gd` until it passes.

### Task 2: Save Store

**Files:**
- Create: `addons/shinokute_game_core/core/local_save_store.gd`
- Test: `Tests/test_local_save_store.gd`

- [ ] Write failing tests for username, device uuid stability, geolocation keys, best score, and submitted score.
- [ ] Implement `LocalSaveStore`.
- [ ] Run `test_local_save_store.gd` until it passes.

### Task 3: Player Profile

**Files:**
- Create: `addons/shinokute_game_core/core/player_profile.gd`
- Test: `Tests/test_player_profile.gd`

- [ ] Write failing tests for first-run username requirement, validation, commit, and skip behavior.
- [ ] Implement `PlayerProfile`.
- [ ] Run `test_player_profile.gd` until it passes.

### Task 4: Leaderboard Client

**Files:**
- Create: `addons/shinokute_game_core/core/leaderboard_client.gd`
- Test: `Tests/test_leaderboard_client.gd`

- [ ] Write failing tests for Firestore submit URL, score document, world query, country query, and ascending/descending ordering.
- [ ] Implement `LeaderboardClient`.
- [ ] Run `test_leaderboard_client.gd` until it passes.

### Task 5: Geo Service And Facade

**Files:**
- Create: `addons/shinokute_game_core/core/geo_service.gd`
- Create: `addons/shinokute_game_core/core/game_core.gd`
- Test: `Tests/test_geo_service.gd`
- Test: `Tests/test_game_core_facade.gd`

- [ ] Write failing tests for geolocation cache apply and facade wiring.
- [ ] Implement `GeoService` and `GameCore`.
- [ ] Run tests until they pass.

### Task 6: Username Prompt UI

**Files:**
- Create: `addons/shinokute_game_core/ui/username_prompt_overlay.tscn`
- Create: `addons/shinokute_game_core/ui/username_prompt_overlay.gd`
- Test: `Tests/test_username_prompt_scene_contract.gd`

- [ ] Write failing scene contract test.
- [ ] Implement prompt scene and script.
- [ ] Run UI contract test until it passes.

### Task 7: Addon Packaging

**Files:**
- Create: `addons/shinokute_game_core/plugin.cfg`
- Create: `addons/shinokute_game_core/plugin.gd`
- Create: `addons/shinokute_game_core/README.md`

- [ ] Add addon metadata and integration docs.
- [ ] Run all tests.
- [ ] Commit repo checkpoint.
