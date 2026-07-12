# Gameplay Progression SSOT

This document is mandatory reading before adding level completion, fail/retry
logic, difficulty scaling, or genre-specific game rules to Candy Sky Islands.

## Canonical Keys

| Key | Owner | Purpose |
|---|---|---|
| `progression.level_catalog` | `ShinokuteProgressionCatalog` resource | Ordered canonical list of playable levels or generated stage profiles. |
| `progression.current_level_index` | `GameProgression` runtime state | Session level pointer. It is runtime state, not scene truth. |
| `progression.completion_condition` | `ShinokuteProgressionLevel` and rules adapter | Data-owned condition for clearing a level. |
| `progression.failure_policy` | `GameProgression` manager | Data-owned fail/retry policy such as retry current level without reloading the SceneTree. |
| `difficulty.curve` | `ShinokuteProgressionLevel` rows | Per-level difficulty profile. |
| `difficulty.profile` | Runtime dictionary | Values pushed into gameplay nodes that accept difficulty. |
| `layout.profile` | `ShinokuteProgressionLevel` rows | Numeric obby route metrics: route length, platform count, verticality, gap distance, and hazard count. |
| `layout.route_generator` | Game route generator script | Builds traversal route from profile metrics without fixed per-level terrain coordinates. |
| `layout.stage_segments` | `ShinokuteProgressionLevel` rows | Optional start/goal anchors or legacy fallback route. Do not use this as fixed terrain for scaled obby levels. |
| `layout.environment_segments` | `ShinokuteProgressionLevel` rows | Optional terrain/decor fallback. Generated obby terrain should come from the route generator. |

Scenes may expose stable node targets such as `Player`, `World`, and `flag`.
Scenes must not own the meaning of level order, win condition, or difficulty.

## Candy Sky Islands Reference

Game family: `3d_obby`.

Current reference implementation:

- `Resources/Data/Progression/candy_sky_islands_obby_progression.tres`
  owns `progression.level_catalog`.
- `scripts/game_progression.gd` owns runtime state, goal completion,
  fail/retry, and difficulty application.
- `objects/goal_flag.gd` emits `goal_reached`; it does not decide next level.
- `scripts/player.gd` exposes `fall_reset_y` and emits
  `fell_out_of_bounds`; it does not own progression.
- Web runtime rule: falling, death, and win transitions must not use
  `reload_current_scene()` or scene changes from physics/signal callbacks. The
  progression manager must defer the transition, keep the current main scene
  instance, rebuild `World/GeneratedStage` from `stage_segments`, and call
  `Player.reset_for_level(...)`.
- `objects/platform_falling.gd` exposes `apply_difficulty_profile`; it does
  not own the difficulty curve.
- `scripts/obby_route_generator.gd` builds Candy's current route from
  `layout_profile` when `route_generator` is `candy_curve_v1`.
- `scripts/obby_stage_builder.gd` consumes generated route/environment
  segments and maps abstract data keys such as `small`, `falling`, `goal`,
  `brick`, and `cloud` to Candy-owned scene refs exported on `World`.

Candy difficulty is not only falling platform speed. Each row must scale map
shape through `layout.profile`: route length, platform count, verticality,
gap distance, and hazard count. It may also scale moving platform speed,
coin quota, timer budget, or checkpoint count, but those must be fields in
`ShinokuteProgressionLevel` or a successor core resource first.

Obby difficulty must not scale by making jumps impossible. Every generated
route must pass `tests/test_obby_route_solvability_contract.gd`. The contract
instantiates the real `objects/player.tscn`, runs the actual controller physics
for a forward double jump, then caps route landing-point distance to a safety
factor of that measured jump envelope. Do not validate jumps only against a
guessed or hand-written `max_step_distance`.

- consecutive horizontal step distance within the measured player jump envelope
  safety cap,
- consecutive vertical delta within `max_step_height`,
- no final-goal falling hazard,
- falling platform delay at least `0.20s`,
- generated hazard count matching `hazard_count`.

Generated obby routes must also honor `route_length` as the actual start-to-goal
span. If a longer route would make adjacent landing points too far apart, raise
`platform_count` in `layout_profile`; do not silently shorten the generated map.

Manual playtest remains required after the contract passes. Contract pass means
the route is inside the measured movement envelope; it does not replace playing
levels 1-3 with real keyboard/touch input.

## Shinokute Core Mapping

Reusable core owns lifecycle shape:

- start run,
- apply move/event,
- complete level,
- fail/retry,
- emit result,
- persist score/progress through configured services.

Game-specific rules stay behind a `rules_adapter`. Candy Sky Islands can later
map goal touch into a core event such as:

```gdscript
core.session.apply_move({
	"type": "goal_reached",
	"level_id": current_level.level_id,
	"coins": player.coins
})
```

Core should know `progression.level_catalog`,
`progression.completion_condition`, `progression.failure_policy`, and
`difficulty.curve` as schemas. Core should not know Candy asset paths,
platform node names, player GLB names, or exact obby map coordinates.

Shinokute core canonical schema:

- `ShinokuteProgressionCatalog`: abstract, reusable catalog resource. It owns
  `game_family`, `progression.level_catalog`, required difficulty keys, and
  monotonic validation directions.
- `ShinokuteProgressionLevel`: abstract, reusable level resource. It owns
  `progression.completion_condition`, `progression.failure_policy`,
  `layout.profile`, `layout.stage_segments`, `layout.environment_segments`,
  and `difficulty.curve`.
- Candy Sky Islands must use these core resource scripts directly in
  `Resources/Data/Progression/candy_sky_islands_obby_progression.tres`.
  Candy-specific values such as falling platform acceleration, trigger delay,
  route positions, terrain props, and goal placement live in data dictionaries,
  not in duplicate game-local schema classes or hardcoded validator branches.

## genre_profiles

Use the same canonical split for other genres:

| Profile | Completion condition | Difficulty curve examples |
|---|---|---|
| `3d_obby` | reach goal trigger, optional coin quota/checkpoint quota | longer route, more platforms, wider gaps, higher verticality, more hazards, shorter platform delay, faster moving hazards |
| `runner` | distance reached, boss reached, or finish line crossed | speed ramp, obstacle density, reaction window, lane count |
| `puzzle` | board solved or target score reached | move limit, board size, blocker count, spawn weights |
| `match3` | objective cleared | target count, move limit, blocker mix, cascade volatility |
| `tower_defense` | wave cleared or base survives | wave size, enemy HP, spawn cadence, route pressure |

No genre may scatter completion logic through random nodes. A scene node may
emit a semantic event; the progression/rules layer decides what that event
means.

## Done Criteria

- Level catalog lives in a Resource or core config, not in scattered scripts.
- Goal/fail nodes emit semantic signals only.
- Difficulty values come from `difficulty.curve`, not magic numbers in nodes.
- Route complexity comes from `layout.profile` and a route generator, not
  hand-placed static platform nodes in `main.tscn` or fixed per-level terrain
  coordinates.
- Terrain/decor comes from generated environment segments or explicit fallback
  `environment_segments`, not unrelated static scene leftovers.
- Contract tests load the config and prove difficulty increases.
- Solvability contract proves generated jumps stay inside player movement
  envelope before manual playtest.
- Reskin work can replace visuals without changing progression data.
