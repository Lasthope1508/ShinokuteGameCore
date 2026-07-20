# Content Pack Core Usage

Purpose: give reskin agents one canonical path for data-driven content without guessing where logic belongs.

## Boundary

Core owns:
- pack metadata: `id`, `version`, `dependencies`
- table registration by name
- `id` uniqueness and required/type validation
- `copy_from` inheritance inside one table
- cross-table reference validation
- generic queries by `type`, `tags`, and `requirements`
- generic group resolution from `items: [{ref: "table/id"}]`

Game owns:
- concrete table names such as enemies, projectiles, upgrades, recipes, waves, bosses, or items
- concrete field meanings such as damage, cooldown, pierce, hunger, armor, rarity, or AI role
- formulas that apply data to actors, combat, inventory, maps, waves, or rewards
- schema choices for each game content pack

UI/function skin owns:
- labels, descriptions, icons, panels, list rows, tabs, windows, text fit, and theme metrics
- how query results are displayed or selected

Forbidden:
- Do not put enemy ids, projectile ids, item ids, recipe ids, combat formulas, status names, UI text, or art paths into `ContentPackCore`.
- Do not make core apply gameplay effects. Core returns resolved dictionaries only.
- Do not bypass pack validation with ad hoc dictionary lookups in gameplay code once a pack/table is managed by this module.

## Source Lessons

- Cataclysm-DDA: large content tables need schema validation, references, inheritance, and grouped selection before content grows.
- Shattered Pixel Dungeon: actors/items/effects/levels/UI stay separated by responsibility.
- Dungeon Crawl Stone Soup: deep combat/action logic should expose reports/effects, but formulas remain game-owned.

## Files

- `addons/shinokute_game_core/runtime/content_pack.gd`
- `addons/shinokute_game_core/runtime/content_table.gd`
- `addons/shinokute_game_core/runtime/content_reference_graph.gd`
- `addons/shinokute_game_core/runtime/content_query.gd`
- `addons/shinokute_game_core/runtime/projectile_blueprint_composer_2d.gd`
- Existing dependencies:
  - `addons/shinokute_game_core/runtime/content_table_validator.gd`
  - `addons/shinokute_game_core/runtime/requirement_resolver.gd`

## Minimal Use

```gdscript
const ContentPack := preload("res://addons/shinokute_game_core/runtime/content_pack.gd")
const RequirementResolver := preload("res://addons/shinokute_game_core/runtime/requirement_resolver.gd")

var pack := ContentPack.new()
pack.configure({
	"id": "my_game_runtime_pack",
	"version": "1.0.0",
	"dependencies": [],
	"tables": {
		"projectiles": [
			{"id": "projectile_base", "abstract": true, "speed": 320, "tags": ["projectile"]},
			{"id": "pierce_bolt", "copy_from": "projectile_base", "damage": 3, "tags": ["piercing"]}
		],
		"upgrades": [
			{"id": "pierce_tuning", "projectile_id": "pierce_bolt", "tags": ["projectile"], "requirements": {"flag": "wave_2"}}
		],
		"groups": [
			{"id": "starter_pool", "items": [{"ref": "projectiles/pierce_bolt", "weight": 7}]}
		]
	},
	"schemas": {
		"projectiles": {"required": ["id"], "types": {"id": TYPE_STRING, "speed": TYPE_INT}},
		"upgrades": {"required": ["id", "projectile_id"], "refs": [{"field": "projectile_id", "table": "projectiles"}]},
		"groups": {"required": ["id"]}
	}
}, {"requirement_resolver_script": RequirementResolver})

if not pack.is_valid():
	push_error(str(pack.errors()))

var projectile := pack.entry("projectiles", "pierce_bolt")
var visible_projectiles := pack.entries("projectiles")
var upgrade_options := pack.query("upgrades", {
	"tags": ["projectile"],
	"context": {"flags": {"wave_2": true}}
})
var starter_pool := pack.resolve_group("groups", "starter_pool")
```

## Projectile Blueprint Composition

Use `ShinokuteProjectileBlueprintComposer2D` when a game has projectile or weapon blueprint dictionaries and independent upgrades must stack without overwriting each other.

Core composer owns:
- generic dictionary copy/merge
- operations: `add`, `multiply`, `set`, `max`, `min`, `set_if_greater`, `set_if_lower`, `append`, `append_unique`
- order-stable results when modifiers touch independent keys

Game still owns:
- projectile table name and ids
- field meanings such as pierce, instances, spread, damage, cooldown, hit radius, or targeting mode
- upgrade history, weapon selection, combat formulas, collision handling, VFX, and UI text

```gdscript
const ProjectileBlueprintComposer := preload("res://addons/shinokute_game_core/runtime/projectile_blueprint_composer_2d.gd")

var composer := ProjectileBlueprintComposer.new()
var pulse_orb := {
	"id": "pulse_orb",
	"pierce": 0,
	"instances": 1,
	"angular_spread": 0.0,
	"hit_radius": 40.0
}
var composed := composer.compose(pulse_orb, [
	{"target_key": "pierce", "operation": "add", "value": 1},
	{"target_key": "instances", "operation": "max", "value": 3},
	{"target_key": "angular_spread", "operation": "set_if_greater", "value": 24.0},
	{"target_key": "behavior_tags", "operation": "append_unique", "value": ["pierce", "spread"]}
])
```

If a game needs transform priority such as current weapon id versus cumulative modifiers, keep that resolver in game code and pass only the final generic modifier list to the composer.

## Skill Progression And Weapon Fusion

Use `SkillProgressionResolver` when a game has weapon/skill level tables and fusion/evolution readiness rules.

Core resolver owns:
- next-level lookup from caller-owned level tables
- preservation of caller-owned `taxonomy_id`
- generic requirement checks for fusion/evolution definitions
- ready/not-ready reports

Game still owns:
- weapon ids, projectile ids, `weapon_skill_id`, taxonomy mapping, level tables, fusion ids, counters, balance numbers, and runtime application
- how level modifiers affect projectile dictionaries, player stats, combat formulas, or encounter state
- save/reset policy for current weapon levels and unlocked fusions

UI/function skin still owns:
- labels, descriptions, icons, tooltips, and VFX names for upgrades, levels, and fusions

Do not infer `weapon_skill_id` from a projectile id in core. If a game wants a selected upgrade to level a weapon table, that upgrade must declare the game-owned skill id explicitly, and the game adapter must pass that id to `SkillProgressionResolver.next_level_entry(...)`.

## API

- `configure(pack: Dictionary, options: Dictionary = {})`
- `pack_id() -> String`
- `version() -> String`
- `dependencies() -> Array`
- `table_names() -> Array`
- `is_valid() -> bool`
- `errors() -> Array`
- `entries(table_name: String, include_abstract: bool = false) -> Array`
- `entry(table_name: String, id: String) -> Dictionary`
- `query(table_name: String, criteria: Dictionary = {}) -> Array`
- `resolve_group(group_table_name: String, group_id: String) -> Array`
- `ShinokuteProjectileBlueprintComposer2D.compose(base_blueprint: Dictionary, modifiers: Array = []) -> Dictionary`
- `ShinokuteProjectileBlueprintComposer2D.compose_many(base_blueprints: Array, modifiers_by_id: Dictionary = {}) -> Array`
- `SkillProgressionResolver.next_level_entry(level_tables: Array, skill_id: String, current_levels: Dictionary = {}) -> Dictionary`
- `SkillProgressionResolver.resolve_ready_progression(definitions: Array, counters: Dictionary, already_unlocked: Array = []) -> Dictionary`
- `SkillProgressionResolver.resolve_all_ready_progressions(definitions: Array, counters: Dictionary, already_unlocked: Array = []) -> Array`

Query criteria:
- `type`: exact match against entry `type`
- `tags`: all listed tags must be present on entry
- `context`: passed to `RequirementResolver` when entry has `requirements`

Group refs:
- `items: [{"ref": "table/id", ...metadata}]`
- returned entry merges target entry plus group item metadata such as `weight`

## Reskin Workflow

1. Define game-owned content tables and schemas in game data files or resources.
2. Load them into `ShinokuteContentPack`.
3. Fail fast if `pack.is_valid()` is false.
4. Query or resolve groups from game-owned systems.
5. Apply returned dictionaries in game-owned adapters/modules.
6. Keep UI labels/icons/layout in theme/function-skin data.

## Tests

Run core contract:

```powershell
$godot='C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$core='C:\Users\Admin\Desktop\Godot Casual Games\Shared\ShinokuteGameCore'
& $godot --headless --path $core --script "$core\Tests\test_content_pack_core_contract.gd"
```
