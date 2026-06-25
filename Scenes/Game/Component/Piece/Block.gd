## A single visual block used by Piece (during drag) and by Cell (filled state).
## Kept as a separate scene so block styling lives in one place.
class_name Block extends Control

const PULSE_SHADER := preload("res://Assets/Shaders/block_pulse.gdshader")

@onready var sprite: TextureRect = $Sprite

var _material: ShaderMaterial
var _pending_color: Color
var _has_pending_color: bool = false


func _ready() -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = PULSE_SHADER
	sprite.material = _material
	if _has_pending_color:
		_apply_color_and_shader(_pending_color)


func set_color(color: Color) -> void:
	_pending_color = color
	_has_pending_color = true
	
	if sprite == null:
		return
		
	_apply_color_and_shader(color)


func _apply_color_and_shader(color: Color) -> void:
	var color_index: int = ThemeManager.find_color_index(color)
	var tex = ThemeManager.get_block_texture(color_index) if color_index != -1 else null

	if tex != null:
		sprite.texture = tex
		sprite.modulate = Color.WHITE
	else:
		# Fallback/Brick skin uses the classic flat block modulated by its color
		sprite.texture = load("res://Assets/Sprites/block.png")
		sprite.modulate = color
		
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = PULSE_SHADER
		sprite.material = _material
		
	var is_obs = abs(color.r - 0.4) < 0.01 and abs(color.g - 0.4) < 0.01 and abs(color.b - 0.4) < 0.01
	_material.set_shader_parameter("is_ice_element", not is_obs)
	_material.set_shader_parameter("glow_color", color)
	_material.set_shader_parameter("glow_strength", 1.0)
	_material.set_shader_parameter("glow_flare", 1.3)
	_material.set_shader_parameter("shrink_factor", 1.2)
	_material.set_shader_parameter("glow_spread", 0.08)


func set_connections(left: bool, right: bool, up: bool, down: bool) -> void:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = PULSE_SHADER
		if sprite:
			sprite.material = _material
			
	_material.set_shader_parameter("is_ice_element", true)
	_material.set_shader_parameter("conn_left", left)
	_material.set_shader_parameter("conn_right", right)
	_material.set_shader_parameter("conn_up", up)
	_material.set_shader_parameter("conn_down", down)




