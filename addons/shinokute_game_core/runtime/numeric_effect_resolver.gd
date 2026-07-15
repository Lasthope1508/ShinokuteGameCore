class_name ShinokuteNumericEffectResolver
extends RefCounted

func resolve(config: Dictionary) -> Dictionary:
	var base_amount := float(config.get("amount", config.get("base", 0.0)))
	var additive := float(config.get("add", 0.0))
	var multiplier := float(config.get("multiplier", 1.0))
	var resistance := clamp(float(config.get("resistance", 0.0)), 0.0, 1.0)
	var amount := (base_amount + additive) * multiplier
	amount *= 1.0 - resistance
	var critical := _is_critical(config)
	if critical:
		amount *= float(config.get("crit_multiplier", 2.0))
	var minimum := float(config.get("min", 0.0))
	var maximum := float(config.get("max", INF))
	amount = clamp(amount, minimum, maximum)
	amount = _rounded(amount, String(config.get("round", "nearest")))
	return {
		"amount": amount,
		"base_amount": base_amount,
		"add": additive,
		"multiplier": multiplier,
		"resistance": resistance,
		"critical": critical,
		"tags": Array(config.get("tags", [])).duplicate(true),
		"payload": Dictionary(config.get("payload", {})).duplicate(true)
	}

func _is_critical(config: Dictionary) -> bool:
	var chance := clamp(float(config.get("crit_chance", 0.0)), 0.0, 1.0)
	if chance <= 0.0:
		return false
	var roll := float(config.get("roll", randf()))
	return clamp(roll, 0.0, 0.999999) < chance

func _rounded(value: float, mode: String):
	match mode:
		"floor":
			return int(floor(value))
		"ceil":
			return int(ceil(value))
		"none":
			return value
	return int(round(value))
