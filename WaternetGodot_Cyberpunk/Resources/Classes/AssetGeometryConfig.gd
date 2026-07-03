extends Resource
class_name AssetGeometryConfig

@export var asset_key: String = ""
@export var frame_size: Vector2 = Vector2(512.0, 512.0)
@export var draw_origin: Vector2 = Vector2(256.0, 256.0)
@export var center: Vector2 = Vector2(256.0, 256.0)
@export var content_rect: Rect2 = Rect2(0.0, 0.0, 512.0, 512.0)
@export var energy_rect: Rect2 = Rect2(0.0, 0.0, 512.0, 512.0)
@export var route_junction: Vector2 = Vector2(256.0, 256.0)
@export var core_center: Vector2 = Vector2(256.0, 256.0)
@export var north_port: Vector2 = Vector2(256.0, 0.0)
@export var east_port: Vector2 = Vector2(512.0, 256.0)
@export var south_port: Vector2 = Vector2(256.0, 512.0)
@export var west_port: Vector2 = Vector2(0.0, 256.0)

func get_frame_scale(cell_size: float) -> Vector2:
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return Vector2.ONE
	return Vector2(cell_size / frame_size.x, cell_size / frame_size.y)

func get_draw_rect() -> Rect2:
	return Rect2(-draw_origin, frame_size)

func get_scaled_content_rect(cell_size: float) -> Rect2:
	return _get_scaled_rect(content_rect, cell_size)

func get_scaled_energy_rect(cell_size: float) -> Rect2:
	return _get_scaled_rect(energy_rect, cell_size)

func get_route_junction_offset(cell_size: float) -> Vector2:
	var scale := get_frame_scale(cell_size)
	return (route_junction - draw_origin) * scale

func get_core_center_offset(cell_size: float) -> Vector2:
	var scale := get_frame_scale(cell_size)
	return (core_center - draw_origin) * scale

func get_rotated_port_offset(direction_index: int, rotation_index: int, cell_size: float) -> Vector2:
	return get_port_offset(direction_index, cell_size).rotated(rotation_index * PI / 2.0)

func _get_scaled_rect(source_rect: Rect2, cell_size: float) -> Rect2:
	var scale := get_frame_scale(cell_size)
	return Rect2((source_rect.position - draw_origin) * scale, source_rect.size * scale)

func get_port_offset(direction_index: int, cell_size: float) -> Vector2:
	var port := center
	match direction_index:
		0:
			port = north_port
		1:
			port = east_port
		2:
			port = south_port
		3:
			port = west_port
	var scale := get_frame_scale(cell_size)
	return (port - draw_origin) * scale
