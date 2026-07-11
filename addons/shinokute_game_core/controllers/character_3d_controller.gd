class_name ShinokuteCharacter3DController
extends CharacterBody3D

signal coin_collected
signal fell_out_of_bounds

@export_subgroup("Components")
@export var view: Node3D

@export_subgroup("Properties")
@export var movement_speed = 250
@export var jump_strength = 7
@export var shift_lock_turn_speed := 180.0
@export var fall_reset_y := -10.0
@export_enum("emit_only") var fall_policy := "emit_only"
@export var input_router_path: NodePath = NodePath("")

var movement_velocity: Vector3
var local_movement_input := Vector3.ZERO
var rotation_direction: float
var gravity = 0

var previously_floored = false

var jump_single = true
var jump_double = true

var coins = 0
var fall_reported := false
var _shift_lock_look_control_frames := 0

@onready var particles_trail = $ParticlesTrail
@onready var sound_footsteps = $SoundFootsteps
@onready var model = $Character
@onready var animation = $Character/AnimationPlayer
@onready var input_router: Node = get_node_or_null(input_router_path)

func _physics_process(delta):
	handle_controls(delta)
	handle_gravity(delta)

	handle_effects(delta)

	var applied_velocity: Vector3

	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity

	velocity = applied_velocity
	move_and_slide()

	if _should_update_facing_from_movement():
		rotation_direction = Vector2(velocity.z, velocity.x).angle()

	if _is_shift_lock_enabled() and _should_update_facing_from_movement():
		rotation.y = rotation_direction
	elif not _is_shift_lock_enabled():
		rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)

	if position.y < fall_reset_y and not fall_reported:
		_handle_fall_out_of_bounds()

	model.scale = model.scale.lerp(Vector3(1, 1, 1), delta * 10)

	if is_on_floor() and gravity > 2 and !previously_floored:
		model.scale = Vector3(1.25, 0.75, 1.25)
		Audio.play_event("land")

	previously_floored = is_on_floor()

func handle_effects(delta):
	particles_trail.emitting = false
	sound_footsteps.stream_paused = true
	var sfx_enabled := not Audio.has_method("is_sfx_enabled") or Audio.is_sfx_enabled()

	if is_on_floor():
		var horizontal_velocity = Vector2(velocity.x, velocity.z)
		var speed_factor = horizontal_velocity.length() / movement_speed / delta
		if speed_factor > 0.05:
			if animation.current_animation != "walk":
				animation.play("walk", 0.1)

			if speed_factor > 0.3 and sfx_enabled:
				sound_footsteps.stream_paused = false
				sound_footsteps.pitch_scale = speed_factor

			if speed_factor > 0.75:
				particles_trail.emitting = true

		elif animation.current_animation != "idle":
			animation.play("idle", 0.1)

		if animation.current_animation == "walk":
			animation.speed_scale = speed_factor
		else:
			animation.speed_scale = 1.0

	elif animation.current_animation != "jump":
		animation.play("jump", 0.1)

func handle_controls(delta):
	var input := Vector3.ZERO

	var routed_input := _get_move_vector()
	input.x = routed_input.x
	input.z = routed_input.y
	local_movement_input = input

	if _is_shift_lock_enabled():
		if absf(input.x) > 0.0 and not _has_shift_lock_look_control():
			rotation_direction = rotation.y - deg_to_rad(input.x * shift_lock_turn_speed * delta)
			rotation.y = rotation_direction
		input = Vector3(0.0, 0.0, -input.z).rotated(Vector3.UP, rotation.y)
		if _shift_lock_look_control_frames > 0:
			_shift_lock_look_control_frames -= 1
	else:
		input = input.rotated(Vector3.UP, view.rotation.y)

	if input.length() > 1:
		input = input.normalized()

	movement_velocity = input * movement_speed * delta

	if _is_jump_just_pressed():
		if jump_single or jump_double:
			jump()

func handle_gravity(delta):
	gravity += 25 * delta

	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0
		fall_reported = false

func jump():
	Audio.play_event("jump")

	gravity = -jump_strength

	model.scale = Vector3(0.5, 1.5, 0.5)

	if jump_single:
		jump_single = false;
		jump_double = true;
	else:
		jump_double = false;

func collect_coin():
	coins += 1

	coin_collected.emit(coins)

func apply_progression_profile(profile: Dictionary) -> void:
	fall_reset_y = float(profile.get("fall_reset_y", fall_reset_y))

func reset_for_level(spawn_transform: Transform3D) -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
	local_movement_input = Vector3.ZERO
	rotation_direction = rotation.y
	gravity = 0
	previously_floored = false
	jump_single = true
	jump_double = true
	fall_reported = false
	coins = 0
	coin_collected.emit(coins)
	if model != null:
		model.scale = Vector3.ONE
	if particles_trail != null:
		particles_trail.emitting = false
	if sound_footsteps != null:
		sound_footsteps.stream_paused = true
	if animation != null and animation.has_animation("idle"):
		animation.play("idle", 0.1)

func apply_shift_lock_look_delta_degrees(delta_yaw_degrees: float) -> void:
	if not _is_shift_lock_enabled():
		return
	_shift_lock_look_control_frames = 2
	rotation_direction = rotation.y + deg_to_rad(delta_yaw_degrees)
	rotation.y = rotation_direction

func _get_move_vector() -> Vector2:
	if input_router != null and input_router.has_method("get_move_vector"):
		return input_router.get_move_vector()
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	).limit_length(1.0)

func _is_jump_just_pressed() -> bool:
	if input_router != null and input_router.has_method("consume_jump_pressed"):
		return input_router.consume_jump_pressed()
	return Input.is_action_just_pressed("jump")

func _is_shift_lock_enabled() -> bool:
	return view != null and "shift_lock_enabled" in view and bool(view.shift_lock_enabled)

func _is_shift_lock_backpedaling() -> bool:
	return _is_shift_lock_enabled() and local_movement_input.z > 0.0

func _has_shift_lock_look_control() -> bool:
	if input_router != null and input_router.has_method("has_pending_look_delta") and input_router.has_pending_look_delta():
		return true
	return _shift_lock_look_control_frames > 0

func _should_update_facing_from_movement() -> bool:
	var has_motion := Vector2(velocity.z, velocity.x).length() > 0
	return has_motion and not _is_shift_lock_enabled()

func _handle_fall_out_of_bounds() -> void:
	fall_reported = true
	fell_out_of_bounds.emit()
