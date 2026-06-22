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


func fill(color: Color) -> void:
	occupied = true
	occupied_color = color
	block.modulate = color
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
	preview.modulate = color
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
