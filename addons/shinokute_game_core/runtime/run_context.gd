class_name ShinokuteRunContext
extends RefCounted

var _run_id := ""
var _seed := 0
var _modifiers: Array[String] = []
var _data: Dictionary = {}

func configure(run_id: String, seed: int = 0, modifiers: Array = [], data: Dictionary = {}) -> void:
	_run_id = run_id
	_seed = int(seed)
	_modifiers = []
	for modifier in modifiers:
		var id := String(modifier).strip_edges()
		if id.is_empty() or _modifiers.has(id):
			continue
		_modifiers.append(id)
	_modifiers.sort()
	_data = data.duplicate(true)

func run_id() -> String:
	return _run_id

func seed() -> int:
	return _seed

func modifiers() -> Array[String]:
	return _modifiers.duplicate()

func has_modifier(id: String) -> bool:
	return _modifiers.has(id)

func derive_seed(scope: String, index: int = 0) -> int:
	var basis := "%s|%s|%s" % [_seed, scope, index]
	return int((_stable_hash(basis) + abs(_seed)) % 2147483647)

func roll(scope: String, index: int = 0) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = derive_seed(scope, index)
	return rng.randf()

func to_dictionary() -> Dictionary:
	var packed := _data.duplicate(true)
	packed["run_id"] = _run_id
	packed["seed"] = _seed
	packed["modifiers"] = _modifiers.duplicate()
	return packed

func _stable_hash(text: String) -> int:
	var value := 2166136261
	for i in range(text.length()):
		value = int(((value ^ text.unicode_at(i)) * 16777619) % 2147483647)
	return abs(value)
