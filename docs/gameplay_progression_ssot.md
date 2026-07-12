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
| `difficulty.dynamic_progression_profile` | `ShinokuteProgressionCatalog` resource | Data-owned formulas for generating fair infinite levels after authored onboarding rows. |
| `difficulty.profile` | Runtime dictionary | Values pushed into gameplay nodes that accept difficulty. |
| `layout.profile` | `ShinokuteProgressionLevel` rows | Numeric obby route metrics: route length, platform count, verticality, gap distance, and hazard count. |
| `layout.route_generator` | Shinokute core route generator plus game adapter | Builds traversal route from profile metrics without fixed per-level terrain coordinates. |
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
- `addons/shinokute_game_core/core/obby_route_generator_3d.gd` owns the
  canonical 3D obby route algorithm from `layout_profile` when
  `route_generator` is `shinokute_3d_obby_curve_v1`.
- `scripts/obby_route_generator.gd` is only a Candy adapter. It calls the core
  route algorithm and may add Candy-specific environment/decor segments such as
  candy clouds or wafer bricks.
- `scripts/obby_stage_builder.gd` consumes generated route/environment
  segments and maps abstract data keys such as `small`, `falling`, `goal`,
  `brick`, and `cloud` to Candy-owned scene refs exported on `World`.
- `addons/shinokute_game_core/core/dynamic_progression_resolver.gd` resolves
  `dynamic_progression_profile` for level numbers beyond the authored catalog.
  Candy owns the curve data; the core owns the generic resolver and canonical
  route-generator id default.

Candy difficulty is not only falling platform speed. Each row must scale map
shape through `layout.profile`: route length, platform count, verticality,
gap distance, and hazard count. It may also scale moving platform speed,
coin quota, timer budget, or checkpoint count, but those must be fields in
`ShinokuteProgressionLevel` or a successor core resource first.

Candy may use three authored onboarding levels, then continue with
`dynamic_progression_profile`. Dynamic progression must be SSOT data, not
hardcoded formulas inside a game scene or route generator. Each dynamic profile
must include curve data for route length, platform count, gap distance, route
width, turn cycles, verticality, descent ratio, platform mix, platform radii,
hazard density, and falling-platform timing. The same visible level number must
always resolve to the same difficulty and route seed, so random layout variation
is deterministic and fair across retries/devices.

Obby difficulty must not scale by making jumps impossible. Every generated
route must pass `tests/test_obby_route_solvability_contract.gd`. The contract
instantiates the real `objects/player.tscn`, runs the actual controller physics
for a forward double jump, then caps route landing-point distance to a safety
factor of that measured jump envelope. Do not validate jumps only against a
guessed or hand-written `max_step_distance`.

- consecutive clear landing gap at least `gap_distance` and within the measured
  player jump envelope safety cap,
- consecutive vertical delta within `max_step_height`,
- lateral X/Z route width at least `route_width` so generated maps are not a
  one-axis line,
- no final-goal falling hazard,
- falling platform delay at least `0.20s`,
- generated hazard count matching `hazard_count`.

Dynamic/infinite levels must pass the same contract for representative deep
levels such as 4, 10, 25, and 100. Gap distance may plateau at the measured
jump envelope cap; infinite difficulty should continue through longer routes,
more platforms, wider 3D route width, more turns, more hazards, tighter timing,
and controlled descent/ascent patterns instead of unbounded jump distance.

Generated obby routes must also honor `route_length` as cumulative clear
traversal gap length, not as a single straight-line start-to-goal span. A 3D
obby must be allowed to snake through X/Z space. If a longer route would make
adjacent landing gaps too far apart, raise `platform_count` in
`layout_profile`; do not silently shorten the generated map.

Core route generators must consume data-owned platform radii, platform mix,
route shape tuning, route seed, height wave, and descent ratio. They must not
hide magic difficulty constants such as platform size, lateral clamp ratio,
jitter, or recovery interval in game-local scripts without an SSOT key. Random
values must come from `route_seed`, derived from the level number by
`dynamic_progression_profile`, so the same level remains reproducible.

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
  monotonic validation directions. It may also own
  `dynamic_progression_profile` for infinite level generation.
- `ShinokuteProgressionLevel`: abstract, reusable level resource. It owns
  `progression.completion_condition`, `progression.failure_policy`,
  `layout.profile`, `layout.stage_segments`, `layout.environment_segments`,
  and `difficulty.curve`.
- `ShinokuteDynamicProgressionResolver`: abstract, reusable resolver. It reads
  catalog-owned dynamic curve data and returns the same profile shape as an
  authored `ShinokuteProgressionLevel`.
- `ShinokuteObbyRouteGenerator3D`: abstract, reusable 3D obby route generator.
  It owns `shinokute_3d_obby_curve_v1`, deterministic route seeding, platform
  mix selection, fair hazard placement, X/Z curve width, vertical waves,
  descent segments, and jump-envelope-safe per-step spacing. Game wrappers must
  not duplicate this math.
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
- Dynamic progression contract proves deep generated levels are deterministic,
  fair, visible to the player as level numbers, and still governed by SSOT.
- Reskin work can replace visuals without changing progression data.
