extends Node3D

@export var fall_acceleration := 15.0
@export var trigger_delay := 0.0

var falling := false
var triggered := false
var fall_velocity := 0.0
var trigger_timer := 0.0

func _physics_process(delta):
	scale = scale.lerp(Vector3(1, 1, 1), delta * 10) # Animate scale

	if triggered and not falling:
		trigger_timer -= delta
		if trigger_timer <= 0.0:
			falling = true
	
	if falling:
		fall_velocity += fall_acceleration * delta
		position.y -= fall_velocity * delta
	else:
		fall_velocity = 0.0
	
	if position.y < -10:
		queue_free() # Remove platform if below threshold

func _on_body_entered(_body):
	if not falling and not triggered:
		Audio.play_event("fall") # Play sound
		scale = Vector3(1.25, 1, 1.25) # Animate scale
		triggered = true
		trigger_timer = trigger_delay
		if trigger_delay <= 0.0:
			falling = true

func apply_difficulty_profile(profile: Dictionary) -> void:
	fall_acceleration = float(profile.get("falling_platform_acceleration", fall_acceleration))
	trigger_delay = float(profile.get("falling_platform_trigger_delay", trigger_delay))
