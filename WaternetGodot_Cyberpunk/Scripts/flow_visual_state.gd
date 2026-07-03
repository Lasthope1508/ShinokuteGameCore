extends RefCounted
class_name FlowVisualState

const DIRECTIONS := [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

static func build(grid: RefCounted, energy_flow_start_times: Dictionary = {}, now: float = 0.0) -> Dictionary:
	var state := {}
	if grid == null or not grid.is_valid_pos(grid.source_pos):
		return state

	var visited := {}
	var queue: Array[Vector2i] = [grid.source_pos]
	visited[grid.source_pos] = true
	state[grid.source_pos] = _make_entry(grid.source_pos, 0, -1, [], energy_flow_start_times, now)

	var read_index := 0
	while read_index < queue.size():
		var current: Vector2i = queue[read_index]
		read_index += 1
		var output_dirs: Array[int] = []
		var current_order: int = state[current]["order"]

		for dir_idx in range(4):
			var neighbor = _get_connected_neighbor(grid, current, dir_idx)
			if neighbor == null:
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			output_dirs.append(dir_idx)
			var input_dir := (dir_idx + 2) % 4
			state[neighbor] = _make_entry(neighbor, current_order + 1, input_dir, [], energy_flow_start_times, now)
			queue.append(neighbor)

		state[current]["output_dirs"] = output_dirs
		state[current]["flow_mask"] = _make_flow_mask(state[current]["input_dir"], output_dirs)

	return state

static func _get_connected_neighbor(grid: RefCounted, current: Vector2i, dir_idx: int):
	var current_ports: Array = grid.get_tile_ports(current.x, current.y)
	if dir_idx >= current_ports.size() or not current_ports[dir_idx]:
		return null
	var neighbor: Vector2i = current + DIRECTIONS[dir_idx]
	if not grid.is_valid_pos(neighbor):
		return null
	var neighbor_ports: Array = grid.get_tile_ports(neighbor.x, neighbor.y)
	var opposite_dir := (dir_idx + 2) % 4
	if opposite_dir >= neighbor_ports.size() or not neighbor_ports[opposite_dir]:
		return null
	return neighbor

static func _make_entry(cell_pos: Vector2i, order: int, input_dir: int, output_dirs: Array, energy_flow_start_times: Dictionary, now: float) -> Dictionary:
	var key := get_cell_key(cell_pos)
	var age := 0.0
	if energy_flow_start_times.has(key):
		age = max(0.0, now - float(energy_flow_start_times[key]))
	return {
		"cell_pos": cell_pos,
		"order": order,
		"input_dir": input_dir,
		"output_dirs": output_dirs,
		"flow_mask": _make_flow_mask(input_dir, output_dirs),
		"age": age
	}

static func _make_flow_mask(input_dir: int, output_dirs: Array) -> int:
	var mask := 0
	if input_dir >= 0:
		mask |= 1 << input_dir
	for dir_idx in output_dirs:
		if int(dir_idx) >= 0:
			mask |= 1 << int(dir_idx)
	return mask

static func get_cell_key(cell_pos: Vector2i) -> String:
	return "%d,%d" % [cell_pos.x, cell_pos.y]
