extends CPUParticles2D

func _ready() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme and ThemeManager.get_active_skin() == "fruits":
		amount = active_theme.particles_amount
		spread = active_theme.particles_spread
		gravity = active_theme.particles_gravity
		initial_velocity_min = active_theme.particles_initial_velocity_min
		initial_velocity_max = active_theme.particles_initial_velocity_max
		scale_amount_min = active_theme.particles_scale_min
		scale_amount_max = active_theme.particles_scale_max
		
		if active_theme.particles_texture != null:
			texture = active_theme.particles_texture
	else:
		# Classic/Brick skin particle settings
		amount = 24
		spread = 180.0
		gravity = Vector2(0, 200)
		initial_velocity_min = 100.0
		initial_velocity_max = 220.0
		scale_amount_min = 2.0
		scale_amount_max = 6.0
		texture = null # render as square blocks
	
	emitting = true
	# Wait for lifetime plus a safety margin, then auto-delete
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()

func set_particle_color(p_color: Color) -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme and ThemeManager.get_active_skin() == "fruits":
		if active_theme.particles_use_cell_color:
			var grad = Gradient.new()
			grad.colors = PackedColorArray([
				p_color,
				Color(p_color.r, p_color.g, p_color.b, 0.7),
				Color(p_color.r, p_color.g, p_color.b, 0.0)
			])
			grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
			color_ramp = grad
		elif active_theme.particles_gradient != null:
			color_ramp = active_theme.particles_gradient
	else:
		# For brick skin, always color particles based on cell color fading to alpha 0
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			p_color,
			Color(p_color.r, p_color.g, p_color.b, 0.7),
			Color(p_color.r, p_color.g, p_color.b, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		color_ramp = grad

