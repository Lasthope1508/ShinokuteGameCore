## Pure-logic helper that decides whether the player still has any legal move
## given the current grid occupancy and the shapes still available in the tray.
## Stateless: takes a snapshot of the grid as a 9x9 bool matrix.
class_name GridSolver extends RefCounted

const GRID_SIZE: int = 9


# True if any shape can be placed at any origin. Early-outs on the first fit.
static func any_placement_possible(occupied: Array, shapes: Array[PieceShape]) -> bool:
	for shape in shapes:
		if shape == null or shape.cells.is_empty():
			continue
		if _can_fit_anywhere(occupied, shape):
			return true
	return false


# True if the shape fits anywhere on the snapshot.
static func can_shape_fit(occupied: Array, shape: PieceShape) -> bool:
	if shape == null or shape.cells.is_empty():
		return false
	return _can_fit_anywhere(occupied, shape)


static func _can_fit_anywhere(occupied: Array, shape: PieceShape) -> bool:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if _can_fit_at(occupied, shape, Vector2i(x, y)):
				return true
	return false


static func _can_fit_at(occupied: Array, shape: PieceShape, origin: Vector2i) -> bool:
	for offset in shape.cells:
		var p := origin + offset
		if p.x < 0 or p.x >= GRID_SIZE or p.y < 0 or p.y >= GRID_SIZE:
			return false
		if occupied[p.y][p.x]:
			return false
	return true
