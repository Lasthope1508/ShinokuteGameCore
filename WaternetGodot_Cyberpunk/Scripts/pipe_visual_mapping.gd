extends RefCounted
class_name PipeVisualMapping

const L_TEXTURE_ROTATION_OFFSET := 0
const L_VISUAL_SCALE := 1.0

static func get_local_flow_mask(global_flow_mask: int, rotation_index: int) -> int:
	var local_flow_mask := 0
	for i in range(4):
		if global_flow_mask & (1 << i):
			var i_local := (i - rotation_index + 4) % 4
			local_flow_mask |= (1 << i_local)
	return local_flow_mask

static func get_rotation_index_for_ports(ports: Array) -> int:
	var active := []
	for i in range(min(ports.size(), 4)):
		if ports[i]:
			active.append(i)

	var count := active.size()
	if count == 1:
		return active[0]
	if count == 2:
		var diff = abs(active[0] - active[1])
		if diff == 2:
			return 1 if active[0] == 1 else 0
		if active[0] == 0 and active[1] == 1:
			return 0
		if active[0] == 1 and active[1] == 2:
			return 1
		if active[0] == 2 and active[1] == 3:
			return 2
		if active[0] == 0 and active[1] == 3:
			return 3
	if count == 3:
		for i in range(4):
			if not ports[i]:
				return (i - 3 + 4) % 4
	return 0

static func get_tile_offset(_pipe_type: String, _active_count: int) -> Vector2:
	return Vector2.ZERO

static func get_l_visual_rotation_index(logical_rotation_index: int) -> int:
	return (logical_rotation_index + L_TEXTURE_ROTATION_OFFSET) % 4

static func get_l_local_flow_mask(global_flow_mask: int, logical_rotation_index: int) -> int:
	var visual_rotation_index := get_l_visual_rotation_index(logical_rotation_index)
	return get_local_flow_mask(global_flow_mask, visual_rotation_index)

static func get_l_visual_scale() -> float:
	return L_VISUAL_SCALE

static func get_l_anchor_offset(ports: Array, cell_size: float, visual_scale: float = L_VISUAL_SCALE) -> Vector2:
	if visual_scale >= 1.0:
		return Vector2.ZERO
	var directions := [
		Vector2(0.0, -1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(-1.0, 0.0)
	]
	var offset := Vector2.ZERO
	var edge_gap := cell_size * (1.0 - visual_scale) * 0.5
	var north_cap_correction := cell_size * 0.04
	for i in range(min(ports.size(), 4)):
		if ports[i]:
			offset += directions[i] * edge_gap
			if i == 0:
				offset.y -= north_cap_correction
	return offset
