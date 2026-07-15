class_name ShinokuteRngStream
extends RefCounted

const _MODULUS := 2147483648
const _MULTIPLIER := 1103515245
const _INCREMENT := 12345

var _base_seed := 1
var _states: Dictionary = {}

func configure(seed_value: int = 1, initial_states: Dictionary = {}) -> void:
	_base_seed = _normalized_seed(seed_value)
	_states = {}
	for key in initial_states.keys():
		_states[String(key)] = _normalized_seed(int(initial_states[key]))

func next_float(stream: String = "default") -> float:
	var state := _next_state(stream)
	return float(state) / float(_MODULUS)

func next_int(stream: String = "default", max_exclusive: int = 1) -> int:
	var limit: int = int(max(1, max_exclusive))
	return int(floor(next_float(stream) * float(limit)))

func next_range_int(stream: String, min_value: int, max_value: int) -> int:
	var low: int = min(min_value, max_value)
	var high: int = max(min_value, max_value)
	return low + next_int(stream, high - low + 1)

func next_range_float(stream: String, min_value: float, max_value: float) -> float:
	var low: float = min(min_value, max_value)
	var high: float = max(min_value, max_value)
	return low + (high - low) * next_float(stream)

func snapshot() -> Dictionary:
	return {
		"base_seed": _base_seed,
		"states": _states.duplicate(true)
	}

func restore(snapshot_data: Dictionary) -> void:
	_base_seed = _normalized_seed(int(snapshot_data.get("base_seed", _base_seed)))
	_states = {}
	for key in Dictionary(snapshot_data.get("states", {})).keys():
		_states[String(key)] = _normalized_seed(int(Dictionary(snapshot_data.get("states", {}))[key]))

func stream_state(stream: String = "default") -> int:
	_ensure_stream(stream)
	return int(_states.get(stream, _base_seed))

func _next_state(stream: String) -> int:
	_ensure_stream(stream)
	var state: int = int(_states.get(stream, _base_seed))
	state = int((state * _MULTIPLIER + _INCREMENT) % _MODULUS)
	_states[stream] = state
	return state

func _ensure_stream(stream: String) -> void:
	var key := stream
	if key.is_empty():
		key = "default"
	if _states.has(key):
		return
	_states[key] = _normalized_seed(_base_seed + _stable_string_hash(key))

func _normalized_seed(value: int) -> int:
	var normalized: int = int(value % _MODULUS)
	if normalized <= 0:
		normalized += _MODULUS - 1
	return normalized

func _stable_string_hash(value: String) -> int:
	var hash := 2166136261
	for index in range(value.length()):
		hash = int((hash ^ value.unicode_at(index)) * 16777619)
		hash = int(hash % _MODULUS)
	return hash
