# Shinokute Game Core

Shared Godot addon for modules every Shinokute casual game needs: player profile, first-run username prompt, local save keys, geolocation cache, leaderboard payloads, game session flow, UX routing, theme services, ads, analytics, localization, remote config, audio, haptics, runtime pause/input/motion/pool/interaction contracts, preload caching, deterministic RNG streams, budget filtering, modal lifecycle guards, content-pack/table validation, inheritance, reference graphs, generic content queries, requirement checks, modifier stacks, projectile blueprint composition, attack pattern math, spatial hash queries, targeting queries, grid path queries, grid occupancy state, grid placement queries, visibility fields, map layout generation, area field runtime, drop table resolution, spawn telegraph lifecycle, numeric effect resolution, status effect timing, generic reward/timeline/spawn helpers, turn-based action/energy primitives, telemetry schemas, and semantic resource registry lookup.

This repo is the canonical home for reusable cross-game code. Individual games should configure the addon through `GameCoreConfig.tres` and should not copy/paste leaderboard or profile logic into gameplay scenes.

## Required Reskin Reading

Every agent must read `AGENTS.md` before touching game code for a new reskin.

Every agent must read `docs/core_module_registry.md` before looking for core scripts. This registry is the SSOT table for module function tags, genre tags, ownership, contract tests, and "do not use" boundaries.

Every agent must read `docs/reskin_core_skin_boundary.md` before reskinning any Shinokute game. Core owns behavior; each game owns game skin and function skin.

Every agent must read `docs/reskin_runbook.md` and create a game-local checklist from `docs/reskin_checklist_template.md` before production reskin edits.

Every agent adding data-driven enemies, projectiles, upgrades, items, recipes, waves, or groups must read `docs/content_pack_core_usage.md` before creating new game schemas.

Every agent wiring reusable spawn schedules, resource counters, or inventory slots must read `docs/runtime_core_usage.md` before adding game runtime plumbing.

Core wiring does not complete production UI. Each production game must create game-owned function-skin UI for enabled shared features such as username, leaderboard, result, settings, menus, ads, profile, and publish prompts.

Every agent must read `docs/asset_generation_guardrails.md` before generating or editing game art.

Every agent must read `docs/godot_web_publish_runbook.md` before giving the owner a web test link or publishing an official Godot Web build.

## Architecture

`addons/shinokute_game_core/` is split into three layers:

- `core/`: game-facing facade, config, save/profile/geo/leaderboard, run lifecycle, and rules adapter contract.
- `services/`: theme, audio/haptics, ads, analytics, localization, and remote config.
- `runtime/`: reusable pause state, input rebinding, input vector filtering, kinematic motion solving, steering helpers, spawn pooling, interaction bus, preload/cache helpers, deterministic RNG streams, budget filtering, presentation primitives, projectile blueprint composition, attack pattern math, spatial hash queries, targeting queries, grid path queries, grid occupancy state, grid placement queries, visibility fields, map layout generation, area field runtime, drop table resolution, spawn schedule resolution, spawn telegraph lifecycle, numeric effect resolution, status effect timing, runtime ledgers, inventory containers, turn-based action/energy primitives, and resource registry validation.
- `ux/`: scene routing and overlay routing.
- `ui/`: reusable UI scenes such as username prompt.

## Modules

Use `docs/core_module_registry.md` as the first module lookup table. It maps each function tag to genre tags, core files, contract tests, use cases, and boundaries. The list below is a prose summary only.

- `GameCoreConfig`: SSOT for game id, Firebase endpoint, score sort, collection names, username policy, and leaderboard display labels.
- `ShinokuteProgressionCatalog` and `ShinokuteProgressionLevel`: canonical SSOT schemas for level catalogs, completion/failure policies, data-driven route/layout profiles, environment segments, and difficulty curves.
- `GameCore`: single entrypoint that wires every core/service/UX module.
- `GameSession`: start/pause/resume/end run lifecycle, score deltas, and result signal.
- `GameRulesAdapter`: per-game rules API. New games subclass or wrap this instead of rewriting core flow.
- `LocalSaveStore`: ConfigFile-backed profile/progress storage compatible with HTML5 `user://`.
- `PlayerProfile`: first-run username policy, validation, default username generation, and profile-ready signals.
- `LeaderboardClient`: Firestore REST URL/payload/query builder and score submission/fetch orchestration.
- `GeoService`: geolocation request/cache handling without hardcoded country fallback.
- `ShinokuteThemeConfig` and `ShinokuteThemeManager`: skin colors, fonts, asset paths, audio event paths, and UI metrics.
- `ShinokuteAudioHapticsManager`: event-based SFX lookup and mobile vibration toggles.
- `ShinokuteAdsManager`: placement registry, cooldown checks, and provider-neutral ad request signals.
- `ShinokuteAnalyticsTracker`: provider-neutral event tracking signal and event cache.
- `ShinokuteLocalizationService`: locale table lookup with fallback and parameter replacement.
- `ShinokuteRemoteConfigService`: local defaults plus runtime override layer.
- `ShinokutePauseController`: shared pause state signal and process-mode switching for gameplay/menu node sets.
- `ShinokuteInputBindingManager`: configurable `InputMap` action defaults, rebinding, and serializable input specs.
- `ShinokuteInputVectorFilter2D`: generic deadzone, analog curve, and diagonal normalization over caller-owned input vectors. Games own action names, speed stats, abilities, UI prompts, and animation.
- `ShinokuteKinematicMotionSolver2D`: generic velocity solve with max speed, acceleration, deceleration, and turn acceleration. Games own actor stats, terrain/collision rules, knockback semantics, and physics integration.
- `ShinokuteSteering2D`: generic seek, arrive, and separation vectors. Games own enemy roles, AI goals, target validity, pathfinding, formations, and combat behavior.
- `ShinokuteSpawnPool`: reusable scene instance pooling for projectiles, pickups, VFX, and other high-churn nodes.
- `ShinokuteInteractionBus`: channel-scoped runtime payload dispatch for reusable damage, pickup, trigger, and UI event paths.
- `ShinokuteScenePreloadCache`: resource preload/cache helper for boot screens and scene transitions.
- `ShinokuteRngStream`: deterministic named random streams with float/int/range rolls and snapshot/restore. Games own seed source, stream names, and gameplay meaning.
- `ShinokuteBudgetResolver`: generic group/key/max/current-count filtering. Games own group mappings and gameplay meaning.
- `ShinokuteFeedbackFormatResolver`, `ShinokuteWorldFeedbackPresenter`, and `ShinokuteHealthIndicatorPresenter`: generic runtime presentation primitives for formatted labels, world-to-screen feedback placement, TTL/drift updates, and current/max indicators. Games own gameplay meaning and theme keys.
- `ShinokuteActionEffectReport`: generic accepted/blocked action report with caller-owned effects/events.
- `ShinokuteContentTableValidator`: generic table schema validation for required fields, unique ids, primitive field types, and allowed references.
- `ShinokuteContentPack`, `ShinokuteContentTable`, `ShinokuteContentReferenceGraph`, and `ShinokuteContentQuery`: generic content pack metadata, table inheritance through `copy_from`, cross-table references, group item refs, and query filters. Games own table names, field meanings, formulas, and schema content.
- `ShinokuteRequirementResolver`: generic AND/OR/NOT, flag, tag, and grouped count checks for unlocks, rewards, recipes, and gates.
- `ShinokuteModifierStack`: generic add/multiply/set modifier stack with optional duration and source removal.
- `ShinokuteProjectileBlueprintComposer2D`: generic dictionary composer for projectile or weapon blueprints. It applies caller-owned modifier keys and operations such as add, multiply, set, max, min, append, and append_unique without knowing projectile ids, enemy behavior, damage formulas, VFX, or UI labels.
- `ShinokuteAttackPatternResolver2D`: generic 2D emission lane resolver for instance count, angular spread, vertical spread, and spawn offset. Games own weapon/projectile ids, targeting, collision, formulas, and visuals.
- `ShinokuteSpatialHash2D`: generic id/position/radius spatial index for nearby queries. Games own collision meaning and result handling.
- `ShinokuteTargetingQuery2D`: generic nearest, radius, cone, and segment-hit geometry queries. Games own faction rules, target validity, damage, pierce memory, and visuals.
- `ShinokuteGridPathQuery2D`: generic grid neighbors, shortest path, distance fields, ray cells, and blocked-line checks. Games own terrain, action cost, occupancy, AI, map generation, and visuals.
- `ShinokuteGridOccupancy2D`: generic blocking/non-blocking cell entries, blocked cells, move/remove, entries-at-cell, and snapshot/restore. Games own actor ids, terrain meaning, pickup rules, faction blocking, AI, save policy, and visuals.
- `ShinokuteGridPlacementQuery2D`: generic nearest free-cell candidate and first-available lookup using caller-owned radius, bounds, blocked cells, occupancy, and direction priority. Games own spawn/drop/objective/tower semantics, safe-radius policy, and preview art.
- `ShinokuteVisibilityField2D`: generic visible/seen/hidden cell queries from bounds, radius, and opaque cells. Games own terrain opacity, stealth, awareness, reveal rules, fog art, and UI.
- `ShinokuteMapLayoutGenerator2D`: generic room rectangle, room center, corridor, and floor-cell layout helper. Games own terrain painting, biomes, props, spawns, objectives, art, and save policy.
- `ShinokuteAreaFieldRuntime2D`: generic circle/rect area field storage, point/radius query, tick/expire events, and snapshot/restore. Games own field meanings, formulas, actor effects, save policy, VFX, labels, and sounds.
- `ShinokuteDropTableResolver`: generic chance, quantity, and requirement-gated drop resolution. Games own item ids, pickup behavior, economy, XP, and UI.
- `ShinokuteSpawnTelegraphLifecycle`: generic pending spawn delay lifecycle. Games own spawn payload meaning, enemy creation, warning VFX, and art.
- `ShinokuteSpawnScheduleResolver`: generic stage schedule lookup, weighted candidate selection, and budget-filtered entry picking. Games own stage meaning, enemy/item ids, active counts, spawn execution, and tuning resources.
- `ShinokuteNumericEffectResolver`: generic numeric amount resolver for add/multiply/resistance/crit/min/max/round reports. Games own HP, shield, score, damage type, healing, and application semantics.
- `ShinokuteStatusEffectRuntime`: generic timed stack/tick/expire status runtime. Games own status ids, payload meanings, visuals, and effect application.
- `ShinokuteRuntimeLedger`: generic named counters with min/max/default clamps, change reports, event history, and snapshot/restore. Games own HP, XP, ammo, economy, and reset semantics.
- `ShinokuteInventoryContainer`: generic capacity, stack fill, add/remove reports, quantity lookup, and snapshot/restore. Games own item meanings, equipment, recipes, shops, and inventory UI.
- `ShinokuteTurnActionReport` and `ShinokuteTurnEnergyScheduler`: turn-based-only primitives for action reports and speed/energy/priority scheduling. Games own concrete actions, AI, combat, item use, movement, messages, and UI.
- `ShinokuteModalLifecycle`: generic one-active-modal lifecycle with blocking and supersede rules.
- `ShinokuteRuntimeDebugSnapshot`: generic snapshot builder for run/debug state and node names.
- `ShinokuteRunRewardPicker`: generic weighted reward option picker with requirements, caps, banish/exclusion, and unique selection.
- `ShinokuteEventTimeline`: generic elapsed-time event schedule helper.
- `ShinokuteSpawnPatternResolver2D`: generic ring, edge, and lane point generation for game-owned spawn systems.
- `ShinokutePickupAttractor2D`: generic 2D attract/collect motion step.
- `ShinokuteTelemetryEventSchema`: generic telemetry payload validation and normalization.
- `ShinokuteResourceRegistry`: semantic key to resource path/type/required/fallback lookup. Games own entries; core validates and loads without editor dock dependencies.
- `ShinokuteSceneRouter`: scene key to scene path routing.
- `ShinokuteOverlayManager`: overlay key registry and provider-neutral show/hide signals.
- `UsernamePromptOverlay`: reusable first-run prompt scene.

## New Game Contract

Each new mobile game should create these game-owned files:

- `Resources/Data/<game>_game_core_config.tres`: id, Firebase, leaderboard modes, routes, overlays, ad placements, translations, remote defaults, and `resource_registry` semantic keys.
- `Resources/Data/<game>_theme_config.tres`: colors, fonts, art paths, SFX paths, UI metrics.
- `Scripts/<GameName>Rules.gd`: rules adapter implementing `start_run`, `can_make_move`, `apply_move`, `is_game_over`, and `get_result`.
- Gameplay scenes call `GameCore.start_run`, `GameCore.session.apply_move`, `GameCore.submit_score`, and route/overlay services. They must not copy save, ads, leaderboard, profile, or settings code.
- Runtime-heavy games should use core pause/input/motion/pool/interaction/preload/resource-registry/rng/presentation/content-pack/projectile-composer/attack-pattern/spatial-hash/targeting/grid-path/grid-occupancy/grid-placement/visibility-field/map-layout/area-field/drop-table/spawn-schedule/spawn-telegraph/numeric-effect/status-runtime/ledger/inventory helpers. Turn-based games may also use action report and energy scheduler helpers. Games still own actor behavior, enemy AI, wave definitions, level data, projectile rules, terrain semantics, motion meaning, occupancy meaning, placement policy, map layout meaning, field meanings, content table schemas, art, VFX, presentation meaning, and function-skin UI.
- Each enabled shared core feature gets game-owned UI/function skin, SSOT/theme asset keys, contract tests, and screenshot evidence before that feature is complete.

## Reskin Automation Guardrails

- `tools/reskin_audit.ps1`: scans a target game for missing checklist,
  config, theme, rules adapter, contract test, screenshot evidence, copied
  managers, and hardcoded values. Run with `-FailOnWarnings` before claiming
  a reskin is ready.
- `templates/new_game`: starter files for a new reskin, including config
  templates, rules adapter template, contract test template, and screenshot
  verification checklist.
- `docs/asset_generation_guardrails.md`: asset manifest, Block Kit, proof over
  claims, and paid-generation rules inspired by Godogen's useful workflow
  pieces.
- `docs/external_godogen_notes.md`: Godogen ideas kept outside the production
  Shinokute reskin pipeline.

## Migration Roadmap

Next shared candidates live in `docs/shared_core_migration_candidates.md`.

Priority order:
- `AudioCore`: canonical buses, SFX pool, BGM player, saved toggles, HTML5 unlock/debug.
- `PublishCore`: export/package gates, runtime manifest schema, mobile/HTML5 checks.
- `SceneTransitionCore`: fade transition scene and scene router helper.
- `OverlayCore`: elastic popup animation and shared popup behavior. Generic modal lifecycle guards are complete.
- `AdCore`: platform bridge signal contract.
- `ThemeTokenCore` and `VfxCatalogCore`: only after at least two games share the same resource schema.

Completed extractions:
- `RuntimeCore`: pause state, input rebinding, spawn pooling, interaction bus, and preload/cache contracts extracted from the isometric template source without importing shooter-specific gameplay.
- `ResourceRegistryCore`: semantic resource key registry extracted from the template `resource_manager` lesson without importing its editor dock UI.
- `BudgetResolverCore`: generic group/key budget filtering extracted from Last Hope threat role caps without importing shooter enemy ids, roles, or spawn rules.
- `PresentationCore`: generic world feedback and current/max indicator primitives extracted from Last Hope combat feedback without importing HP, enemy, projectile, or damage meanings.
- `DataDrivenRuntimeCore`: generic action/effect reports, deterministic RNG streams, content pack/table validation, table inheritance, reference graphs, content queries, requirement resolution, modifier stacks, input vector filtering, kinematic motion solving, steering helpers, projectile blueprint composition, attack pattern math, spatial hash queries, targeting queries, grid path queries, grid occupancy state, grid placement queries, visibility fields, map layout generation, area field runtime, drop table resolution, spawn schedule resolution, spawn telegraph lifecycle, numeric effect resolution, status effect timing, modal lifecycle guards, debug snapshots, reward picking, event timelines, 2D spawn patterns, pickup attraction, runtime ledgers, inventory containers, turn-based action/energy primitives, and telemetry schemas learned from CDDA/Shattered/DCSS style data organization and Godot projectile/survivor/roguelike references without importing monster, item, recipe, concrete mapgen content, combat, status, field meanings, motion meanings, occupancy meanings, placement policies, inventory item meanings, or skin content.

## Tests

Run all contracts:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project='C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore'
Get-ChildItem "$project\Tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```
