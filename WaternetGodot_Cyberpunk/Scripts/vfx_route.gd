extends RefCounted
class_name VfxRoute

const PORT_NAMES := ["north", "east", "south", "west"]

static func get_route_points(geometry: Resource, input_dir: int, output_dir: int, anchors: Dictionary) -> Array:
	var junction: Vector2 = anchors.get("route_junction", anchors.get("center", Vector2.ZERO))
	var output_point: Vector2 = _get_port_point(output_dir, anchors, junction)
	if input_dir < 0:
		return [junction, output_point]
	var input_point: Vector2 = _get_port_point(input_dir, anchors, junction)
	if _is_straight_route(geometry, input_dir, output_dir):
		return [input_point, output_point]
	return [input_point, junction, output_point]

static func _get_port_point(direction: int, anchors: Dictionary, fallback: Vector2) -> Vector2:
	if direction < 0 or direction >= PORT_NAMES.size():
		return fallback
	return anchors.get(PORT_NAMES[direction], fallback)

static func _is_straight_route(geometry: Resource, input_dir: int, output_dir: int) -> bool:
	if input_dir < 0 or output_dir < 0:
		return false
	if (input_dir + 2) % 4 != output_dir:
		return false
	var asset_key: String = String(geometry.get("asset_key")) if geometry != null else ""
	return asset_key == "I" or asset_key == "T" or asset_key == "X"
