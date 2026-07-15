class_name ShinokuteProjectileHitBudget
extends RefCounted

var _default_max_hits = 1
var _default_allow_rehit = false
var _default_rehit_cooldown = 0.0
var _projectiles = {}

func configure(settings = {}) -> void:
	_default_max_hits = int(max(0, int(Dictionary(settings).get("default_max_hits", _default_max_hits))))
	_default_allow_rehit = bool(Dictionary(settings).get("allow_rehit", _default_allow_rehit))
	_default_rehit_cooldown = float(max(0.0, float(Dictionary(settings).get("rehit_cooldown", _default_rehit_cooldown))))

func register_projectile(projectile_id, config = {}) -> Dictionary:
	var id = String(projectile_id).strip_edges()
	if id.is_empty():
		return {}
	var entry = {
		"projectile_id": id,
		"max_hits": int(max(0, int(Dictionary(config).get("max_hits", _default_max_hits)))),
		"remaining_hits": 0,
		"allow_rehit": bool(Dictionary(config).get("allow_rehit", _default_allow_rehit)),
		"rehit_cooldown": float(max(0.0, float(Dictionary(config).get("rehit_cooldown", _default_rehit_cooldown)))),
		"hit_ids": [],
		"last_hit_at": {},
		"elapsed": 0.0,
		"expired": false,
		"expire_reason": ""
	}
	entry["remaining_hits"] = int(entry["max_hits"])
	_projectiles[id] = entry.duplicate(true)
	return projectile_state(id)

func record_hit(projectile_id, target_id, elapsed = 0.0) -> Dictionary:
	var id = String(projectile_id).strip_edges()
	var target = String(target_id).strip_edges()
	if id.is_empty() or target.is_empty():
		return _blocked_report(id, target, "invalid_target")
	if not _projectiles.has(id):
		register_projectile(id)
	var state = Dictionary(_projectiles[id]).duplicate(true)
	state["elapsed"] = float(state.get("elapsed", 0.0)) + max(0.0, float(elapsed))
	if bool(state.get("expired", false)):
		return _blocked_report(id, target, String(state.get("expire_reason", "expired")))

	var hit_ids = Array(state.get("hit_ids", [])).duplicate(true)
	var last_hit_at = Dictionary(state.get("last_hit_at", {})).duplicate(true)
	var allow_rehit = bool(state.get("allow_rehit", false))
	if hit_ids.has(target):
		if not allow_rehit:
			return _blocked_report(id, target, "duplicate_target")
		var last_hit = float(last_hit_at.get(target, -1000000000.0))
		var cooldown = float(max(0.0, float(state.get("rehit_cooldown", 0.0))))
		if float(state.get("elapsed", 0.0)) - last_hit < cooldown:
			return _blocked_report(id, target, "rehit_cooldown")

	if not hit_ids.has(target):
		hit_ids.append(target)
	last_hit_at[target] = float(state.get("elapsed", 0.0))
	state["hit_ids"] = hit_ids
	state["last_hit_at"] = last_hit_at
	var remaining = int(max(0, int(state.get("remaining_hits", 0)) - 1))
	state["remaining_hits"] = remaining
	var report = {
		"projectile_id": id,
		"target_id": target,
		"accepted": true,
		"remaining_hits": remaining,
		"expired": false,
		"expire_reason": "",
		"reason": ""
	}
	if remaining <= 0:
		state["expired"] = true
		state["expire_reason"] = "hit_budget_depleted"
		report["expired"] = true
		report["expire_reason"] = "hit_budget_depleted"
	_projectiles[id] = state
	return report

func advance(delta) -> Array:
	var reports = []
	var step = max(0.0, float(delta))
	if step <= 0.0:
		return reports
	for projectile_id in _projectiles.keys():
		var state = Dictionary(_projectiles[projectile_id]).duplicate(true)
		state["elapsed"] = float(state.get("elapsed", 0.0)) + step
		_projectiles[projectile_id] = state
		reports.append({"projectile_id": String(projectile_id), "elapsed": float(state.get("elapsed", 0.0))})
	return reports

func expire(projectile_id, reason = "manual") -> Dictionary:
	var id = String(projectile_id).strip_edges()
	if id.is_empty():
		return {}
	if not _projectiles.has(id):
		register_projectile(id)
	var state = Dictionary(_projectiles[id]).duplicate(true)
	state["expired"] = true
	state["expire_reason"] = String(reason)
	_projectiles[id] = state
	return projectile_state(id)

func projectile_state(projectile_id) -> Dictionary:
	var id = String(projectile_id).strip_edges()
	if id.is_empty() or not _projectiles.has(id):
		return {}
	return Dictionary(_projectiles[id]).duplicate(true)

func snapshot() -> Dictionary:
	return {
		"default_max_hits": _default_max_hits,
		"allow_rehit": _default_allow_rehit,
		"rehit_cooldown": _default_rehit_cooldown,
		"projectiles": _projectiles.duplicate(true)
	}

func restore(snapshot_data) -> void:
	var data = Dictionary(snapshot_data)
	_default_max_hits = int(max(0, int(data.get("default_max_hits", _default_max_hits))))
	_default_allow_rehit = bool(data.get("allow_rehit", _default_allow_rehit))
	_default_rehit_cooldown = float(max(0.0, float(data.get("rehit_cooldown", _default_rehit_cooldown))))
	_projectiles = Dictionary(data.get("projectiles", {})).duplicate(true)

func _blocked_report(projectile_id, target_id, reason) -> Dictionary:
	var id = String(projectile_id).strip_edges()
	var state = Dictionary(_projectiles.get(id, {}))
	return {
		"projectile_id": id,
		"target_id": String(target_id).strip_edges(),
		"accepted": false,
		"remaining_hits": int(state.get("remaining_hits", 0)),
		"expired": bool(state.get("expired", false)),
		"expire_reason": String(state.get("expire_reason", "")),
		"reason": String(reason)
	}
