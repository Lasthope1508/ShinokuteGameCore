# Runtime Core Usage

Use these helpers when a game needs reusable runtime plumbing. Core owns data flow and generic algorithms only. Games own ids, formulas, gameplay meaning, actor behavior, save policy, and UI/art presentation.

## RNG Stream

File:
- `addons/shinokute_game_core/runtime/rng_stream.gd`

Core owns:
- deterministic named random streams from a run seed
- float, int, integer range, and float range rolls
- snapshot and restore for replay/debug/save

Game owns:
- seed source and persistence
- stream names such as `spawn`, `drop`, `reward`, `mapgen`, or `spread`
- how roll values affect gameplay, drop odds, rewards, enemy choice, mapgen, or combat

UI/art owns:
- no RNG logic, except animation-only randomness that does not affect gameplay state

Minimal wiring:

```gdscript
var rng := ShinokuteRngStream.new()
rng.configure(run_seed)
var drop_roll := rng.next_float("drop")
var lane_index := rng.next_int("projectile_spread", lane_count)
var snapshot := rng.snapshot()
```

Use this when a system needs replayable rolls. Do not call engine-global random functions inside reusable core logic.

## Spawn Schedule Resolver

File:
- `addons/shinokute_game_core/runtime/spawn_schedule_resolver.gd`

Core owns:
- latest schedule entry lookup by caller-provided stage key
- scalar reads such as batch, interval, and telegraph delay
- spawn pattern dictionary lookup without interpreting VFX or enemy meaning
- weighted candidate selection through `weighted_picker.gd`
- generic budget filtering through `budget_resolver.gd`

Game owns:
- schedule resource location and schema names
- stage meaning such as wave, room, floor, or day
- enemy/item/archetype ids and role meaning
- active count dictionaries and key maps
- actual spawn positions after pattern resolution, safe-radius rules, actor creation, AI, HP, score, and drops

UI/art owns:
- warning visuals, labels, icons, sounds, and scale/offset metrics

Minimal wiring:

```gdscript
var resolver := ShinokuteSpawnScheduleResolver.new()
resolver.configure(schedule, {
	"stage_key": "wave",
	"weight_entries_key": "enemy_weights",
	"weighted_picker_script": preload("res://addons/shinokute_game_core/runtime/weighted_picker.gd"),
	"budget_resolver_script": preload("res://addons/shinokute_game_core/runtime/budget_resolver.gd"),
	"budget_sources": [
		{"source_key": "role_limits", "group": "role", "key_field": "role", "max_field": "max_alive"}
	]
})
var interval_ms := int(resolver.value_for_stage(wave, "spawn_interval_ms", 1000))
var pattern := resolver.pattern_for_stage(wave)
var enemy := resolver.select_entry_for_stage(wave, candidates, fallback, roll, active_counts, key_maps)
```

Do not put enemy ids or formulas in core. Put schedule values in game SSOT resources.

## Motion Core 2D

Files:
- `addons/shinokute_game_core/runtime/input_vector_filter_2d.gd`
- `addons/shinokute_game_core/runtime/kinematic_motion_solver_2d.gd`
- `addons/shinokute_game_core/runtime/steering_2d.gd`

Core owns:
- input vector filtering: deadzone, analog curve, and optional diagonal normalization
- kinematic velocity solving from current velocity, desired direction, delta, max speed, acceleration, deceleration, and turn acceleration
- steering directions for seek, arrive, and separation over caller-owned positions

Game owns:
- input action names and device mappings
- actor speed stats, acceleration values, friction/terrain modifiers, buffs, debuffs, knockback, dash, stun, AI goals, target choice, faction rules, collisions, and physics body integration
- when motion updates: realtime `_process`, fixed tick, tactical step, replay, or debug sim

UI/art owns:
- joystick art, keyboard prompts, motion trails, animation state, facing sprites, camera shake, and screen feedback

Minimal wiring:

```gdscript
var filter := ShinokuteInputVectorFilter2D.new()
var solver := ShinokuteKinematicMotionSolver2D.new()
var steering := ShinokuteSteering2D.new()

var desired := filter.filter(raw_input, {
	"deadzone": input_deadzone,
	"analog_curve": input_analog_curve,
	"normalize_diagonal": true
})
velocity = solver.solve_velocity(velocity, desired, delta, {
	"max_speed": player_speed,
	"acceleration": player_acceleration,
	"deceleration": player_deceleration,
	"turn_acceleration": player_turn_acceleration
})

var chase_direction := steering.arrive(enemy_position, target_position, arrive_radius)
var avoid_direction := steering.separation(enemy_position, neighbor_positions, separation_radius)
```

Use this for shared movement feel math. Do not make core decide what player, enemy, terrain, dash, slow, or attack behavior means.

## Targeting Query 2D

File:
- `addons/shinokute_game_core/runtime/targeting_query_2d.gd`

Core owns:
- nearest candidate query
- radius candidate query
- cone candidate query
- segment hit query sorted by travel order
- generic distance, angle, and segment metadata in reports

Game owns:
- candidate lists and payload ids
- faction/team rules, target validity, stealth/visibility, priority weights, and tie-break policy
- projectile hit lifecycle, pierce memory, damage, status effects, and score
- actor creation, collision layers, physics, and AI

UI/art owns:
- target markers, reticles, hit flashes, aim indicators, and tooltip text

Minimal wiring:

```gdscript
var query := ShinokuteTargetingQuery2D.new()
var target := query.nearest(player_position, candidates, {"max_distance": 600.0})
var pierce_hits := query.segment_hits(start, end, candidates, {"hit_radius": 8.0})
```

Use this for reusable geometry. Do not move shooter combat rules into this module.

## Grid Path Query 2D

File:
- `addons/shinokute_game_core/runtime/grid_path_query_2d.gd`

Core owns:
- in-bounds and blocked-cell checks over caller-provided config
- orthogonal or optional diagonal neighbor lookup
- shortest path by breadth-first search
- flood-fill distance fields with optional max distance
- ray cells and blocked-line report

Game owns:
- grid coordinate system and cell size
- terrain ids, passability rules, doors, traps, one-way edges, actor occupancy, faction blocking, and AI decisions
- map/chunk generation, room themes, encounter meaning, save policy, and action costs
- whether a path means move, aim, ability range, tower placement, or tactical preview

UI/art owns:
- path highlights, range overlays, line-of-sight tint, tile sprites, fog visuals, cursor prompts, and sounds

Minimal wiring:

```gdscript
var query := ShinokuteGridPathQuery2D.new()
var config := {
	"width": map_width,
	"height": map_height,
	"blocked": blocked_cells,
	"allow_diagonal": false
}
var path := query.shortest_path(actor_cell, target_cell, config)
var visible_line := not query.line_hits_blocked(actor_cell, target_cell, config).get("blocked", false)
```

Use this for future roguelike, tactical, tower-defense, and puzzle games. Do not wire it into First Peace's realtime horde loop unless the game adds an explicit grid/tactical mode.

## Grid Occupancy 2D

File:
- `addons/shinokute_game_core/runtime/grid_occupancy_2d.gd`

Core owns:
- generic cell entry placement, move, remove, lookup, and entries-at-cell queries
- blocked-cell and bounds rejection
- blocking versus non-blocking stack rules
- snapshot and restore of neutral occupancy state

Game owns:
- actor ids, pickup ids, terrain ids, faction rules, collision layers, path cost, AI decisions, spawn rules, item rules, and save/reset policy
- whether an occupied cell means blocked movement, target cover, pickup collection, loot stack, tower tile, trap, or interactable

UI/art owns:
- tile highlights, cursor prompts, occupancy debug overlays, icons, stack labels, sounds, and VFX

Minimal wiring:

```gdscript
var occupancy := ShinokuteGridOccupancy2D.new()
occupancy.configure({
	"width": map_width,
	"height": map_height,
	"blocked": wall_cells
})
occupancy.place({"id": actor_id, "cell": actor_cell, "layer": "actor", "blocks": true})
occupancy.place({"id": pickup_id, "cell": actor_cell, "layer": "pickup", "blocks": false})
var can_enter := occupancy.is_cell_available(target_cell, actor_id)
```

Do not store gameplay meaning in core occupancy entries beyond neutral fields such as `id`, `cell`, `layer`, `blocks`, and `tags`.

## Grid Placement Query 2D

File:
- `addons/shinokute_game_core/runtime/grid_placement_query_2d.gd`

Core owns:
- nearest free-cell candidate ordering around an origin
- caller-provided radius, bounds, blocked cells, occupancy object, and direction priority
- first-available report with no gameplay meaning

Game owns:
- why placement is happening: spawn, drop, player start, objective, trap, tower, tactical marker, or debug tool
- safe radius, encounter fairness, room/biome constraints, weighted spawn sources, enemy/item ids, and final create/apply logic

UI/art owns:
- preview rings, placement highlights, warning markers, invalid-cell tint, sounds, and animation

Minimal wiring:

```gdscript
var placement := ShinokuteGridPlacementQuery2D.new()
var result := placement.first_available(player_cell, {
	"width": map_width,
	"height": map_height,
	"radius": spawn_radius_cells,
	"blocked": blocked_cells,
	"occupancy": occupancy,
	"direction_priority": [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]
})
if result.get("status") == "found":
	_spawn_game_owned_actor_at_cell(result.get("cell"))
```

Use this for grid/tactical/roguelike placement plumbing. Realtime First Peace arena spawns still use world-space spawn helpers unless a future mode adds a grid layer.

## Visibility Field 2D

File:
- `addons/shinokute_game_core/runtime/visibility_field_2d.gd`

Core owns:
- visible-cell calculation from origin, radius, bounds, and caller-provided opaque cells
- seen-state merge from previous seen cells plus current visible cells
- line ray cells for visibility blocking
- cell query reports: `visible`, `seen`, or `hidden`

Game owns:
- terrain ids and which terrain/field/door/actor entries are opaque
- stealth, invisibility, awareness, smell/sound sensing, reveal rewards, trap reveal, quest discovery, and save/reset policy
- when visibility recomputes: move, turn, door open, field tick, light change, or debug mode

UI/art owns:
- fog sprites, dimming, minimap reveal, tile tint, line highlights, cursor text, sounds, and animation

Minimal wiring:

```gdscript
var visibility := ShinokuteVisibilityField2D.new()
var visible := visibility.compute_visible(player_cell, {
	"width": map_width,
	"height": map_height,
	"radius": vision_radius,
	"opaque": opaque_cells
})
seen_cells = visibility.update_seen(seen_cells, visible)
var state := visibility.query_cell(tile_cell, visible, seen_cells).get("state", "hidden")
```

Use this for roguelike/tactical visibility and fog logic. It is not a skin renderer and does not decide actor awareness.

## Map Layout Generator 2D

File:
- `addons/shinokute_game_core/runtime/map_layout_generator_2d.gd`

Core owns:
- caller-provided room rectangle normalization
- room center calculation
- sequence corridor cell generation between room centers
- combined floor-cell output

Game owns:
- room candidate source, procedural policy, seeds, terrain ids, wall/floor painting, biome/theme, props, encounter placement, spawn rules, objectives, and save policy
- whether corridor cells become floor, road, pipe, bridge, wire, path, or blocked preview

UI/art owns:
- tile sprites, room labels, minimap style, debug overlay, lighting, fog visuals, and decoration

Minimal wiring:

```gdscript
var layout_generator := ShinokuteMapLayoutGenerator2D.new()
var layout := layout_generator.build_layout({
	"width": map_width,
	"height": map_height,
	"rooms": room_rects,
	"connect": "sequence",
	"corridor_axis": "x_first"
})
for cell in layout.get("floor_cells", []):
	_paint_game_owned_floor(cell)
```

This is loaded into core for future roguelike/tactical/tower-defense/puzzle map work. First Peace does not use this module unless it later gets grid rooms, dungeon sectors, or generated arenas.

## Area Field Runtime 2D

File:
- `addons/shinokute_game_core/runtime/area_field_runtime_2d.gd`

Core owns:
- generic field entries keyed by caller-owned id
- circle and rect point/radius overlap queries
- elapsed duration, tick interval, tick event, expire event
- active field listing plus snapshot/restore

Game owns:
- field ids and field types such as smoke, fire, poison, slow, heal, aura, hazard, buff, or objective zone
- formulas, resistances, stack policy, actor effect application, source ownership, save/reset policy, and spawn rules
- whether field ticks are turn-based, realtime, wave-based, or encounter-based

UI/art owns:
- field labels, icons, shader/material, particle/VFX, audio loop, screen tint, tooltip text, and layout metrics

Minimal wiring:

```gdscript
var fields := ShinokuteAreaFieldRuntime2D.new()
fields.configure({"cell_size": tile_size})
fields.add_field({
	"id": field_id,
	"field_type": field_type,
	"position": world_position,
	"radius": radius,
	"intensity": intensity,
	"duration": duration_seconds,
	"tick_interval": tick_seconds,
	"tags": tags,
	"source": source_id
})

for event in fields.advance(delta):
	if event.get("type") == "tick":
		_apply_game_owned_field_effect(event)
```

This is future expansion plumbing only. It does not apply damage, status, score, screen effects, or labels.

## Runtime Ledger

File:
- `addons/shinokute_game_core/runtime/runtime_ledger.gd`

Core owns:
- generic named counters
- min/max/default clamping
- change reports
- event history
- snapshot and restore

Game owns:
- meaning of each counter such as HP, XP, shards, ammo, hunger, heat, or score
- formulas that change counters
- persistence rules and reset rules
- defeat, unlock, reward, and economy decisions

UI/art owns:
- HUD labels, bars, damage numbers, colors, fonts, icons, and animation

Minimal wiring:

```gdscript
var ledger := ShinokuteRuntimeLedger.new()
ledger.configure([
	{"id": "integrity", "min": 0, "max": 10, "default": 10},
	{"id": "signal", "min": 0, "default": 0}
])
var report := ledger.add("integrity", -damage, "enemy_contact")
```

Do not make core decide what zero HP means. Game rules decide.

## Inventory Container

File:
- `addons/shinokute_game_core/runtime/inventory_container.gd`

Core owns:
- generic slot capacity
- stack fill and overflow
- add/remove quantity reports
- total quantity lookup
- snapshot and restore

Game owns:
- item ids, item definitions, rarity, equipment rules, recipes, crafting, drops, shops, and save policy
- validation beyond generic quantity/capacity

UI/art owns:
- inventory screen, slot layout, icons, item names, descriptions, drag/drop, and tooltips

Minimal wiring:

```gdscript
var inventory := ShinokuteInventoryContainer.new()
inventory.configure({"capacity": 20, "default_max_stack": 99})
var result := inventory.add_item({"id": item_id, "quantity": amount, "max_stack": stack_limit})
```

Do not use this module for final item semantics. It is only the generic container.

## Turn-Based Action And Energy

Files:
- `addons/shinokute_game_core/runtime/turn_action_report.gd`
- `addons/shinokute_game_core/runtime/turn_energy_scheduler.gd`

Core owns:
- accepted/blocked action reports with actor id, action id, energy cost, effects, event keys, and message keys
- speed/energy/priority readiness for turn-based actors
- spend, snapshot, and restore for deterministic turn order

Game owns:
- concrete action handlers such as move, attack, open, pickup, use item, cast, wait, reload, or interact
- AI decision trees, player input mapping, grid/map semantics, combat formulas, inventory semantics, death checks, and system ticks
- whether a turn advances, how much energy an action costs, and what each effect/event/message means

UI/art owns:
- action prompts, logs, combat text, animation timing, indicators, and modal layouts

Minimal wiring:

```gdscript
var scheduler := ShinokuteTurnEnergyScheduler.new()
scheduler.configure([
	{"id": "player", "speed": 100.0, "priority": 10},
	{"id": "goblin", "speed": 80.0, "priority": 0}
], {"ready_threshold": 100.0})

for actor in scheduler.advance(1.0):
	var report := ShinokuteTurnActionReport.new()
	report.accept(String(actor.get("id", "")), "wait", {}, 100.0)
	scheduler.spend(String(actor.get("id", "")), float(report.to_dictionary().get("energy_cost", 100.0)))
```

Do not use this for realtime games like First Peace horde shooting. Realtime games should keep `_process`/timers for motion and use `EventTimeline`, `SpawnScheduleResolver`, `Steering2D`, projectile helpers, and presentation helpers.

### Future Gameplay Expansion Anchor

When the owner asks how to expand gameplay with inventory, grid movement, tactical range, or area fields, answer from this boundary:

Game-owned expansion modules:
- map/grid definition SSOT: grid size, cell size, terrain ids, passability tags, movement costs, one-way edges, room/chunk ids, encounter placement, save/reset rules
- path/range rule adapter: maps game terrain, doors, traps, actor occupancy, faction blocking, and ability rules into `GridPathQuery2D` config before querying
- visibility rule adapter: maps game terrain, fields, doors, light, stealth, and debug state into `VisibilityField2D` config and post-query actor awareness
- map layout adapter: turns `MapLayoutGenerator2D` room/corridor cells into game-owned tile painting, biome, props, enemies, objectives, and save state
- field definition SSOT: field ids, gameplay types, tags, duration values, tick intervals, stack policy, source ownership, and content-pack refs
- field effect runtime adapter: maps field tick/expire/query reports into game formulas such as damage, slow, reveal, heal, shield, objective capture, or status application
- item definition SSOT: ids, types, tags, rarity, max stack, gameplay effect ids, unlock requirements
- item effect runtime: maps item/effect ids into game formulas such as heal, XP, projectile unlock, stat buff, key gate, or consumable action
- inventory rule adapter: stack policy, unique policy, auto-pickup/manual-use policy, run/campaign/meta persistence, full-inventory handling
- equipment/loadout runtime if needed: weapon, armor, relic, passive, active, projectile modifier slots
- recipe/crafting runtime if needed: ingredients, outputs, station/tool gates, craft time, unlock requirements
- drop/pickup integration: enemy/boss drop tables, pickup nodes, add-to-inventory versus immediate apply
- save policy: run inventory reset, campaign inventory carry, meta inventory persist, debug seed/load behavior

UI/theme-owned expansion data:
- item labels, descriptions, icon keys, rarity colors, tooltip templates, inventory panel metrics, slot art, drag/drop visuals

Core helpers to reuse:
- `InventoryContainer` for stack/capacity only
- `TurnActionReport` and `TurnEnergyScheduler` only when the expansion is turn-based or tactical
- `GridPathQuery2D` for grid movement/range/LoS query only
- `GridOccupancy2D` for blocking/non-blocking cell occupancy only
- `GridPlacementQuery2D` for neutral nearest free-cell lookup only
- `VisibilityField2D` for visible/seen/hidden state only
- `MapLayoutGenerator2D` for generic room/corridor/floor-cell layout only
- `AreaFieldRuntime2D` for generic zone/cloud/tick/expire plumbing only
- `RequirementResolver` for item/recipe/unlock gates
- `DropTableResolver` for generic drops
- `RuntimeLedger` for currencies or quantities that are not physical item stacks
- `ContentPack` and validators for item/equipment/recipe table shape

Do not move item meanings, equipment semantics, crafting formulas, field meanings, terrain semantics, save decisions, labels, descriptions, or icons into core.

## Migration Rule

Before moving any game system into core:
- Write a failing core contract test.
- Extract only stable generic behavior.
- Keep game ids, formulas, and schemas in game resources or adapters.
- Keep labels, descriptions, icons, and layout in theme/UI SSOT.
- Add a game contract test showing the game uses the core helper through injected scripts or config.
