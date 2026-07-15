# Shinokute Definition Resolver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a generic core resolver that merges canonical definition tables with weighted id pools, then migrate Last Hope upgrades to use it.

**Architecture:** Core owns only generic dictionary resolution: ids, optional weights, duplicate/missing validation, and weighted unique picks. Last Hope keeps upgrade names, target keys, operations, values, and application rules in game-owned files.

**Tech Stack:** Godot 4.3, GDScript, ShinokuteGameCore runtime helpers, LastHopeFirstPeace game scripts.

---

### Task 1: Core Resolver Contract

**Files:**
- Modify: `C:/Users/Admin/Desktop/Godot Casual Games/Shared/ShinokuteGameCore/Tests/test_runtime_core_contract.gd`
- Create: `C:/Users/Admin/Desktop/Godot Casual Games/Shared/ShinokuteGameCore/addons/shinokute_game_core/runtime/definition_resolver.gd`

- [x] **Step 1: Write failing test**

Add a runtime test that loads `res://addons/shinokute_game_core/runtime/definition_resolver.gd`, configures canonical definitions plus pool refs, verifies merged output, missing refs, duplicate ids, and deterministic weighted unique picks.

- [x] **Step 2: Run test to verify RED**

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore' --script 'C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore\Tests\test_runtime_core_contract.gd'
```

Expected: fail because `definition_resolver.gd` does not exist.

- [x] **Step 3: Implement minimal resolver**

Create `ShinokuteDefinitionResolver` with `configure(definitions, pool_refs, weighted_picker_script, id_key, weight_key)`, `resolved_entries()`, `definition_for_id(id)`, `missing_refs()`, `validation_errors()`, and `pick_unique(count, rolls)`.

- [x] **Step 4: Run test to verify GREEN**

Run same command. Expected: `test_runtime_core_contract: PASS`.

### Task 2: Last Hope Migration

**Files:**
- Modify: `C:/Users/Admin/Desktop/Godot Casual Games/LastHopeFirstPeace/Scripts/LastHopeUpgradeCatalog.gd`
- Copy: `definition_resolver.gd` into `C:/Users/Admin/Desktop/Godot Casual Games/LastHopeFirstPeace/addons/shinokute_game_core/runtime/`
- Modify: `C:/Users/Admin/Desktop/Godot Casual Games/LastHopeFirstPeace/tests/test_last_hope_upgrade_contract.gd`

- [x] **Step 1: Write failing game contract**

Assert Last Hope upgrade catalog can receive a core definition resolver script and still produces merged unique upgrade options from `character_updates` plus `upgrade_pool`.

- [x] **Step 2: Run game test to verify RED**

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
& $godot --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\LastHopeFirstPeace' --script 'C:\Users\Admin\Desktop\Godot Casual Games\LastHopeFirstPeace\tests\test_last_hope_upgrade_contract.gd'
```

Expected: fail because catalog has not accepted core resolver script yet.

- [x] **Step 3: Migrate catalog**

Change `LastHopeUpgradeCatalog` to delegate merge, validation, and weighted unique picks to `ShinokuteDefinitionResolver`; keep upgrade normalization and effect application in game.

- [x] **Step 4: Run game test to verify GREEN**

Run same command. Expected: `test_last_hope_upgrade_contract: PASS`.

### Task 3: Research Boundary Notes

**Files:**
- Create: `C:/Users/Admin/Desktop/Godot Casual Games/_research/roguelike_core_sources/core_boundary_analysis.md`
- Modify: `C:/Users/Admin/Desktop/Godot Casual Games/LastHopeFirstPeace/docs/reskin_checklist.md`

- [x] **Step 1: Write standalone analysis**

Document which researched systems do not enter Shinokute core, why, and where they belong.

- [x] **Step 2: Link from Last Hope checklist**

Record the resolver extraction in Core Learning Gate and point to the standalone research boundary file.

### Task 4: Verification

- [x] **Step 1: Run core tests**

Run every `Shared/ShinokuteGameCore/Tests/test_*.gd`.

- [x] **Step 2: Run game tests**

Run every `LastHopeFirstPeace/tests/test_*.gd`.

- [x] **Step 3: Smoke**

Run Last Hope headless smoke for 3 seconds.
