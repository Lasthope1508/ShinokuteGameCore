## A single visual block used by Piece (during drag) and by Cell (filled state).
## Kept as a separate scene so block styling lives in one place.
class_name Block extends Control

@onready var sprite: TextureRect = $Sprite


func set_color(color: Color) -> void:
	var color_index: int = ThemeManager.find_color_index(color)

	if ThemeManager.get_active_skin() == "fruits" and color_index != -1:
		var tex = ThemeManager.get_block_texture(color_index)
		if tex != null:
			sprite.texture = tex
			sprite.modulate = Color.WHITE
			return
	
	# Fallback/Brick skin uses the classic flat block modulated by its color
	sprite.texture = load("res://Assets/Sprites/block.png")
	sprite.modulate = color

