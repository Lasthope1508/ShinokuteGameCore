# Gameplay Progression SSOT Doctrine

This doctrine defines how ShinokuteGameCore should absorb reusable level
progression thinking without swallowing game-specific rules or skins.

## Canonical Schema

| Key | Meaning |
|---|---|
| `progression.level_catalog` | Ordered or generated list of levels/stages. |
| `progression.current_level_index` | Runtime pointer to current stage. |
| `progression.completion_condition` | Data-owned win condition for one stage. |
| `progression.failure_policy` | Data-owned retry/fail behavior. |
| `difficulty.curve` | Monotonic or deliberately shaped difficulty profile. |
| `difficulty.profile` | Runtime values applied to game nodes or rules. |
| `layout.profile` | Numeric route shape metrics such as route length, platform count, verticality, gap distance, and hazard count. |
| `layout.stage_segments` | Data-owned traversal segments consumed by the game builder. |
| `layout.environment_segments` | Data-owned terrain/decor segments consumed by the game builder. |

Core may define these names, validation shape, lifecycle signals, and
persistence handoff. A game owns concrete rules and scene nodes.

## Core Modules

- `core/progression_level.gd` defines `ShinokuteProgressionLevel`.
  It owns canonical per-stage fields: `progression.completion_condition`,
  `progression.failure_policy`, `layout.profile`,
  `layout.stage_segments`, `layout.environment_segments`, and
  `difficulty.curve`.
- `core/progression_catalog.gd` defines `ShinokuteProgressionCatalog`.
  It owns `progression.level_catalog`, required difficulty keys, next-level
  resolution, completion policy, data-owned monotonic difficulty validation
  through `difficulty_sort_directions`, and data-owned monotonic layout
  validation through `layout_sort_directions`.
- `core/game_core_config.gd` may reference a `progression_catalog` Resource
  and surfaces catalog validation errors through `validate_config()`.

Do not add Candy-specific fields such as exact platform node paths, mesh paths,
or fall-platform property names to the core modules. Games may use those names
inside their own `difficulty.curve` dictionaries and rules adapters.

## Core Boundary

Use `rules_adapter` for game-specific interpretation:

- Obby goal touch becomes a `goal_reached` move/event.
- Puzzle tile swap becomes a `swap_tiles` move/event.
- Runner collision becomes a `hit_obstacle` move/event.
- Tower defense wave clear becomes a `wave_cleared` move/event.

ShinokuteGameCore should not hardcode Candy Sky Islands node paths, Godot scene
paths, asset IDs, platform coordinates, coin positions, exact hazard nodes,
terrain props, cloud props, or map builder details. It should accept canonical
dictionaries/resources from the game and emit generic lifecycle events.

## 3d_obby Reference Profile

Candy Sky Islands is the reference `3d_obby` implementation:

- Completion: goal trigger reached, optional coin/checkpoint quota.
- Failure: player falls below configured reset plane.
- Scaling: route length grows, platform count rises, gap distance increases,
  verticality rises, hazard count rises, falling platform acceleration rises,
  and trigger delay shrinks.
- Scene nodes emit semantic signals. Progression manager decides next level.
- Stage builders are game-owned. They read `stage_segments` and optional
  `environment_segments`, map abstract segment keys to game-owned scene refs,
  and generate the current route at level start.

This is sample game logic, not a shared visual skin. Reuse the concepts and
schemas; do not copy Candy assets into core.

## genre_profiles

| Profile | completion_condition | difficulty.curve examples |
|---|---|---|
| `3d_obby` | reach goal, collect quota, checkpoint quota | fall delay, hazard speed, timer, path length |
| `runner` | distance/finish/boss reached | speed, obstacle density, lane pressure |
| `puzzle` | solve board or target score | move limit, blocker count, board size |
| `match3` | clear objective | target count, spawn weight, move limit |
| `tower_defense` | survive wave | enemy HP, spawn cadence, route pressure |

## Migration Rule

Before moving a game's progression into ShinokuteGameCore:

1. Make the game-local `progression.level_catalog` Resource pass tests.
2. Keep concrete gameplay rules in a `rules_adapter`.
3. Add core tests for schema/lifecycle only.
4. Do not move game skin, art paths, scene coordinates, or generated assets to
   core.
