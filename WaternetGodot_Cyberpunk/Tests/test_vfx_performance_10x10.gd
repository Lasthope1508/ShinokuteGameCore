extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")
const PipeVfxLayer = preload("res://Scripts/pipe_vfx_layer.gd")

const BOARD_SIZE = 10
const CELL_SIZE = 72.0
const SAMPLE_TIME = 2.0
const START_TIME = 0.0
const MAX_EFFECTS_PER_FLOW_CELL = 5
const FRAME_BUDGET_USEC_60FPS = 16666

func _init() -> void:
	var passed: bool = true
	var theme = load(THEME_PATH)
	var level: Dictionary = _make_comb_level(BOARD_SIZE, BOARD_SIZE)
	var grid = PipeGridScript.new()
	grid.initialize(level)
	var solver = ConnectionSolverScript.new()
	var watered_tiles: Dictionary = solver.get_watered_tiles(grid)
	var energy_times: Dictionary = _make_energy_times(watered_tiles)
	var flow_state: Dictionary = FlowVisualStateScript.build(grid, energy_times, SAMPLE_TIME)
	var geometry_by_cell: Dictionary = _make_geometry_map(grid, theme)
	var layer = PipeVfxLayer.new()

	passed = passed and _assert_equal(grid.width, BOARD_SIZE, "Perf fixture should use 10x10 board width")
	passed = passed and _assert_equal(grid.height, BOARD_SIZE, "Perf fixture should use 10x10 board height")
	passed = passed and _assert_equal(grid.source_pos, Vector2i(0, 0), "Perf fixture should keep source top-left")
	passed = passed and _assert_equal(grid.target_pos, Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1), "Perf fixture should keep target bottom-right")
	passed = passed and _assert_true(solver.check_connection(grid), "Perf fixture should connect source to target")
	passed = passed and _assert_equal(flow_state.size(), BOARD_SIZE * BOARD_SIZE, "Perf fixture should water every 10x10 tile")

	layer.set_visual_context(flow_state, geometry_by_cell, Vector2(24, 48), CELL_SIZE)
	layer.apply_theme_config(theme, CELL_SIZE)

	var started_usec: int = Time.get_ticks_usec()
	var trails: Array = layer.get_directional_trails()
	var sparks: Array = layer.get_contact_sparks()
	var pulses: Array = layer.get_target_pulses()
	var emissions: Array = layer.get_source_emissions()
	var hums: Array = layer.get_idle_hums()
	var streams: Array = layer.get_energy_streams(SAMPLE_TIME)
	var waves: Array = layer.get_path_waves(SAMPLE_TIME)
	var lightning: Array = layer.get_lightning_arcs(SAMPLE_TIME)
	layer.set_win_state({"event_time": SAMPLE_TIME})
	var bursts: Array = layer.get_win_bursts(SAMPLE_TIME + 0.1)
	var elapsed_usec: int = Time.get_ticks_usec() - started_usec
	var total_effects: int = trails.size() + sparks.size() + pulses.size() + emissions.size() + hums.size() + streams.size() + waves.size() + lightning.size() + bursts.size()
	var effect_budget: int = flow_state.size() * MAX_EFFECTS_PER_FLOW_CELL

	passed = passed and _assert_true(trails.size() <= flow_state.size(), "Trail count should stay bounded by connected edges")
	passed = passed and _assert_true(hums.size() <= max(0, flow_state.size() - 2), "Idle hum count should stay bounded by non-endpoint cells")
	passed = passed and _assert_true(streams.size() <= int(theme.get("vfx_energy_stream_max_effects")), "Energy stream count should respect theme cap")
	passed = passed and _assert_true(waves.size() <= int(theme.get("vfx_path_wave_max_effects")), "Path wave count should respect theme cap")
	passed = passed and _assert_true(lightning.size() <= int(theme.get("vfx_lightning_max_arcs")), "Lightning arc count should respect theme cap")
	passed = passed and _assert_true(bursts.size() <= int(theme.get("vfx_win_burst_max_cells")), "Win burst count should respect theme cap")
	passed = passed and _assert_true(total_effects <= effect_budget, "Total VFX records should stay bounded by flow state")
	passed = passed and _assert_true(elapsed_usec <= FRAME_BUDGET_USEC_60FPS, "VFX data build should stay within 60 FPS frame budget")
	print("test_vfx_performance_10x10: flow=%d trails=%d hums=%d streams=%d waves=%d lightning=%d bursts=%d sparks=%d pulses=%d emissions=%d total=%d budget=%d elapsed_usec=%d" % [
		flow_state.size(),
		trails.size(),
		hums.size(),
		streams.size(),
		waves.size(),
		lightning.size(),
		bursts.size(),
		sparks.size(),
		pulses.size(),
		emissions.size(),
		total_effects,
		effect_budget,
		elapsed_usec
	])

	layer.free()

	if passed:
		print("test_vfx_performance_10x10: PASS")
		quit(0)
	else:
		print("test_vfx_performance_10x10: FAIL")
		quit(1)

func _make_comb_level(width: int, height: int) -> Dictionary:
	var ports_by_cell: Dictionary = {}
	for y in range(height):
		for x in range(width):
			ports_by_cell[Vector2i(x, y)] = [false, false, false, false]
	for y in range(height):
		for x in range(width - 1):
			_connect(ports_by_cell, Vector2i(x, y), 1)
	for y in range(height - 1):
		_connect(ports_by_cell, Vector2i(0, y), 2)

	var grid_list: Array = []
	for y in range(height):
		for x in range(width):
			var ports: Array = ports_by_cell[Vector2i(x, y)]
			var visual: Dictionary = _get_base_rotation_and_type(ports)
			grid_list.append({
				"type": visual["type"],
				"ports": ports,
				"rotation": int(visual["base_rot"]) * 90
			})
	var source_pos: Vector2i = Vector2i(0, 0)
	var target_pos: Vector2i = Vector2i(width - 1, height - 1)
	return {
		"id": 16,
		"width": width,
		"height": height,
		"source": {"x": source_pos.x, "y": source_pos.y, "ports": ports_by_cell[source_pos]},
		"target": {"x": target_pos.x, "y": target_pos.y, "ports": ports_by_cell[target_pos]},
		"grid": grid_list
	}

func _connect(ports_by_cell: Dictionary, cell_pos: Vector2i, direction: int) -> void:
	var neighbor: Vector2i = cell_pos + _direction_offset(direction)
	var opposite: int = (direction + 2) % 4
	var cell_ports: Array = ports_by_cell[cell_pos]
	var neighbor_ports: Array = ports_by_cell[neighbor]
	cell_ports[direction] = true
	neighbor_ports[opposite] = true
	ports_by_cell[cell_pos] = cell_ports
	ports_by_cell[neighbor] = neighbor_ports

func _direction_offset(direction: int) -> Vector2i:
	match direction:
		0:
			return Vector2i(0, -1)
		1:
			return Vector2i(1, 0)
		2:
			return Vector2i(0, 1)
		3:
			return Vector2i(-1, 0)
	return Vector2i.ZERO

func _get_base_rotation_and_type(ports: Array) -> Dictionary:
	var active: Array = []
	for i in range(4):
		if ports[i]:
			active.append(i)
	var count: int = active.size()
	if count == 4:
		return {"type": "X", "base_rot": 0}
	if count == 3:
		var closed_port: int = 0
		for i in range(4):
			if not ports[i]:
				closed_port = i
				break
		return {"type": "T", "base_rot": (closed_port - 3 + 4) % 4}
	if count == 2:
		var diff: int = abs(int(active[0]) - int(active[1]))
		if diff == 2:
			var straight_rot: int = 0
			if int(active[0]) == 1:
				straight_rot = 1
			return {"type": "I", "base_rot": straight_rot}
		if active[0] == 0 and active[1] == 1:
			return {"type": "L", "base_rot": 0}
		if active[0] == 1 and active[1] == 2:
			return {"type": "L", "base_rot": 1}
		if active[0] == 2 and active[1] == 3:
			return {"type": "L", "base_rot": 2}
		return {"type": "L", "base_rot": 3}
	var cap_rot: int = 0
	if active.size() == 1:
		cap_rot = int(active[0])
	return {"type": "I", "base_rot": cap_rot}

func _make_energy_times(watered_tiles: Dictionary) -> Dictionary:
	var energy_times: Dictionary = {}
	for raw_cell_pos in watered_tiles.keys():
		var cell_pos: Vector2i = raw_cell_pos
		energy_times[FlowVisualStateScript.get_cell_key(cell_pos)] = START_TIME
	return energy_times

func _make_geometry_map(grid: RefCounted, theme) -> Dictionary:
	var geometry_by_cell: Dictionary = {}
	for y in range(grid.height):
		for x in range(grid.width):
			var cell_pos: Vector2i = Vector2i(x, y)
			if cell_pos == grid.source_pos:
				geometry_by_cell[cell_pos] = theme.source_geometry
			elif cell_pos == grid.target_pos:
				geometry_by_cell[cell_pos] = theme.target_geometry
			else:
				geometry_by_cell[cell_pos] = theme.get_asset_geometry(grid.get_tile(x, y).get("type", "I"))
	return geometry_by_cell

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
