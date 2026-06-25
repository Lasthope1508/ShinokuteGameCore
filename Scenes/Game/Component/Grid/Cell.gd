## A single 1x1 cell of the grid. Knows whether it is occupied and renders
## the filled block / preview / clear highlight. All the visuals are children
## set up in Cell.tscn so the user can restyle them from the Inspector.
class_name Cell extends Control

# Pulse highlight applied when the cell is part of a projected clear.
const PULSE_SHADER := preload("res://Assets/Shaders/block_pulse.gdshader")
var OBSTACLE_TEXTURES = [
	load("res://Assets/Sprites/obstacle_block_1.png"),
	load("res://Assets/Sprites/obstacle_block_2.png"),
	load("res://Assets/Sprites/obstacle_block_3.png"),
	load("res://Assets/Sprites/obstacle_block_4.png"),
	load("res://Assets/Sprites/obstacle_block_5.png"),
	load("res://Assets/Sprites/obstacle_block_6.png"),
	load("res://Assets/Sprites/obstacle_block_7.png"),
	load("res://Assets/Sprites/obstacle_block_8.png"),
]

@onready var background: TextureRect = $Background
@onready var block: TextureRect = $Block
@onready var preview: TextureRect = $Preview
@onready var highlight: ColorRect = $Highlight

var cell_x: int = 0
var cell_y: int = 0
var occupied: bool = false
var occupied_color: Color = Color.WHITE
var _block_material: ShaderMaterial
var _preview_material: ShaderMaterial

var _orig_texture: Texture2D
var _orig_modulate: Color
var _has_saved_state: bool = false


func _ready() -> void:
	block.visible = false
	preview.visible = false
	highlight.visible = false
	
	_block_material = ShaderMaterial.new()
	_block_material.shader = PULSE_SHADER
	_block_material.set_shader_parameter("pulse_strength", 0.0)
	_block_material.set_shader_parameter("dissolve_cutoff", 0.0)
	_block_material.set_shader_parameter("glow_strength", 0.0)
	_block_material.set_shader_parameter("glow_flare", 1.0)
	block.material = _block_material

	_preview_material = ShaderMaterial.new()
	_preview_material.shader = PULSE_SHADER
	_preview_material.set_shader_parameter("pulse_strength", 0.0)
	_preview_material.set_shader_parameter("dissolve_cutoff", 0.0)
	_preview_material.set_shader_parameter("glow_strength", 0.0)
	_preview_material.set_shader_parameter("glow_flare", 1.0)
	preview.material = _preview_material

	# Listen to theme changes
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme()


func is_obstacle() -> bool:
	return occupied and abs(occupied_color.r - 0.4) < 0.01 and abs(occupied_color.g - 0.4) < 0.01 and abs(occupied_color.b - 0.4) < 0.01


func _update_theme() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		if is_obstacle():
			background.texture = preload("res://Assets/Sprites/obstacle_bg.png")
			# High opacity solid slate stone texture
			background.modulate = Color(0.9, 0.9, 0.9, 0.95)
		else:
			if active_theme.cell_empty_texture:
				background.texture = active_theme.cell_empty_texture
			else:
				background.texture = preload("res://Assets/Sprites/cell_empty.png")
			
			# If the theme's empty cell tint is opaque, default it to translucent
			var tint = active_theme.cell_empty_tint
			if tint.a > 0.1:
				tint.a = 0.02
			background.modulate = tint
	else:
		if is_obstacle():
			background.texture = preload("res://Assets/Sprites/obstacle_bg.png")
			background.modulate = Color(0.9, 0.9, 0.9, 0.95)
		else:
			background.texture = preload("res://Assets/Sprites/cell_empty.png")
			background.modulate = Color(1.0, 1.0, 1.0, 0.02)
	
	if occupied:
		_update_texture_for_color(block, occupied_color)
		if active_theme:
			block.modulate = block.modulate * active_theme.placed_block_modulate


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()


func _update_texture_for_color(rect: TextureRect, color: Color) -> void:
	# Detect and apply custom 9Router obstacle texture for starting blocks
	if abs(color.r - 0.4) < 0.01 and abs(color.g - 0.4) < 0.01 and abs(color.b - 0.4) < 0.01:
		var index := (cell_x + cell_y * 9) % OBSTACLE_TEXTURES.size()
		var obstacle_tex = OBSTACLE_TEXTURES[index]
		if obstacle_tex:
			rect.texture = obstacle_tex
		else:
			rect.texture = load("res://Assets/Sprites/block.png")
		rect.modulate = Color.WHITE
		return

	var color_index: int = ThemeManager.find_color_index(color)
	var tex = ThemeManager.get_block_texture(color_index) if color_index != -1 else null

	if tex != null:
		rect.texture = tex
		rect.modulate = Color.WHITE
		return
			
	# Fallback/Brick skin uses the classic flat block modulated by its color
	rect.texture = load("res://Assets/Sprites/block.png")
	rect.modulate = color


func fill(color: Color) -> void:
	occupied = true
	occupied_color = color
	_update_texture_for_color(block, color)
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		block.modulate = block.modulate * active_theme.placed_block_modulate

	else:
		block.modulate = block.modulate * Color(0.92, 0.92, 0.92, 1.0)
	block.visible = true
	block.scale = Vector2.ONE
	_update_theme()


## Elastic "bump → cracking tilt & shake" followed by dissolving from the center outwards.
func clear_with_animation(delay: float = 0.0) -> Tween:
	occupied = false
	preview.visible = false
	highlight.visible = false
	_update_theme()

	block.pivot_offset = block.size * 0.5
	var spin_dir: float = 1.0 if randf() > 0.5 else -1.0
	var spin_first: float = deg_to_rad(25.0) * spin_dir

	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)

	# Phase 1 — elastic bump + tilt.
	tw.tween_property(block, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(block, "rotation", spin_first, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Phase 1.5 — Cracking Jitter Shake (Tactile high-frequency vibration)
	var orig_pos = block.position
	tw.tween_property(block, "position", orig_pos + Vector2(-3, 2), 0.02)
	tw.tween_property(block, "position", orig_pos + Vector2(3, -2), 0.02)
	tw.tween_property(block, "position", orig_pos + Vector2(-2, -3), 0.02)
	tw.tween_property(block, "position", orig_pos + Vector2(2, 3), 0.02)
	tw.tween_property(block, "position", orig_pos + Vector2(-1, -1), 0.02)
	tw.tween_property(block, "position", orig_pos, 0.02)

	# Phase 2 — spawn magic particles & dissolve shader!
	tw.tween_callback(func() -> void:
		_spawn_magic_sparks()
	)
	tw.tween_property(_block_material, "shader_parameter/dissolve_cutoff", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Phase 3 — reset parameters & hide
	tw.tween_callback(func() -> void:
		block.visible = false
		block.scale = Vector2.ONE
		block.rotation = 0.0
		block.modulate.a = 1.0
		block.position = orig_pos
		_block_material.set_shader_parameter("dissolve_cutoff", 0.0)
		z_index = 0
	)
	
	# Add a small delay in the tween so grid matches timing.
	tw.tween_interval(0.1)
	return tw


func _spawn_magic_sparks() -> void:
	if not block.texture:
		return
		
	var effect_color = occupied_color
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("_spawn_cell_pop_vfx"):
		# Cell's position is local relative to the Grid node, which matches the cells_layer coordinate space.
		main_scene._spawn_cell_pop_vfx(position + size * 0.5, effect_color)
	else:
		var center_pos = size * 0.5
		var sparks := CPUParticles2D.new()
		sparks.texture = preload("res://addons/kenney_particle_pack/spark_01.png")
		sparks.amount = 6
		sparks.one_shot = true
		sparks.explosiveness = 0.9
		sparks.lifetime = 0.4
		sparks.spread = 180.0
		sparks.gravity = Vector2(0, 180)
		sparks.initial_velocity_min = 50.0
		sparks.initial_velocity_max = 110.0
		sparks.scale_amount_min = 0.02
		sparks.scale_amount_max = 0.05
		
		var spark_curve := Curve.new()
		spark_curve.add_point(Vector2(0.0, 1.0))
		spark_curve.add_point(Vector2(1.0, 0.0))
		sparks.scale_amount_curve = spark_curve
		
		var spark_gradient := Gradient.new()
		spark_gradient.set_color(0, Color.WHITE)
		spark_gradient.set_color(1, Color(1, 1, 1, 0))
		sparks.color_ramp = spark_gradient
		
		sparks.modulate = block.modulate * 1.3
		add_child(sparks)
		sparks.position = center_pos
		sparks.emitting = true
		sparks.finished.connect(sparks.queue_free)


# Shows a translucent ghost of the dragged piece on this cell.
func show_preview(color: Color) -> void:
	_update_texture_for_color(preview, color)
	preview.modulate = Color(0.5, 0.9, 0.5, 0.6)
	preview.visible = true


func clear_preview() -> void:
	preview.visible = false


# Highlights the cell to signal it would be cleared by the placement.
func show_clear_hint(color: Color) -> void:
	highlight.color = color
	highlight.visible = true


func clear_clear_hint() -> void:
	highlight.visible = false


# Enables the pulsing highlight on the filled block. Empty cells use the
# highlight ColorRect instead, so this is a no-op for them.
func start_pulse() -> void:
	if not occupied or _block_material == null:
		return
	_block_material.set_shader_parameter("pulse_strength", 1.0)


func stop_pulse() -> void:
	if _block_material:
		_block_material.set_shader_parameter("pulse_strength", 0.0)


func show_clear_aura(active_color: Color) -> void:
	# Enable glow on both materials
	_block_material.set_shader_parameter("glow_color", active_color)
	_block_material.set_shader_parameter("glow_strength", 1.0)
	
	_preview_material.set_shader_parameter("glow_color", active_color)
	_preview_material.set_shader_parameter("glow_strength", 1.0)
	
	# Initial flare-up Tween (lóe sáng)
	var tw := create_tween()
	tw.tween_property(_block_material, "shader_parameter/glow_flare", 2.5, 0.08)
	tw.parallel().tween_property(_preview_material, "shader_parameter/glow_flare", 2.5, 0.08)
	tw.tween_property(_block_material, "shader_parameter/glow_flare", 1.0, 0.17).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_preview_material, "shader_parameter/glow_flare", 1.0, 0.17).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Color-swapping active color if occupied
	if occupied:
		if not _has_saved_state:
			_orig_texture = block.texture
			_orig_modulate = block.modulate
			_has_saved_state = true
		_update_texture_for_color(block, active_color)
		var active_theme = ThemeManager.get_active_theme()
		if active_theme:
			block.modulate = block.modulate * active_theme.placed_block_modulate


func clear_clear_aura() -> void:
	_block_material.set_shader_parameter("glow_strength", 0.0)
	_block_material.set_shader_parameter("glow_flare", 1.0)
	
	_preview_material.set_shader_parameter("glow_strength", 0.0)
	_preview_material.set_shader_parameter("glow_flare", 1.0)
	
	# Restore block style if saved
	if _has_saved_state:
		block.texture = _orig_texture
		block.modulate = _orig_modulate
		_has_saved_state = false
