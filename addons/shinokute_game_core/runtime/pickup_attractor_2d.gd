class_name ShinokutePickupAttractor2D
extends RefCounted

func step(position: Vector2, target: Vector2, speed: float, delta: float, collect_radius: float) -> Dictionary:
	var distance: float = position.distance_to(target)
	if distance <= collect_radius:
		return {"position": target, "collected": true}
	var max_step: float = max(0.0, speed) * max(0.0, delta)
	var next_position: Vector2 = position
	if distance > 0.0:
		next_position = position + (target - position).normalized() * min(max_step, distance)
	return {"position": next_position, "collected": next_position.distance_to(target) <= collect_radius}
