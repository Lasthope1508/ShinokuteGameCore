class_name ShinokuteSteering2D
extends RefCounted

func seek(position: Vector2, target: Vector2) -> Vector2:
	var delta := target - position
	if delta.length() <= 0.0001:
		return Vector2.ZERO
	return delta.normalized()

func arrive(position: Vector2, target: Vector2, slow_radius: float = 0.0) -> Vector2:
	var delta := target - position
	var distance := delta.length()
	if distance <= 0.0001:
		return Vector2.ZERO
	if slow_radius <= 0.0 or distance >= slow_radius:
		return delta.normalized()
	return delta.normalized() * clamp(distance / slow_radius, 0.0, 1.0)

func separation(position: Vector2, neighbors: Array, radius: float) -> Vector2:
	if radius <= 0.0:
		return Vector2.ZERO
	var force := Vector2.ZERO
	for raw in neighbors:
		if not (raw is Vector2):
			continue
		var neighbor: Vector2 = raw
		var offset: Vector2 = position - neighbor
		var distance: float = offset.length()
		if distance <= 0.0001 or distance >= radius:
			continue
		force += offset.normalized() * ((radius - distance) / radius)
	return force.limit_length(1.0)
