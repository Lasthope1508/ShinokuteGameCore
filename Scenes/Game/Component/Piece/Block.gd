## A single visual block used by Piece (during drag) and by Cell (filled state).
## Kept as a separate scene so block styling lives in one place.
class_name Block extends Control

@onready var sprite: TextureRect = $Sprite


func set_color(color: Color) -> void:
	sprite.modulate = color
