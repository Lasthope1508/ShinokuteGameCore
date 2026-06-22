## Global palette and visual constants for the template. A single instance is
## referenced by Game/HUD/Piece nodes so the user can recolor the whole project
## from the Inspector by editing one .tres asset.
class_name ThemeConfig extends Resource

# Palette used by PieceTray when picking a color for a new piece.
@export var piece_colors: Array[Color] = [
	Color("#7c3aed"), # violet
	Color("#ef4444"), # red
	Color("#22c55e"), # green
	Color("#3b82f6"), # blue
	Color("#f59e0b"), # amber
	Color("#ec4899"), # pink
	Color("#06b6d4"), # cyan
	Color("#eab308"), # yellow
]

# Tints for dark/light quadrant backgrounds (alternated per 3x3 block).
@export var quadrant_dark_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var quadrant_light_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var cell_empty_tint: Color = Color(1.0, 1.0, 1.0, 0.10)

# Overlay shown for the projected piece preview while dragging.
@export var preview_valid_tint: Color = Color(1.0, 1.0, 1.0, 0.45)

# Highlight for rows / columns / quadrants that would be cleared by a placement.
@export var preview_clear_highlight: Color = Color(1.0, 0.95, 0.4, 0.55)
