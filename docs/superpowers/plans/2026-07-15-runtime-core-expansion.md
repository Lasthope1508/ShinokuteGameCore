# Runtime Core Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reusable projectile travel, attack cadence, scene transition, audio playback, and publish audit primitives to ShinokuteGameCore without moving game meaning, UI art, or concrete formulas into core.

**Architecture:** Core modules expose small dictionary-based contracts and return reports. First Peace may call core through game-owned adapters or local wrapper methods only. Docs update registry and candidate status so later agents find modules by function tag.

**Tech Stack:** Godot 4.3 GDScript, ShinokuteGameCore `RefCounted` runtime modules, core contract tests, First Peace game contract tests.

---

### Task 1: ProjectileTravelRuntime2D

**Files:**
- Create: `addons/shinokute_game_core/runtime/projectile_travel_runtime_2d.gd`
- Modify: `Tests/test_runtime_core_p0_p1_contract.gd`
- Modify docs: `docs/core_module_registry.md`, `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write RED tests**

Add tests proving `step()` advances position, tracks distance, expires by range and lifetime, and can turn direction toward a target with an angular limit.

- [ ] **Step 2: Verify RED**

Run core test sweep. Expected failure: `Could not preload resource` or missing method for `projectile_travel_runtime_2d.gd`.

- [ ] **Step 3: Implement GREEN**

Create a `RefCounted` with:
- `configure(defaults := {})`
- `initial_state(config := {})`
- `step(state, delta, config := {})`
- `snapshot(state)`
- `restore(snapshot)`

Core owns only position, direction, speed, traveled distance, elapsed/lifetime/range, optional target steering, and expire reason.

- [ ] **Step 4: Verify GREEN**

Run core test sweep. Expected: all current core tests pass.

### Task 2: AttackCadenceCore

**Files:**
- Create: `addons/shinokute_game_core/runtime/attack_cadence.gd`
- Modify: `Tests/test_runtime_core_p0_p1_contract.gd`
- Modify docs: `docs/core_module_registry.md`, `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write RED tests**

Add tests proving cooldown blocks firing, ready attack enters `anticipate`, `duration`, `recovery`, and back to `ready`, with reports but no projectile spawning.

- [ ] **Step 2: Verify RED**

Run core test sweep. Expected failure: missing `attack_cadence.gd`.

- [ ] **Step 3: Implement GREEN**

Create a `RefCounted` with `configure`, `initial_state`, `request`, `advance`, `can_request`, `snapshot`, and `restore`.

- [ ] **Step 4: Verify GREEN**

Run core test sweep.

### Task 3: SceneTransitionCore

**Files:**
- Create: `addons/shinokute_game_core/ux/scene_transition_lifecycle.gd`
- Modify: `Tests/test_core_ux_contract.gd`
- Modify docs: `docs/core_module_registry.md`, `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write RED tests**

Add tests proving busy guard blocks duplicate transition, transition reports `fade_out`, `change_scene`, `fade_in`, `complete`, and invalid route blocks.

- [ ] **Step 2: Verify RED**

Run core UX test. Expected failure: missing lifecycle class.

- [ ] **Step 3: Implement GREEN**

Create a `RefCounted` with route registry, request state, `advance(delta)`, `complete_change()`, `cancel()`, and snapshot.

- [ ] **Step 4: Verify GREEN**

Run core test sweep.

### Task 4: AudioHaptics Upgrade

**Files:**
- Modify: `addons/shinokute_game_core/services/audio_haptics_manager.gd`
- Modify: `Tests/test_core_settings_audio_contract.gd`, `Tests/test_core_services_contract.gd`
- Modify docs: `docs/core_module_registry.md`, `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write RED tests**

Add tests proving event player pooling uses configurable bus names, missing paths report cleanly, BGM crossfade request records pending state, and HTML5 unlock can be tracked without vendor code.

- [ ] **Step 2: Verify RED**

Run audio tests. Expected failure: missing methods or fields.

- [ ] **Step 3: Implement GREEN**

Add config dictionary, bus names, `unlock_audio()`, `is_audio_unlocked()`, `audio_debug_state()`, `play_bgm_event()`, and crossfade state report. Keep paths in theme/config.

- [ ] **Step 4: Verify GREEN**

Run core test sweep.

### Task 5: PublishAuditCore

**Files:**
- Create: `addons/shinokute_game_core/runtime/publish_audit.gd`
- Modify: `Tests/test_runtime_core_p0_p1_contract.gd`
- Modify docs: `docs/core_module_registry.md`, `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write RED tests**

Add tests proving manifest entries validate required keys, forbidden marker scan reports paths, and export preset text scan can detect platform and missing preset names without touching filesystem.

- [ ] **Step 2: Verify RED**

Run core test sweep. Expected failure: missing publish audit class.

- [ ] **Step 3: Implement GREEN**

Create pure-data audit helpers: `validate_manifest`, `scan_forbidden_markers`, `audit_export_presets_text`, `audit_hosting_headers`.

- [ ] **Step 4: Verify GREEN**

Run core test sweep.

### Task 6: First Peace Wiring

**Files:**
- Create: `LastHopeFirstPeace/Scripts/LastHopeProjectileTravelAdapter.gd`
- Modify: `LastHopeFirstPeace/Scripts/LastHopeLevel.gd`
- Copy core files into `LastHopeFirstPeace/addons/shinokute_game_core/...`
- Modify tests: `LastHopeFirstPeace/tests/test_last_hope_projectile_behavior_contract.gd`, `LastHopeFirstPeace/tests/test_last_hope_core_runtime_usage_contract.gd`
- Modify docs: `LastHopeFirstPeace/docs/reskin_checklist.md`

- [ ] **Step 1: Write RED game tests**

Add tests proving bullets carry core travel state, `_update_bullets` uses adapter reports for movement/expiry, and game still owns hit/damage/pool return.

- [ ] **Step 2: Verify RED**

Run First Peace relevant tests. Expected failure: missing adapter or metadata.

- [ ] **Step 3: Implement GREEN**

Route bullet travel only through game adapter. Do not route collision, target selection, damage, VFX, or projectile ids into core.

- [ ] **Step 4: Verify GREEN**

Run First Peace full test sweep and core full test sweep.
