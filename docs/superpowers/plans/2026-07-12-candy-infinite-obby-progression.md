# Candy Infinite Obby Progression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Candy Sky Islands dynamic 3D obby difficulty so level progression can scale beyond the authored onboarding levels while remaining solvable, deterministic, fair, and SSOT-driven.

**Architecture:** Shinokute core owns generic dynamic progression resolution. Candy owns only data curves and a route generator adapter that consumes resolved profile data. Route randomness must be deterministic from level number and seed so the same level always produces the same difficulty and layout.

**Tech Stack:** Godot 4.3 GDScript resources, Shinokute core addon scripts, Candy progression `.tres` data, headless Godot contract tests.

---

### Task 1: Add Dynamic Progression Contract

**Files:**
- Create: `tests/test_dynamic_obby_progression_contract.gd`

- [x] **Step 1: Write failing test**

Create a Godot headless test that loads `res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres`, requests profiles for levels `4`, `10`, `25`, and `100`, and asserts:

```gdscript
config.has_method("get_difficulty_profile_for_level_number")
profile.level_number == requested level
layout_profile.route_length increases from level 4 to 100
layout_profile.platform_count increases from level 4 to 100
layout_profile.route_width increases from level 4 to 100
layout_profile.gap_distance <= measured_jump_cap
layout_profile.route_seed is deterministic for the same level
profile.display_name contains the visible level number
```

- [x] **Step 2: Run red**

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_dynamic_obby_progression_contract.gd"
```

Expected: FAIL because the catalog has no dynamic profile API.

### Task 2: Add Core Dynamic Resolver

**Files:**
- Create: `addons/shinokute_game_core/core/dynamic_progression_resolver.gd`
- Modify: `addons/shinokute_game_core/core/progression_catalog.gd`

- [x] **Step 1: Implement resolver**

Add a generic resolver that evaluates dictionary curve specs:

```gdscript
linear: base + per_level * n
sqrt: base + per_level * sqrt(n)
log: base + per_level * log(n + 1)
clamp: min/max
round: ceil/floor/round/int
```

It must duplicate source dictionaries, never mutate authored level resources, and return a resolved profile dictionary.

- [x] **Step 2: Expose catalog API**

Add:

```gdscript
@export var dynamic_progression_profile: Dictionary = {}
func get_difficulty_profile_for_level_number(level_number: int, measured_jump_cap: float = 0.0) -> Dictionary
```

If `level_number` is within the authored catalog, return the authored profile plus `level_number` and `display_name`. If beyond catalog size, resolve from `dynamic_progression_profile`.

### Task 3: Move Candy Difficulty Constants Into SSOT

**Files:**
- Modify: `Resources/Data/Progression/candy_sky_islands_obby_progression.tres`

- [x] **Step 1: Add dynamic progression profile**

Add SSOT data for:

```text
seed_base
seed_stride
route_length curve
platform_count curve
gap_distance curve with jump cap
route_width curve
turn_cycles curve
verticality curve
height_wave_amplitude curve
descent_ratio curve
hazard_density curve
falling_platform_acceleration curve
falling_platform_trigger_delay curve
platform_radii
platform_mix
route_shape tuning
```

### Task 4: Make Route Generator Fully Profile-Driven

**Files:**
- Modify: `scripts/obby_route_generator.gd`
- Modify: `tools/print_obby_route_report.gd`

- [x] **Step 1: Replace hardcoded route tuning**

Use `layout_profile.platform_radii`, `route_shape.width_overshoot_factor`, `route_shape.max_lateral_step_ratio`, `route_shape.position_jitter`, `platform_mix`, and `height_wave`.

- [x] **Step 2: Add fair deterministic randomness**

All random choices must use `route_seed`, and same level/profile must produce byte-equivalent route metrics.

- [x] **Step 3: Add descent support**

Height may go up/down within `max_step_height`, but final goal still reaches `verticality`.

### Task 5: Show Level Number In UI

**Files:**
- Inspect and modify existing HUD/progression scripts only where needed.

- [x] **Step 1: Verify existing HUD path**

Find current level label update path in `scripts/game_progression.gd` and HUD scripts.

- [x] **Step 2: Ensure dynamic level numbers display**

When a dynamic profile starts, HUD must show the current level number, not only one of three authored titles.

### Task 6: Update Contracts And Docs

**Files:**
- Modify: `tests/test_obby_route_solvability_contract.gd`
- Modify: `tests/test_game_progression_ssot_contract.gd`
- Modify: `docs/gameplay_progression_ssot.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/asset_manifest.md`

- [x] **Step 1: Extend solvability test**

Test dynamic levels `4`, `10`, `25`, and `100`. Assert route stays solvable and not one-axis.

- [x] **Step 2: Update SSOT docs**

Document dynamic progression, deterministic fair randomness, jump-cap clamping, and data-owned route shape tuning.

### Task 7: Verification

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_dynamic_obby_progression_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_obby_route_solvability_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_game_progression_ssot_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_obby_stage_builder_runtime_contract.gd"
& $godot --headless --path $project --script "$project\tests\test_game_progression_runtime_reset.gd"
git diff --check
```

Expected: all PASS, no whitespace errors.
