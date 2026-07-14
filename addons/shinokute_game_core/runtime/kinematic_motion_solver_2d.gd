class_name ShinokuteKinematicMotionSolver2D
extends RefCounted

func solve_velocity(current_velocity: Vector2, desired_direction: Vector2, delta: float, profile: Dictionary) -> Vector2:
	var max_speed := float(max(0.0, float(profile.get("max_speed", 0.0))))
	var acceleration := float(max(0.0, float(profile.get("acceleration", max_speed))))
	var deceleration := float(max(0.0, float(profile.get("deceleration", acceleration))))
	var turn_acceleration := float(max(0.0, float(profile.get("turn_acceleration", acceleration))))
	var desired := desired_direction
	if desired.length() > 1.0:
		desired = desired.normalized()
	if desired.length() <= 0.0001:
		return current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
	var target := desired.normalized() * max_speed
	var accel := acceleration
	if current_velocity.length() > 0.0001 and current_velocity.normalized().dot(target.normalized()) < 0.25:
		accel = turn_acceleration
	return current_velocity.move_toward(target, accel * delta).limit_length(max_speed)
