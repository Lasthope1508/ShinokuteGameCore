# Shared Core Migration Candidates

Date: 2026-07-04

Compared sources:
- Bloxchain: `C:/Users/Admin/Desktop/Game`
- Glyphflow Arrays: `C:/w/water/WaternetGodot_Cyberpunk`

Current core already covers profile, local save primitives, leaderboard REST payloads, geolocation, and first-run username prompt.

## Completed From Later Reskins

### BudgetResolverCore

Evidence:
- Last Hope First Peace threat schedule uses role/archetype caps to avoid unbounded specialist spawns.

Shared contract:
- generic `group` / `key` / `max` budget entries
- caller-owned current counts
- caller-owned key maps from gameplay dictionaries into generic budget groups
- no enemy ids, projectile ids, role names, reward ids, or gameplay meanings in core

### PresentationCore

Evidence:
- Last Hope First Peace needed repeated survivor-style damage labels, world-to-screen feedback placement, TTL/drift cleanup, and current/max HP indicators.

Shared contract:
- generic text formatter for caller-owned templates and values
- generic world feedback presenter with caller-owned camera, viewport, offset, font, color, and TTL config
- generic current/max indicator presenter with caller-owned node names, format, colors, offsets, and visibility rule
- no HP, damage, enemy, boss, projectile, pierce, or game-specific UI text meanings in core

### DataDrivenRuntimeCore

Evidence:
- Cataclysm-DDA data/json organization showed the value of schema-validated content tables, references, requirements, and data-first expansion.
- Shattered Pixel Dungeon source organization showed clean separation between actors/items/effects/levels/UI and reusable mechanics.
- Dungeon Crawl Stone Soup showed that action/combat depth needs generic effect reports and telemetry, while concrete formulas stay in game code.
- Last Hope First Peace bugs showed modal lifecycle, upgrade effect state, and debug snapshot primitives repeat across reskins.

Shared contract:
- generic `ActionEffectReport` accepted/blocked result plus caller-owned effects/events
- generic `ContentTableValidator` for ids, required fields, field types, and refs
- generic `ContentPack`, `ContentTable`, `ContentReferenceGraph`, and `ContentQuery` for pack metadata, `copy_from` inheritance, cross-table references, group refs, and type/tag/requirement filtering
- generic `RequirementResolver` for AND/OR/NOT, flags, tags, and grouped counts
- generic `ModifierStack` for add/multiply/set operations with durations and source removal
- generic `ModalLifecycle` for blocking and supersede rules
- generic `RuntimeDebugSnapshot` for evidence gathering
- generic `RunRewardPicker`, `EventTimeline`, `SpawnPatternResolver2D`, `PickupAttractor2D`, and `TelemetryEventSchema`
- no monster ids, item ids, combat formulas, recipes, inventory slots, mapgen, projectile meanings, concrete table semantics, or skin text in core

### SpawnScheduleResolverCore

Evidence:
- Last Hope First Peace needed wave schedule scalar reads, weighted enemy candidates, role/archetype caps, spawn patterns, and telegraph timing without hardcoded values.
- Survivor/horde references use spawn radius, spawn time, weighted enemy pools, and difficulty schedules as data, not manager constants.

Shared contract:
- generic stage schedule lookup using caller-provided `stage_key`
- generic scalar lookup for batch, interval, delay, or other caller-owned keys
- generic spawn pattern dictionary passthrough
- weighted entry selection through `WeightedPicker`
- budget filtering through `BudgetResolver` with caller-owned key maps and active counts
- no enemy ids, role meanings, spawn positions, AI, VFX, HP, or gameplay formulas in core

### RuntimeLedgerCore

Evidence:
- Last Hope First Peace repeatedly needed HP, signal XP, score, pickups, and upgrade state to be tracked without hardcoded scattered counters.
- CDDA/Shattered/DCSS-style systems separate generic resource bookkeeping from concrete gameplay meanings.

Shared contract:
- generic named counters with `min`, `max`, and `default`
- clamped set/add reports with previous/current/delta/source
- change event history
- snapshot and restore
- no HP, XP, ammo, hunger, score, death, unlock, economy, save, or UI meaning in core

### InventoryContainerCore

Evidence:
- CDDA/Shattered-style roguelike systems need reusable stack/capacity inventory plumbing, but item semantics vary heavily by game.

Shared contract:
- generic slot capacity
- generic stack fill, overflow, add/remove quantity reports
- quantity lookup and snapshot/restore
- no item definitions, equipment rules, recipes, crafting, shops, save policy, labels, icons, or UI in core

### RngStreamCore

Evidence:
- Shattered Pixel Dungeon keeps reusable random helpers and generator stack patterns for repeatable dungeon, item, and actor systems.
- Cataclysm-DDA mapgen, monstergroups, item groups, and procedural content need deterministic roll sources to reproduce generated state.
- Dungeon Crawl Stone Soup combat/ability/targeting systems use many roll gates; source organization keeps roll plumbing separate from concrete ability meaning.
- Godot projectile and survivor references need seeded rolls for spread, drops, spawn points, and reward choices.

Shared contract:
- deterministic named streams from caller-owned seed
- generic float, int, int range, and float range rolls
- snapshot and restore for replay/debug/save
- no item ids, enemy ids, map layouts, drop odds, reward meanings, combat formulas, or UI in core

### MotionCore

Evidence:
- Last Hope First Peace needed repeated player/enemy movement tuning without scattering deadzone, diagonal normalization, acceleration, deceleration, turn acceleration, seek, arrive, and separation math through gameplay scripts.
- Top-down shooter and survivor references share the same neutral motion primitives even when enemy roles, AI goals, terrain, collision, and animation differ.

Shared contract:
- generic input vector filtering with deadzone, analog curve, and diagonal normalization
- generic kinematic velocity solve using caller-owned max speed, acceleration, deceleration, and turn acceleration
- generic seek/arrive/separation vectors over caller-owned positions
- no actor ids, speed values, AI behavior, terrain semantics, physics body ownership, collisions, animation state, VFX, or UI prompts in core

### TargetingQueryCore

Evidence:
- Dungeon Crawl Stone Soup separates targetability, range, and ability targeting from concrete spell behavior.
- All-projectiles separates projectile directionality/spread from projectile semantics.
- Last Hope First Peace needed nearest enemy targeting and pierce segment behavior without duplicating geometry in every projectile.

Shared contract:
- generic nearest candidate query
- generic radius and cone candidate filters
- generic segment hit query sorted by travel order
- generic distance, angle, and segment metadata in reports
- no faction rules, target validity semantics, damage, enemy ids, projectile ids, pierce memory, VFX, or UI prompts in core

### TurnBasedActionCore

Evidence:
- Statico's Godot roguelike example uses action objects, action results, effects, messages, player action processing, monster energy, system ticks, and vision updates.
- Shattered Pixel Dungeon keeps actors on a time/priority scheduler, with blobs and buffs acting as turn participants.
- First Peace is realtime, so this must be marked turn-based-only and not wired into its horde shooter loop.

Shared contract:
- generic action report with actor id, action id, block reason, energy cost, effects, events, and message keys
- generic energy scheduler with speed, energy, priority, ready order, spend, snapshot, and restore
- no movement, attack, item use, AI, map, combat, death, message text, UI, or animation semantics in core

### GridPathQueryCore

Evidence:
- Shattered `PathFinder`/`Graph` and roguelike map generation code repeatedly need grid distance, reachability, neighbor, and path queries.
- DCSS tactical code relies on line-of-sight, target ranges, and path constraints.

Shared contract:
- grid neighbor lookup
- breadth-first/flood-fill distance fields
- shortest path over caller-owned bounds/blocked data
- ray cells and blocked-line report for line/range checks
- no terrain ids, monster ids, AI decisions, action costs, room themes, traps, labels, or visuals in core

### GridOccupancyPlacementCore

Evidence:
- Shattered-style actor/item/dungeon systems need one neutral source for which cells contain blocking actors, non-blocking pickups, or blocked terrain before pathing, FOV, placement, and action handlers run.
- Statico's Godot roguelike example keeps map cell occupancy and item-on-ground rules separate from rendering; the reusable part is the occupancy contract, not the item/combat semantics.
- First Peace does not use this yet because it is realtime world-space, but future roguelike/tactical/tower-defense reskins need cell occupancy and nearest free-cell lookup early.

Shared contract:
- generic blocking and non-blocking entries by cell
- blocked cell and bounds checks
- place/move/remove/entries-at-cell lookup
- snapshot and restore
- stable nearest free-cell candidate query using caller-owned radius, bounds, blocked cells, occupancy, and direction priority
- no actor ids, item meanings, terrain semantics, spawn policy, faction rules, AI, save policy, highlights, labels, or art in core

### AreaFieldRuntimeCore

Evidence:
- CDDA ammo/effects use generic trail/AOE/field data such as fire, smoke, acid, gas, and chance.
- DCSS clouds are a reusable tactical primitive.
- Shattered blobs show area effects as reusable timed actors, separate from concrete game effect semantics.

Shared contract:
- generic area field entries with id, position, radius/shape, intensity, duration, tick interval, tags, and source
- tick/expire reports
- query fields at point/radius
- no fire/poison/gas meanings, damage formulas, resistances, VFX, or labels in core

### VisibilityFieldCore

Evidence:
- Statico's Godot roguelike example keeps `visible_cells`, `seen_cells`, and FOV recompute separate from renderer decisions.
- Shattered Pixel Dungeon uses `heroFOV` and visited/mapped arrays across combat, items, actor visibility, and fog rendering.
- DCSS separates `see_cell`, `cell_see_cell`, and LOS bounds from concrete actor awareness and UI draw code.

Shared contract:
- compute visible cells from origin, bounds, radius, and caller-owned opaque cells
- merge current visible cells into previous seen cells
- return cell state reports: visible, seen, hidden
- no terrain ids, stealth/invisibility semantics, actor awareness, trap reveal, minimap, fog art, labels, or VFX in core

### MapLayoutGeneratorCore

Evidence:
- Godot roguelike references use generated rooms/corridors before game-specific tile painting, actors, and props.
- CDDA/CDDA-BN style data-driven mapgen shows map layout policy should be data/config driven and separate from terrain/item/monster meaning.
- Shattered and DCSS keep level/map geometry concerns separate from UI windows and actor combat.

Shared contract:
- normalize caller-owned room rectangles
- compute room centers
- generate generic sequence corridor cells
- emit combined floor cells for game-owned tile painting
- no terrain ids, biomes, props, enemy spawns, objective placement, art, save policy, or First Peace realtime arena rules in core

## Next Source-Derived Candidates

## P0 Candidates

### AudioCore

Evidence:
- `C:/Users/Admin/Desktop/Game/Resources/Globals/AudioManager.gd`
- `C:/w/water/WaternetGodot_Cyberpunk/Resources/Globals/AudioManager.gd`

Shared contract:
- canonical `Master`, `Music`, `SFX` buses
- saved volume/toggle flow
- pooled SFX playback
- BGM playback/crossfade
- theme-aware audio lookup
- HTML5 first-gesture unlock and debug state

Core should own the playback contract and expose adapters for game-specific stream lookup.

### PublishCore

Evidence:
- `C:/Users/Admin/Desktop/Game/docs/mobile_html5_asset_optimization_checklist.md`
- `C:/w/water/WaternetGodot_Cyberpunk/docs/mobile_html5_asset_optimization_checklist.md`
- `C:/w/water/WaternetGodot_Cyberpunk/docs/release_packaging_checklist.md`
- `runtime_asset_manifest.json` in both games

Shared contract:
- export preset audit
- runtime asset manifest schema
- PCK/AAB forbidden marker scan
- mobile and HTML5 compression checklist
- Firebase Hosting header checklist
- HTML5 audio packaging rule: export with Godot, do not custom-shell away imports

## P1 Candidates

### SceneTransitionCore

Evidence:
- `SceneRouter.gd` in both games
- `Scenes/Common/FadeTransition.gd` in both games

Core should own fade transitions, busy guards, and common scene change helpers.

### OverlayCore

Evidence:
- `Scenes/Common/ElasticOverlay.gd` in both games
- Bloxchain settings/leaderboard/username overlays
- Glyphflow profile popup

Generic modal lifecycle is now complete in `runtime/modal_lifecycle.gd`. Remaining OverlayCore candidate scope is open/close animation and reusable popup sizing hooks.

### AdCore

Evidence:
- `Resources/Globals/AdManager.gd` in both games

Core should own platform bridge wrappers and ad signals. Games keep unit ids and reward policy in config.

## P2 Candidates

### ThemeTokenCore

Evidence:
- `Resources/Globals/ThemeManager.gd` in both games

Core can own theme registry, save key, change signal, and generic UI token application. Game-specific `ThemeConfig` fields stay local.

### VfxCatalogCore

Evidence:
- Glyphflow has VFX layer, route, anchor, transition state, usage docs, parameter docs.
- Bloxchain has VFX config catalogs embedded in `ThemeManager.gd`.

Core can own effect catalog schema and documentation pattern. Game-specific routes and trigger rules stay local.

## Migration Rule

Do not copy whole game singletons into core. Extract the stable contract first, add tests in `ShinokuteGameCore/Tests`, then adapt each game through config/resources.
