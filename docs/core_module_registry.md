# Core Module Registry

This is the SSOT entry map for ShinokuteGameCore modules. Read this before opening random scripts. Pick a module by function tag and genre tags, then read its contract test before editing.

Status:
- `ACTIVE`: reusable core module exists.
- `DOC_ONLY`: doctrine or usage guide only.
- `CANDIDATE`: planned extraction; do not use as completed core.

Ownership rule:
- Core owns generic plumbing and algorithms.
- Game owns ids, formulas, actor behavior, content meaning, save policy, and platform-specific adapters.
- UI/art/theme owns labels, descriptions, icons, layouts, colors, sounds, VFX, and screenshot proof.

## Use Order

1. Find matching `Function tag` or `Genre tags`.
2. Read `Use when` and `Do not use when`.
3. Open `Contract test`.
4. Open module file.
5. If no module fits, add a candidate first. Do not copy a game manager into core.

## Genre Tags

| Tag | Meaning |
|---|---|
| `all-casual` | Useful across most Shinokute casual games. |
| `mobile-web` | Mobile/HTML5 flow, input, save, UX, or publish concern. |
| `puzzle` | Grid, score, turn, level, or board puzzle games. |
| `arcade` | Timed, score, reflex, runner, avoider, or short-loop games. |
| `shooter-survivor` | Auto-fire, projectile, horde, wave, drop, upgrade games. |
| `roguelike` | Data-driven content, procedural, inventory, status, dungeon/room games. |
| `rpg` | Stats, items, equipment, status, abilities, progression games. |
| `tower-defense` | Spawn waves, targeting, projectiles, upgrades, economy. |
| `turn-based` | Action, energy, initiative, grid, FOV, and tactical turn-order games. |
| `tactical` | Positioning, initiative, action reports, line-of-fire, effects, and squad/encounter games. |
| `platformer-3d` | 3D character/camera/touch controller games. |
| `liveops` | Ads, analytics, remote config, leaderboard, profile. |
| `debug-publish` | Test evidence, telemetry, export, hosting, package checks. |

## Core Flow And Config

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|---|
| GameCoreConfig | ACTIVE | `core.config.ssot` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/core/game_core_config.gd` | `Tests/test_game_core_config.gd` | Game needs canonical id, Firebase, routes, overlays, ads, translations, theme, preload, progression config. | Do not put gameplay formulas, enemy ids, item ids, UI layout text, or art placement here unless field is explicitly a core config route/key. |
| GameCore | ACTIVE | `core.facade` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/core/game_core.gd` | `Tests/test_game_core_facade.gd` | Game needs one entrypoint for profile, save, leaderboard, services, UX, pause/input/runtime helpers. | Do not add game-specific gameplay rules or scene node assumptions. Use `GameRulesAdapter`. |
| GameSession | ACTIVE | `core.session.lifecycle` | `all-casual`, `puzzle`, `arcade`, `shooter-survivor`, `roguelike` | `addons/shinokute_game_core/core/game_session.gd` | `Tests/test_game_session_contract.gd` | Start/pause/resume/end run lifecycle and score deltas need shared handling. | Do not make session decide game-over formulas, level routes, or reward meaning. |
| GameRulesAdapter | ACTIVE | `core.rules.adapter` | `all-casual` | `addons/shinokute_game_core/core/game_rules_adapter.gd` | `Tests/test_game_session_contract.gd` | Game needs to plug rules into core session without copying core flow. | Do not move concrete rules into base adapter. Subclass/wrap in game. |
| ProgressionCatalog/Level | ACTIVE | `core.progression.ssot` | `all-casual`, `puzzle`, `arcade`, `shooter-survivor`, `roguelike`, `rpg` | `addons/shinokute_game_core/core/progression_catalog.gd`; `addons/shinokute_game_core/core/progression_level.gd` | `Tests/test_progression_catalog_contract.gd`; `Tests/test_gameplay_progression_doctrine.gd` | Game needs level ids, next-level handoff, completion/failure policy, layout/environment/difficulty profiles. | Do not put final art, UI labels, actor scripts, or formulas that only one game understands into core schema. |

## Profile Save Leaderboard

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|---|
| LocalSaveStore | ACTIVE | `core.save.local` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/core/local_save_store.gd` | `Tests/test_local_save_store.gd` | Profile/progress/local settings need HTML5-compatible `user://` save primitives. | Do not hardcode game inventory/progression structure here. Game decides save payload shape. |
| PlayerProfile | ACTIVE | `core.profile.username` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/core/player_profile.gd` | `Tests/test_player_profile.gd`; `Tests/test_username_prompt_scene_contract.gd` | Need first-run username, validation, profile-ready state, pending score flush gate. | Do not create game-specific result UI here. Function-skin UI belongs to game/theme. |
| LeaderboardClient | ACTIVE | `core.leaderboard.rest` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/core/leaderboard_client.gd` | `Tests/test_leaderboard_client.gd`; `Tests/test_game_core_facade.gd` | Need Firestore REST score submit/fetch with config-owned collections and sort. | Do not hardcode collection names, score labels, or sort direction in game scenes. |
| GeoService | ACTIVE | `core.geo.cache` | `mobile-web`, `liveops` | `addons/shinokute_game_core/core/geo_service.gd` | `Tests/test_geo_service.gd` | Need geolocation request/cache without fake hardcoded fallback country. | Do not infer user country in gameplay logic. |

## Services

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|---|
| ThemeConfig/ThemeManager | ACTIVE | `service.theme.tokens` | `all-casual`, `mobile-web` | `addons/shinokute_game_core/services/shinokute_theme_config.gd`; `addons/shinokute_game_core/services/theme_manager.gd` | `Tests/test_core_services_contract.gd` | Game needs skin colors, fonts, asset paths, audio events, UI metrics. | Do not put gameplay content ids or formulas in theme; only presentation keys and metrics. |
| AudioHapticsManager | ACTIVE | `service.audio.haptics` | `all-casual`, `mobile-web`, `arcade` | `addons/shinokute_game_core/services/audio_haptics_manager.gd` | `Tests/test_core_settings_audio_contract.gd`; `Tests/test_core_services_contract.gd` | Event-based SFX and vibration toggles need shared flow. | Do not hardcode game-specific audio paths outside theme/config. |
| AdsManager | ACTIVE | `service.ads.provider-neutral` | `mobile-web`, `liveops` | `addons/shinokute_game_core/services/ads_manager.gd` | `Tests/test_core_services_contract.gd` | Need placement registry, cooldown checks, provider-neutral ad request signals. | Do not put real unit ids or reward policy in core logic. |
| AnalyticsTracker | ACTIVE | `service.analytics.provider-neutral` | `mobile-web`, `liveops`, `debug-publish` | `addons/shinokute_game_core/services/analytics_tracker.gd` | `Tests/test_core_services_contract.gd` | Need provider-neutral event tracking and event cache. | Do not make gameplay decisions from analytics module. |
| LocalizationService | ACTIVE | `service.localization` | `all-casual`, `mobile-web` | `addons/shinokute_game_core/services/localization_service.gd` | `Tests/test_core_services_contract.gd` | Need locale lookup, fallback, parameter replacement. | Do not store gameplay formulas or ids as translated text. |
| RemoteConfigService | ACTIVE | `service.remote-config` | `mobile-web`, `liveops` | `addons/shinokute_game_core/services/remote_config_service.gd` | `Tests/test_core_services_contract.gd` | Need local defaults plus runtime override layer. | Do not bypass game SSOT with ad hoc remote keys. |

## UX And UI

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|---|
| SceneRouter | ACTIVE | `ux.route.scene` | `all-casual`, `mobile-web` | `addons/shinokute_game_core/ux/scene_router.gd` | `Tests/test_core_ux_contract.gd` | Need scene key to scene path routing. | Do not hardcode game route paths in gameplay scripts. |
| OverlayManager | ACTIVE | `ux.overlay.route` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/ux/overlay_manager.gd` | `Tests/test_core_ux_contract.gd` | Need overlay registry and provider-neutral show/hide signals. | Do not solve modal stacking rules here; use `ModalLifecycle` for one-active-modal runtime state. |
| UsernamePromptOverlay | ACTIVE | `ui.profile.username-prompt` | `all-casual`, `mobile-web`, `liveops` | `addons/shinokute_game_core/ui/username_prompt_overlay.gd` | `Tests/test_username_prompt_scene_contract.gd` | Need reusable first-run username prompt. | Do not treat this as final game function-skin UI unless game has themed it and screenshot-tested it. |

## Runtime Plumbing

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| PauseController | ACTIVE | `runtime.pause.state` | `all-casual`, `mobile-web`, `arcade`, `shooter-survivor` | `addons/shinokute_game_core/runtime/pause_controller.gd` | `Tests/test_runtime_core_contract.gd` | Need shared pause state and process-mode switching. | Do not put game-specific pause menu UI or button labels here. |
| InputBindingManager | ACTIVE | `runtime.input.rebind` | `all-casual`, `mobile-web`, `arcade`, `platformer-3d` | `addons/shinokute_game_core/runtime/input_binding_manager.gd` | `Tests/test_runtime_core_contract.gd` | Need configurable `InputMap` action defaults and rebinding specs. | Do not put gameplay action effects here. |
| InputVectorFilter2D | ACTIVE | `runtime.input.vector-filter` | `all-casual`, `mobile-web`, `arcade`, `shooter-survivor`, `rpg`, `platformer-3d` | `addons/shinokute_game_core/runtime/input_vector_filter_2d.gd` | `Tests/test_runtime_core_contract.gd` | Need deadzone, analog curve, and diagonal normalization over caller-owned input vectors. | Do not put action meaning, device UI prompts, player abilities, speed values, or animation in core. |
| KinematicMotionSolver2D | ACTIVE | `runtime.motion.kinematic` | `all-casual`, `arcade`, `shooter-survivor`, `rpg`, `platformer-3d`, `tactical` | `addons/shinokute_game_core/runtime/kinematic_motion_solver_2d.gd` | `Tests/test_runtime_core_contract.gd` | Need generic velocity solving with max speed, acceleration, deceleration, and turn acceleration. | Do not put actor stats, terrain friction, collisions, knockback semantics, AI goals, or animation in core. |
| Steering2D | ACTIVE | `runtime.motion.steering` | `arcade`, `shooter-survivor`, `rpg`, `tower-defense`, `tactical` | `addons/shinokute_game_core/runtime/steering_2d.gd` | `Tests/test_runtime_core_contract.gd` | Need generic seek, arrive, and separation direction helpers over caller-owned positions. | Do not put enemy roles, target validity, formations, pathfinding, flock identity, or combat behavior in core. |
| SpawnPool | ACTIVE | `runtime.pool.spawn` | `arcade`, `shooter-survivor`, `tower-defense`, `rpg` | `addons/shinokute_game_core/runtime/spawn_pool.gd` | `Tests/test_runtime_core_contract.gd` | Need reusable instance pooling for projectiles, pickups, VFX, or high-churn nodes. | Do not put projectile/enemy behavior or art selection in pool. |
| InteractionBus | ACTIVE | `runtime.event.bus` | `all-casual`, `arcade`, `shooter-survivor`, `rpg`, `roguelike` | `addons/shinokute_game_core/runtime/interaction_bus.gd` | `Tests/test_runtime_core_contract.gd` | Need channel-scoped runtime payload dispatch. | Do not use as hidden global state for game rules. Payload meaning stays game-owned. |
| ScenePreloadCache | ACTIVE | `runtime.preload.cache` | `all-casual`, `mobile-web` | `addons/shinokute_game_core/runtime/scene_preload_cache.gd` | `Tests/test_runtime_core_contract.gd` | Need preload/cache helper for boot and scene transitions. | Do not hardcode game scene paths outside config. |
| ResourceRegistry | ACTIVE | `runtime.resource.registry` | `all-casual`, `mobile-web` | `addons/shinokute_game_core/runtime/resource_registry.gd` | `Tests/test_runtime_core_contract.gd`; `Tests/test_game_core_facade.gd` | Need semantic key to resource path/type/required/fallback lookup. | Do not copy editor resource manager UI into runtime. |
| RuntimeDebugSnapshot | ACTIVE | `runtime.debug.snapshot` | `debug-publish`, `all-casual` | `addons/shinokute_game_core/runtime/runtime_debug_snapshot.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic run/debug evidence with node names and caller sections. | Do not use as gameplay save state. |
| TelemetryEventSchema | ACTIVE | `runtime.telemetry.schema` | `debug-publish`, `liveops`, `all-casual` | `addons/shinokute_game_core/runtime/telemetry_event_schema.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need validate/normalize telemetry payloads. | Do not hardcode vendor SDK or game formulas here. |

## Data And Content

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| ContentTableValidator | ACTIVE | `content.schema.validate` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/content_table_validator.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need required fields, primitive types, unique ids, and refs checked. | Do not encode game table semantics here beyond generic schema rules. |
| ContentPack/Table/ReferenceGraph/Query | ACTIVE | `content.pack.query` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/content_pack.gd`; `content_table.gd`; `content_reference_graph.gd`; `content_query.gd` | `Tests/test_content_pack_core_contract.gd` | Need pack metadata, `copy_from`, cross-table refs, groups, type/tag/requirement filtering. | Do not store labels/icons in gameplay content pack when theme/UI SSOT should own presentation. |
| DefinitionResolver | ACTIVE | `content.definition.resolve` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/definition_resolver.gd` | `Tests/test_runtime_core_contract.gd` | Need canonical definitions merged with weighted id pools. | Do not make upgrade/item effects core-owned. |
| RequirementResolver | ACTIVE | `content.requirement.resolve` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense`, `puzzle` | `addons/shinokute_game_core/runtime/requirement_resolver.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic AND/OR/NOT, flags, tags, and grouped count gates. | Do not put quest/story/item meanings in core. |
| ModifierStack | ACTIVE | `content.modifier.stack` | `rpg`, `roguelike`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/modifier_stack.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need add/multiply/set modifiers with optional duration/source removal. | Do not put specific stat formulas or upgrade ids in core. |
| ActionEffectReport | ACTIVE | `content.action.report` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense`, `puzzle` | `addons/shinokute_game_core/runtime/action_effect_report.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need accepted/blocked action report with caller-owned effects/events. | Do not apply game effects here. |

## Combat Geometry And Projectiles

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| RngStream | ACTIVE | `runtime.rng.stream` | `all-casual`, `roguelike`, `shooter-survivor`, `tower-defense`, `rpg`, `debug-publish` | `addons/shinokute_game_core/runtime/rng_stream.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need deterministic named roll streams and snapshot/restore for replay/debug. | Do not put drop odds, spawn choices, or gameplay meanings in RNG. |
| ProjectileBlueprintComposer2D | ACTIVE | `combat.projectile.compose` | `shooter-survivor`, `tower-defense`, `rpg` | `addons/shinokute_game_core/runtime/projectile_blueprint_composer_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need merge base projectile/weapon dictionary with generic modifiers. | Do not put projectile ids, damage formulas, VFX, or targeting mode meanings in core. |
| AttackPatternResolver2D | ACTIVE | `combat.attack.pattern` | `shooter-survivor`, `tower-defense`, `arcade` | `addons/shinokute_game_core/runtime/attack_pattern_resolver_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need emission lanes for instances, spread, and spawn offset. | Do not decide target, hit, damage, cooldown, or visuals. |
| SpatialHash2D | ACTIVE | `combat.spatial.index` | `shooter-survivor`, `tower-defense`, `arcade`, `rpg` | `addons/shinokute_game_core/runtime/spatial_hash_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic id/position/radius nearby queries. | Do not interpret collision, team, damage, or visibility. |
| TargetingQuery2D | ACTIVE | `combat.targeting.query` | `shooter-survivor`, `tower-defense`, `rpg`, `roguelike`, `arcade` | `addons/shinokute_game_core/runtime/targeting_query_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need nearest/radius/cone/segment geometry query and pierce travel order. | Do not put faction, target validity, damage, pierce memory, UI prompts, or enemy meanings in core. |
| GridPathQuery2D | ACTIVE | `grid.path.query` | `turn-based`, `roguelike`, `tactical`, `tower-defense`, `puzzle`, `rpg` | `addons/shinokute_game_core/runtime/grid_path_query_2d.gd` | `Tests/test_grid_area_core_contract.gd` | Need generic grid neighbors, shortest path, distance field, and ray cells over caller-owned passability data. | Do not put terrain ids, monster ids, AI decisions, trap semantics, map themes, or visuals in core. |
| GridOccupancy2D | ACTIVE | `grid.occupancy.state` | `turn-based`, `roguelike`, `tactical`, `tower-defense`, `puzzle`, `rpg` | `addons/shinokute_game_core/runtime/grid_occupancy_2d.gd` | `Tests/test_grid_occupancy_placement_core_contract.gd` | Need generic cell occupancy for blocking and non-blocking entries, blocked cells, move/remove, and snapshot/restore. | Do not put actor ids, faction rules, terrain meanings, pickup meanings, AI, collision layers, save policy, or visuals in core. |
| GridPlacementQuery2D | ACTIVE | `grid.placement.query` | `turn-based`, `roguelike`, `tactical`, `tower-defense`, `puzzle`, `rpg`, `shooter-survivor` | `addons/shinokute_game_core/runtime/grid_placement_query_2d.gd` | `Tests/test_grid_occupancy_placement_core_contract.gd` | Need stable nearest free-cell candidate queries around an origin using caller-owned radius, bounds, blocked cells, occupancy, and direction priority. | Do not put spawn rules, safe-radius policy, item placement semantics, enemy placement, room meanings, UI highlights, or art in core. |
| VisibilityField2D | ACTIVE | `grid.visibility.field` | `turn-based`, `roguelike`, `tactical`, `tower-defense`, `puzzle`, `rpg` | `addons/shinokute_game_core/runtime/visibility_field_2d.gd` | `Tests/test_visibility_map_layout_core_contract.gd` | Need generic visible-cell, seen-cell, line-of-sight, and query-state helpers over caller-owned opaque cells. | Do not put stealth, invisibility, monster awareness, fog art, minimap, tile tint, reveal rewards, or UI in core. |
| MapLayoutGenerator2D | ACTIVE | `map.layout.generate` | `turn-based`, `roguelike`, `tactical`, `tower-defense`, `puzzle` | `addons/shinokute_game_core/runtime/map_layout_generator_2d.gd` | `Tests/test_visibility_map_layout_core_contract.gd` | Need generic room rectangle normalization, room floor cells, and caller-owned corridor links. | Do not put terrain ids, biomes, props, enemy spawns, objective placement, art, or First Peace realtime arena rules in core. |
| AreaFieldRuntime2D | ACTIVE | `area.field.runtime` | `turn-based`, `roguelike`, `tactical`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/area_field_runtime_2d.gd` | `Tests/test_grid_area_core_contract.gd` | Need generic area/cloud/zone field storage, point/radius query, tick events, expire events, and snapshot/restore. | Do not put fire/poison/gas meanings, damage formulas, resistances, actor effects, labels, VFX, sounds, or UI in core. |
| NumericEffectResolver | ACTIVE | `combat.numeric.effect` | `rpg`, `roguelike`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/numeric_effect_resolver.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic add/multiply/resistance/crit/min/max/round reports. | Do not decide HP, shield, healing, score, death, or status application. |
| StatusEffectRuntime | ACTIVE | `combat.status.runtime` | `rpg`, `roguelike`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/status_effect_runtime.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need timed stack/tick/expire status runtime. | Do not put poison/fire/freeze meanings, VFX, or stat formulas here. |

## Spawn Reward Pickup Inventory

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| WeightedPicker | ACTIVE | `runtime.weighted.pick` | `all-casual`, `roguelike`, `shooter-survivor`, `tower-defense`, `rpg` | `addons/shinokute_game_core/runtime/weighted_picker.gd` | `Tests/test_runtime_core_contract.gd`; `Tests/test_grid_area_core_contract.gd` | Need weighted dictionary choice by id/key, with optional stable sort for deterministic source-order-independent picks. | Do not put enemy/reward meaning, rarity policy, pity rules, or unlock logic in picker. |
| LimitedCounter | ACTIVE | `runtime.counter.limit` | `all-casual`, `roguelike`, `rpg`, `shooter-survivor`, `tower-defense`, `puzzle` | `addons/shinokute_game_core/runtime/limited_counter.gd` | `Tests/test_runtime_core_contract.gd` | Need generic per-id counts, max quantity limits, consume checks, and capped entry filtering. | Do not put upgrade ids, reward meanings, inventory semantics, save policy, labels, icons, or UI in core. |
| BudgetResolver | ACTIVE | `runtime.budget.filter` | `shooter-survivor`, `tower-defense`, `roguelike`, `rpg` | `addons/shinokute_game_core/runtime/budget_resolver.gd` | `Tests/test_runtime_core_contract.gd` | Need generic group/key/max/current-count filtering. | Do not hardcode roles, archetypes, or enemy ids in core. |
| RunRewardPicker | ACTIVE | `reward.option.pick` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/run_reward_picker.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need weighted reward options with requirements, caps, banish/exclusion, unique selection. | Do not apply upgrade effects or choose UI labels/icons. |
| DropTableResolver | ACTIVE | `reward.drop.resolve` | `shooter-survivor`, `roguelike`, `rpg`, `tower-defense` | `addons/shinokute_game_core/runtime/drop_table_resolver.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need chance, quantity, requirement-gated drop resolution. | Do not put item definitions, pickup effects, economy, or UI in core. |
| PickupAttractor2D | ACTIVE | `pickup.motion.attract` | `shooter-survivor`, `arcade`, `rpg` | `addons/shinokute_game_core/runtime/pickup_attractor_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic 2D attract/collect motion step. | Do not apply pickup effects or play visuals here. |
| EventTimeline | ACTIVE | `spawn.timeline.events` | `shooter-survivor`, `tower-defense`, `arcade`, `roguelike` | `addons/shinokute_game_core/runtime/event_timeline.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need elapsed-time event schedule helper. | Do not put enemy spawn meaning or wave rules in timeline. |
| SpawnPatternResolver2D | ACTIVE | `spawn.pattern.points` | `shooter-survivor`, `tower-defense`, `arcade`, `roguelike` | `addons/shinokute_game_core/runtime/spawn_pattern_resolver_2d.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need ring, edge, and lane point generation. | Do not create enemies, apply safe radius, or choose VFX. |
| SpawnTelegraphLifecycle | ACTIVE | `spawn.telegraph.lifecycle` | `shooter-survivor`, `tower-defense`, `arcade` | `addons/shinokute_game_core/runtime/spawn_telegraph_lifecycle.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need pending spawn delay lifecycle. | Do not choose warning art, enemy id, or spawn payload meaning. |
| SpawnScheduleResolver | ACTIVE | `spawn.schedule.resolve` | `shooter-survivor`, `tower-defense`, `roguelike`, `arcade` | `addons/shinokute_game_core/runtime/spawn_schedule_resolver.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need stage schedule lookup, scalar reads, pattern passthrough, weighted/budget-filtered entry selection. | Do not put wave semantics, enemy roles, spawn execution, HP, AI, or VFX in core. |
| RuntimeLedger | ACTIVE | `runtime.ledger.counters` | `all-casual`, `rpg`, `roguelike`, `shooter-survivor`, `tower-defense`, `puzzle` | `addons/shinokute_game_core/runtime/runtime_ledger.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic named counters, clamp reports, events, snapshot/restore. | Do not decide what HP zero, XP, ammo, economy, or score means. |
| InventoryContainer | ACTIVE | `inventory.container.stack` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `addons/shinokute_game_core/runtime/inventory_container.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need generic capacity, stack fill, add/remove reports, quantity, snapshot/restore. | Do not put item definitions, equipment, recipes, shops, save policy, labels, icons, or inventory UI in core. |

## Turn-Based Runtime

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|---|
| TurnActionReport | ACTIVE | `turn.action.report` | `turn-based`, `roguelike`, `rpg`, `tactical` | `addons/shinokute_game_core/runtime/turn_action_report.gd` | `Tests/test_turn_based_core_contract.gd` | Need accepted/blocked action records with actor id, action id, energy cost, effects, events, and message keys. | Do not execute movement, combat, item use, AI, messages, or UI here; game owns action handlers and meanings. |
| TurnEnergyScheduler | ACTIVE | `turn.energy.scheduler` | `turn-based`, `roguelike`, `rpg`, `tactical` | `addons/shinokute_game_core/runtime/turn_energy_scheduler.gd` | `Tests/test_turn_based_core_contract.gd` | Need generic speed/energy/priority turn readiness, spend, snapshot, and restore. | Do not use for realtime loops such as First Peace horde movement/fire updates; realtime games should use `_process`, timers, timeline, spawn, steering, and projectile helpers. |

## Presentation Primitives

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| FeedbackFormatResolver | ACTIVE | `presentation.feedback.format` | `all-casual`, `shooter-survivor`, `rpg`, `arcade` | `addons/shinokute_game_core/runtime/presentation/feedback_format_resolver.gd` | `Tests/test_runtime_core_contract.gd` | Need caller-owned text templates formatted with runtime values. | Do not store final labels outside theme/localization. |
| WorldFeedbackPresenter | ACTIVE | `presentation.feedback.world` | `shooter-survivor`, `rpg`, `arcade`, `tower-defense` | `addons/shinokute_game_core/runtime/presentation/world_feedback_presenter.gd` | `Tests/test_runtime_core_contract.gd` | Need world-to-screen feedback placement, TTL/drift cleanup. | Do not make damage/score/HP meaning or VFX identity core-owned. |
| HealthIndicatorPresenter | ACTIVE | `presentation.indicator.current-max` | `shooter-survivor`, `rpg`, `tower-defense`, `arcade` | `addons/shinokute_game_core/runtime/presentation/health_indicator_presenter.gd` | `Tests/test_runtime_core_contract.gd` | Need generic current/max label or bar indicator mechanics. | Do not make HP, boss, enemy, color, or label meaning core-owned. |
| ModalLifecycle | ACTIVE | `presentation.modal.lifecycle` | `all-casual`, `mobile-web`, `liveops`, `shooter-survivor` | `addons/shinokute_game_core/runtime/modal_lifecycle.gd` | `Tests/test_runtime_core_p0_p1_contract.gd` | Need one-active-modal guard with blocking/supersede rules. | Do not build overlay art or final function-skin UI here. |

## 3D Controllers

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| Character3DController | ACTIVE | `controller.3d.character` | `platformer-3d`, `arcade`, `mobile-web` | `addons/shinokute_game_core/controllers/character_3d_controller.gd` | `Tests/test_runtime_core_contract.gd` | Need reusable 3D movement, jump, fall, reset, Shift Lock facing. | Do not put game-specific abilities, models, skins, or level rules here. |
| FollowCamera3D | ACTIVE | `controller.3d.camera` | `platformer-3d`, `mobile-web` | `addons/shinokute_game_core/controllers/follow_camera_3d.gd` | `Tests/test_runtime_core_contract.gd` | Need rotate/zoom, mouse capture, Shift Lock camera sync, routed look/zoom. | Do not put game-specific cinematics or UI hints here. |
| MobileTouchControls3D | ACTIVE | `controller.3d.touch` | `platformer-3d`, `mobile-web` | `addons/shinokute_game_core/controllers/mobile_touch_controls_3d.gd` | `Tests/test_runtime_core_contract.gd` | Need touch pointer routing, guard zones, jump, look, pinch zoom, Web pointer bridge. | Do not put game-specific HUD art or ability buttons here. |

## Docs And Future Candidates

| Module | Status | Function tag | Genre tags | Core file | Contract test | Use when | Do not use when |
|---|---|---|---|---|---|---|
| Reskin Boundary Doctrine | DOC_ONLY | `doctrine.boundary.reskin` | `all-casual`, `mobile-web` | `docs/reskin_core_skin_boundary.md` | `Tests/test_reskin_boundary_doctrine.gd` | Need core/game/UI/art ownership decisions. | Do not skip before reskin edits. |
| Runtime Core Usage | DOC_ONLY | `doctrine.runtime.usage` | `all-casual`, `roguelike`, `shooter-survivor`, `rpg`, `tower-defense` | `docs/runtime_core_usage.md` | Registry + module tests | Need examples and boundary notes for runtime helpers. | Do not treat examples as game-specific values. |
| Content Pack Usage | DOC_ONLY | `doctrine.content.usage` | `roguelike`, `rpg`, `shooter-survivor`, `tower-defense` | `docs/content_pack_core_usage.md` | `Tests/test_content_pack_core_contract.gd` | Need data-driven content schema guidance. | Do not put presentation text/icons in gameplay content pack. |
| Shared Core Migration Candidates | DOC_ONLY | `doctrine.migration.candidates` | `all-casual`, `debug-publish` | `docs/shared_core_migration_candidates.md` | N/A | Need next extraction list and evidence. | Do not use candidate as completed runtime module. |
| AudioCore | CANDIDATE | `candidate.audio.core` | `all-casual`, `mobile-web`, `arcade` | TBD | TBD | Shared buses, SFX pool, BGM crossfade, HTML5 unlock need extraction. | Do not copy existing game audio managers. |
| PublishCore | CANDIDATE | `candidate.publish.core` | `mobile-web`, `debug-publish` | TBD | TBD | Export/package/runtime manifest/Firebase checks need extraction. | Do not claim publish-ready from docs alone. |
| SceneTransitionCore | CANDIDATE | `candidate.transition.scene` | `all-casual`, `mobile-web` | TBD | TBD | Fade/busy scene transition helpers need extraction. | Do not duplicate transition scenes across games. |
| OverlayCore | CANDIDATE | `candidate.overlay.behavior` | `all-casual`, `mobile-web`, `liveops` | TBD | TBD | Popup sizing/animation remains after modal lifecycle extraction. | Do not mix overlay art with core modal rules. |
