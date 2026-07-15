# Projectile Hit Budget Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a generic projectile hit budget runtime that tracks pierce, hit ids, rehit cooldowns, and expire reasons without owning damage, faction, collision, or visuals.

**Architecture:** Core owns only dictionary-driven hit bookkeeping and reports. Games own projectile ids, target validity, damage application, collision source, node spawning, art, VFX, and UI.

**Tech Stack:** Godot 4.3 GDScript, ShinokuteGameCore runtime addon, headless SceneTree contract tests.

---

### Task 1: Core Projectile Hit Budget

**Files:**
- Create: `addons/shinokute_game_core/runtime/projectile_hit_budget.gd`
- Modify: `Tests/test_runtime_core_p0_p1_contract.gd`
- Modify: `docs/core_module_registry.md`
- Modify: `docs/shared_core_migration_candidates.md`

- [ ] **Step 1: Write failing contract test**

Add `ProjectileHitBudgetPath`, call `_test_p0_projectile_hit_budget()`, and assert:
- script loads
- first hit is accepted and consumes one pierce budget
- repeated hit is blocked when `allow_rehit` is false
- repeated hit is blocked during `rehit_cooldown`
- repeated hit is accepted after cooldown when `allow_rehit` is true
- projectile expires when pierce budget reaches zero
- snapshot/restore keeps remaining budget and hit ids

- [ ] **Step 2: Run test to verify RED**

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$core='C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore'
& $godot --headless --path $core --script "$core\Tests\test_runtime_core_p0_p1_contract.gd"
```

Expected: FAIL because `projectile_hit_budget.gd` does not exist.

- [ ] **Step 3: Implement minimal runtime**

Create `projectile_hit_budget.gd` as a `RefCounted` with:
- `configure(config: Dictionary)`
- `register(projectile_id: String, config: Dictionary = {}) -> Dictionary`
- `record_hit(projectile_id: String, target_id: String, elapsed: float = 0.0) -> Dictionary`
- `advance(delta: float) -> Array`
- `expire(projectile_id: String, reason: String = "manual") -> Dictionary`
- `snapshot() -> Dictionary`
- `restore(snapshot: Dictionary) -> void`

- [ ] **Step 4: Run focused core contract**

Run same command. Expected: PASS.

- [ ] **Step 5: Update SSOT docs**

Add `ProjectileHitBudget` to `core_module_registry.md` under Combat Geometry And Projectiles. Move migration candidate evidence from “Next Source-Derived Candidates” into completed notes in `shared_core_migration_candidates.md`.

- [ ] **Step 6: Run full core sweep**

Run:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$core='C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore'
Get-ChildItem "$core\Tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $core --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: all core tests PASS.
