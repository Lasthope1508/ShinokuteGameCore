class_name ShinokuteInputVectorFilter2D
extends RefCounted

func filter(raw: Vector2, profile: Dictionary = {}) -> Vector2:
	var deadzone := float(profile.get("deadzone", 0.0))
	var analog_curve := float(max(0.01, float(profile.get("analog_curve", 1.0))))
	var normalize_diagonal := bool(profile.get("normalize_diagonal", true))
	var length := raw.length()
	if length <= deadzone:
		return Vector2.ZERO
	var direction := raw / length
	var scaled_length := clamp((length - deadzone) / max(0.0001, 1.0 - deadzone), 0.0, 1.0)
	scaled_length = pow(scaled_length, analog_curve)
	var result: Vector2 = direction * scaled_length
	if normalize_diagonal and result.length() > 1.0:
		return result.normalized()
	return result
