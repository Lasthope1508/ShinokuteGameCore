class_name SkillTaxonomyCatalog
extends RefCounted

const DEFAULT_SKILL_TAXONOMY_ENTRIES: Array = [
	{"id": "straight_shot", "kind": "weapon_family", "function_tag": "combat.weapon.straight_shot", "game_genre_tags": ["shooter-survivor", "arcade", "tower-defense"], "use_when": "Need one reliable projectile that tracks a single target or aim vector.", "do_not_use_when": "Do not use for split-shot or area-control roles."},
	{"id": "piercing_line", "kind": "weapon_family", "function_tag": "combat.weapon.piercing_line", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need line-clear shots that pass through aligned targets.", "do_not_use_when": "Do not use for pure splash or orbiting damage."},
	{"id": "spread_cone", "kind": "weapon_family", "function_tag": "combat.weapon.spread_cone", "game_genre_tags": ["shooter-survivor", "arcade", "tower-defense"], "use_when": "Need a fan, volley, or multi-lane shot pattern.", "do_not_use_when": "Do not use if single-target precision matters more than coverage."},
	{"id": "area_orb", "kind": "weapon_family", "function_tag": "combat.weapon.area_orb", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need a slow projectile or zone that owns a radius.", "do_not_use_when": "Do not use for fast hitscan or strict line shots."},
	{"id": "explosive_shell", "kind": "weapon_family", "function_tag": "combat.weapon.explosive_shell", "game_genre_tags": ["shooter-survivor", "arcade", "tower-defense"], "use_when": "Need burst splash, shard burst, or delayed explosion damage.", "do_not_use_when": "Do not use when splash would hide target selection or lane logic."},
	{"id": "chain_bolt", "kind": "weapon_family", "function_tag": "combat.weapon.chain_bolt", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need hit chaining across nearby targets.", "do_not_use_when": "Do not use when each hit must stay isolated."},
	{"id": "orbit_weapon", "kind": "weapon_family", "function_tag": "combat.weapon.orbit_weapon", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "arcade"], "use_when": "Need rotating blades, rings, shields, or contact auras.", "do_not_use_when": "Do not use for directional fire-first builds."},
	{"id": "aura_field", "kind": "weapon_family", "function_tag": "combat.weapon.aura_field", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need radial tick damage or persistent zone pressure.", "do_not_use_when": "Do not use if the game must read as projectile-forward only."},
	{"id": "trap_mine", "kind": "weapon_family", "function_tag": "combat.weapon.trap_mine", "game_genre_tags": ["tower-defense", "roguelike", "tactical"], "use_when": "Need placed hazards, mines, stakes, or delayed detonation tiles.", "do_not_use_when": "Do not use when the weapon must stay attached to player aim."},
	{"id": "summon_turret", "kind": "weapon_family", "function_tag": "combat.weapon.summon_turret", "game_genre_tags": ["tower-defense", "shooter-survivor", "roguelike", "rpg"], "use_when": "Need deployed allies, drones, or static turrets.", "do_not_use_when": "Do not use when summon logic would be indistinguishable from a projectile."},
	{"id": "boomerang_return", "kind": "weapon_family", "function_tag": "combat.weapon.boomerang_return", "game_genre_tags": ["arcade", "shooter-survivor", "rpg"], "use_when": "Need outbound and return travel with double-hit potential.", "do_not_use_when": "Do not use for one-way burst or pure hitscan."},
	{"id": "beam_channel", "kind": "weapon_family", "function_tag": "combat.weapon.beam_channel", "game_genre_tags": ["shooter-survivor", "rpg", "arcade"], "use_when": "Need sustained beam, sweep, or channel damage.", "do_not_use_when": "Do not use when attack cadence must be discrete per projectile."},
	{"id": "shotgun_burst", "kind": "weapon_family", "function_tag": "combat.weapon.shotgun_burst", "game_genre_tags": ["shooter-survivor", "arcade"], "use_when": "Need close-range pellet burst or cone burst.", "do_not_use_when": "Do not use when range and pierce matter more than clustering."},
	{"id": "charged_sniper", "kind": "weapon_family", "function_tag": "combat.weapon.charged_sniper", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tactical"], "use_when": "Need slow charge, high damage, boss/elite focus.", "do_not_use_when": "Do not use when fire cadence must stay constant."},
	{"id": "weapon_level", "kind": "progression_system", "function_tag": "progression.weapon.level", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need repeatable per-weapon levelups that change behavior or stats.", "do_not_use_when": "Do not use when upgrades are purely cosmetic."},
	{"id": "weapon_evolution", "kind": "progression_system", "function_tag": "progression.weapon.evolution", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need weapon plus condition transforms into stronger weapon.", "do_not_use_when": "Do not use when upgrade should stay linear and reversible."},
	{"id": "weapon_fusion", "kind": "progression_system", "function_tag": "progression.weapon.fusion", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need two maxed weapons to merge into one composite weapon.", "do_not_use_when": "Do not use when each weapon must remain independently upgradeable."},
	{"id": "passive_stat", "kind": "progression_system", "function_tag": "progression.passive.stat", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need generic stat passives like damage, cooldown, range, HP, speed.", "do_not_use_when": "Do not use when the upgrade should be an active weapon family."},
	{"id": "skill_tree_branch", "kind": "progression_system", "function_tag": "progression.skill.tree_branch", "game_genre_tags": ["roguelike", "rpg", "shooter-survivor"], "use_when": "Need branching unlock path with persistent choice gates.", "do_not_use_when": "Do not use when selections are fully flat and independent."},
	{"id": "ability_trait_rank", "kind": "progression_system", "function_tag": "progression.ability.trait_rank", "game_genre_tags": ["roguelike", "rpg", "shooter-survivor"], "use_when": "Need trait ranks or ability tiers that gate stronger forms.", "do_not_use_when": "Do not use when the system is just raw stat stacking."},
	{"id": "status_effect", "kind": "combat_modifier", "function_tag": "combat.status.effect", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need burn, bleed, slow, root, freeze, mark, shock, or poison style effects.", "do_not_use_when": "Do not use when the upgrade should only modify projectile stats."},
	{"id": "on_hit_proc", "kind": "combat_modifier", "function_tag": "combat.proc.on_hit", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need trigger-on-hit logic like chain, splash, stun, refund, or shard spawn.", "do_not_use_when": "Do not use when a clean stat change is enough."},
	{"id": "defensive_layer", "kind": "combat_modifier", "function_tag": "combat.defense.layer", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need armor, shield, barrier, regen, or dodge style survivability.", "do_not_use_when": "Do not use when the upgrade should only raise offense."},
	{"id": "dash_mobility", "kind": "combat_modifier", "function_tag": "combat.mobility.dash", "game_genre_tags": ["arcade", "shooter-survivor", "roguelike", "rpg"], "use_when": "Need dash, blink, invuln step, or movement burst.", "do_not_use_when": "Do not use when movement is only passive walking speed."},
	{"id": "economy_drop", "kind": "progression_system", "function_tag": "progression.economy.drop", "game_genre_tags": ["roguelike", "rpg", "shooter-survivor"], "use_when": "Need coin, XP, reroll, reward, or loot economy modifiers.", "do_not_use_when": "Do not use when currency does not affect the build loop."},
	{"id": "curse_risk_reward", "kind": "progression_system", "function_tag": "progression.curse.risk_reward", "game_genre_tags": ["roguelike", "rpg"], "use_when": "Need stronger reward at the cost of enemy pressure or constraints.", "do_not_use_when": "Do not use when the build must stay low-risk and flat."},
	{"id": "enemy_counter", "kind": "combat_modifier", "function_tag": "combat.enemy.counter", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg", "tower-defense"], "use_when": "Need bonus damage or control versus elite, boss, armored, swarm, or ranged enemies.", "do_not_use_when": "Do not use when all enemies are intended to be treated identically."},
	{"id": "meta_progression", "kind": "progression_system", "function_tag": "progression.meta", "game_genre_tags": ["roguelike", "rpg", "shooter-survivor"], "use_when": "Need unlocks, account progression, permanent talent, or profile gains.", "do_not_use_when": "Do not use for per-run-only temporary boosts."},
	{"id": "build_rule_modifier", "kind": "progression_system", "function_tag": "progression.build.rule_modifier", "game_genre_tags": ["shooter-survivor", "roguelike", "rpg"], "use_when": "Need rules that alter how builds are offered, stacked, or capped.", "do_not_use_when": "Do not use when one stat adjustment is enough."},
	{"id": "summon_minion", "kind": "combat_modifier", "function_tag": "combat.summon.minion", "game_genre_tags": ["tower-defense", "shooter-survivor", "roguelike", "rpg"], "use_when": "Need allied minions, pets, summons, or helpers that act on their own.", "do_not_use_when": "Do not use when the effect is still just a projectile."}
]

var _entries: Array = []
var _entry_index: Dictionary = {}

func configure(entries: Array = []) -> void:
	_entries = _normalize_entries(entries if not entries.is_empty() else DEFAULT_SKILL_TAXONOMY_ENTRIES)
	_entry_index = {}
	for entry in _entries:
		_entry_index[String(entry.get("id", ""))] = Dictionary(entry).duplicate(true)

func entries(kind: String = "", genre_tag: String = "") -> Array:
	var resolved: Array = []
	for entry in _entries:
		if not kind.is_empty() and String(entry.get("kind", "")) != kind:
			continue
		if not genre_tag.is_empty() and not Array(entry.get("game_genre_tags", [])).has(genre_tag):
			continue
		resolved.append(Dictionary(entry).duplicate(true))
	return resolved

func entry(id: String) -> Dictionary:
	return Dictionary(_entry_index.get(id.strip_edges(), {})).duplicate(true)

func has_entry(id: String) -> bool:
	return _entry_index.has(id.strip_edges())

func ids_for_genre(genre_tag: String, kind: String = "") -> Array:
	var ids: Array = []
	for entry in entries(kind, genre_tag):
		ids.append(String(entry.get("id", "")))
	return ids

func validate_skill_definition(definition: Dictionary) -> Dictionary:
	var errors: Array = []
	var taxonomy_id := String(definition.get("taxonomy_id", "")).strip_edges()
	if taxonomy_id.is_empty():
		errors.append({"code": "missing_taxonomy_id"})
	elif not has_entry(taxonomy_id):
		errors.append({"code": "unknown_taxonomy_id"})
	var genre_tags := Array(definition.get("genre_tags", []))
	if genre_tags.is_empty():
		errors.append({"code": "missing_genre_tags"})
	elif not taxonomy_id.is_empty() and has_entry(taxonomy_id):
		var allowed := Array(entry(taxonomy_id).get("game_genre_tags", []))
		if allowed.is_empty():
			errors.append({"code": "missing_allowed_genre_tags"})
		elif not _shares_any_tag(allowed, genre_tags):
			errors.append({"code": "genre_tag_mismatch"})
	return {"valid": errors.is_empty(), "errors": errors}

func _normalize_entries(raw_entries: Array) -> Array:
	var normalized: Array = []
	var seen: Dictionary = {}
	for item in raw_entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item).duplicate(true)
		var id := String(entry.get("id", "")).strip_edges()
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		if not entry.has("kind"):
			entry["kind"] = "unknown"
		if not entry.has("game_genre_tags"):
			entry["game_genre_tags"] = []
		normalized.append(entry)
	return normalized

func _shares_any_tag(left: Array, right: Array) -> bool:
	for tag in left:
		if right.has(tag):
			return true
	return false
