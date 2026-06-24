## A single 1x1 cell of the grid. Knows whether it is occupied and renders
## the filled block / preview / clear highlight. All the visuals are children
## set up in Cell.tscn so the user can restyle them from the Inspector.
class_name Cell extends Control

# Pulse highlight applied when the cell is part of a projected clear.
const PULSE_SHADER := preload("res://Assets/Shaders/block_pulse.gdshader")

@onready var background: TextureRect = $Background
@onready var block: TextureRect = $Block
@onready var preview: TextureRect = $Preview
@onready var highlight: ColorRect = $Highlight

var occupied: bool = false
var occupied_color: Color = Color.WHITE
var _block_material: ShaderMaterial


func _ready() -> void:
	block.visible = false
	preview.visible = false
	highlight.visible = false
	# Per-cell ShaderMaterial so pulses can be toggled independently. The
	# underlying Shader resource is shared.
	_block_material = ShaderMaterial.new()
	_block_material.shader = PULSE_SHADER
	_block_material.set_shader_parameter("pulse_strength", 0.0)
	block.material = _block_material

	# Listen to theme changes
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme()


func _update_theme() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		if active_theme.cell_empty_texture != null:
			background.texture = active_theme.cell_empty_texture
		else:
			background.texture = load("res://Assets/Sprites/cell_empty.png")
		background.modulate = active_theme.cell_empty_tint
	else:
		background.texture = load("res://Assets/Sprites/cell_empty.png")
		background.modulate = Color(0.2, 0.15, 0.1, 0.5)
	
	if occupied:
		_update_texture_for_color(block, occupied_color)
		if ThemeManager.get_active_skin() == "fruits" and active_theme:
			block.modulate = block.modulate * active_theme.placed_block_modulate
		else:
			block.modulate = block.modulate * Color(1.0, 1.0, 1.0, 1.0)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()


func _update_texture_for_color(rect: TextureRect, color: Color) -> void:
	var color_index: int = ThemeManager.find_color_index(color)

	if ThemeManager.get_active_skin() == "fruits" and color_index != -1:
		var tex = ThemeManager.get_block_texture(color_index)
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


# Elastic "bump → spin → shrink" clear, returning the tween so callers can await.
func clear_with_animation(delay: float = 0.0) -> Tween:
	occupied = false
	preview.visible = false
	highlight.visible = false

	block.pivot_offset = block.size * 0.5
	# Random rotation direction so the cleared field feels less mechanical.
	var spin_dir: float = 1.0 if randf() > 0.5 else -1.0
	var spin_first: float = deg_to_rad(28.0) * spin_dir
	var spin_final: float = deg_to_rad(70.0) * spin_dir

	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)

	# Phase 1 — elastic bump + tilt.
	tw.tween_property(block, "scale", Vector2(1.35, 1.35), 0.18) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(block, "rotation", spin_first, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Phase 2 — monotonic shrink + spin + fade.
	tw.chain().tween_property(block, "scale", Vector2.ZERO, 0.22) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(block, "rotation", spin_final, 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(block, "modulate:a", 0.0, 0.22)

	tw.tween_callback(func() -> void:
		block.visible = false
		block.scale = Vector2.ONE
		block.rotation = 0.0
		block.modulate.a = 1.0
		# Restore draw order (Grid raised it for the cascade).
		z_index = 0
	)
	return tw


# Shows a translucent ghost of the dragged piece on this cell.
func show_preview(color: Color) -> void:
	_update_texture_for_color(preview, color)
	var active_theme = ThemeManager.get_active_theme()
	var alpha = active_theme.preview_valid_tint.a if active_theme else 0.45
	preview.modulate.a = alpha
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
