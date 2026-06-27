## Defines the shape of a draggable piece by listing the local cell offsets
## that make up the piece. Used both to render the piece (one Block per cell)
## and to test placement on the Grid.
class_name PieceShape extends Resource

# Local cell offsets composing the piece, e.g. an "L": [(0,0), (0,1), (0,2), (1,2)].
@export var cells: Array[Vector2i] = []

@export var display_name: String = ""

# Random-pick weight used by PieceLibrary. Higher = more frequent.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0

# Difficulty tier: 1 = Easy, 2 = Medium, 3 = Hard, 4 = Extreme
@export var tier: int = 1


# Returns the bounding-box size in cells.
func get_size() -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var min_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_x: int = cells[0].x
	var max_y: int = cells[0].y
	for c in cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
		max_x = max(max_x, c.x)
		max_y = max(max_y, c.y)
	return Vector2i(max_x - min_x + 1, max_y - min_y + 1)


# Returns cells normalized so the top-left bounding corner is (0,0).
func get_normalized_cells() -> Array[Vector2i]:
	if cells.is_empty():
		return []
	var min_x: int = cells[0].x
	var min_y: int = cells[0].y
	for c in cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	return out
