extends RefCounted
class_name VfxAnchor

const PORT_NAMES := ["north", "east", "south", "west"]

static func get_anchor_points(geometry: Resource, grid_offset: Vector2, cell_size: float, cell_pos: Vector2i) -> Dictionary:
	var center := get_tile_center(grid_offset, cell_size, cell_pos)
	var anchors := {
		"center": center,
		"energy_center": center,
		"route_junction": center
	}
	if geometry == null:
		return anchors

	for direction_index in range(4):
		anchors[PORT_NAMES[direction_index]] = center + geometry.get_port_offset(direction_index, cell_size)

	if geometry.has_method("get_scaled_energy_rect"):
		var energy_rect: Rect2 = geometry.get_scaled_energy_rect(cell_size)
		anchors["energy_center"] = center + energy_rect.position + energy_rect.size / 2.0
	if geometry.has_method("get_route_junction_offset"):
		anchors["route_junction"] = center + geometry.get_route_junction_offset(cell_size)

	return anchors

static func get_tile_center(grid_offset: Vector2, cell_size: float, cell_pos: Vector2i) -> Vector2:
	return grid_offset + Vector2(cell_pos) * cell_size + Vector2(cell_size / 2.0, cell_size / 2.0)
