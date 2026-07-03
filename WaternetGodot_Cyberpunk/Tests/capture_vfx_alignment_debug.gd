extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")
const OUTPUT_PATH = "res://debug/vfx_alignment_debug.png"

const BOARD_SIZE = 5

var frame_count := 0
var scene = null
var installed := false
var passed := true

func _init() -> void:
	root.size = Vector2i(720, 1280)

func _process(_delta):
	frame_count += 1
	if scene == null:
		_setup_scene()
		return
	if not installed and frame_count >= 4:
		_install_level()
		return
	if frame_count < 12:
		scene.queue_redraw()
		return
	_capture()
	if passed:
		print("capture_vfx_alignment_debug: PASS")
		_cleanup()
		quit(0)
	else:
		print("capture_vfx_alignment_debug: FAIL")
		_cleanup()
		quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0

func _install_level() -> void:
	var grid = PipeGridScript.new()
	grid.initialize(_make_comb_level(BOARD_SIZE, BOARD_SIZE))
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 16
	scene.moves = 0
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.energy_flow_start_times = _make_energy_times(scene.grid)
	scene._recalculate_layout()
	scene._update_flow_visual_state(Time.get_ticks_msec() / 1000.0)
	scene._sync_vfx_layer()
	scene.pipe_vfx_layer.set_debug_visible(true)
	scene._update_hud()
	scene.queue_redraw()
	installed = true
	frame_count = 0

func _capture() -> void:
	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Failed to save %s: %s" % [OUTPUT_PATH, str(err)])
		return
	print("capture_vfx_alignment_debug: %s" % OUTPUT_PATH)

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
			grid_list.append({"type": visual["type"], "ports": ports, "rotation": int(visual["base_rot"]) * 90})
	var source_pos := Vector2i(0, 0)
	var target_pos := Vector2i(width - 1, height - 1)
	return {
		"id": 16,
		"width": width,
		"height": height,
		"source": {"x": source_pos.x, "y": source_pos.y, "ports": ports_by_cell[source_pos]},
		"target": {"x": target_pos.x, "y": target_pos.y, "ports": ports_by_cell[target_pos]},
		"grid": grid_list
	}

func _connect(ports_by_cell: Dictionary, cell_pos: Vector2i, direction: int) -> void:
	var neighbor := cell_pos + _direction_offset(direction)
	var opposite := (direction + 2) % 4
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
			return {"type": "I", "base_rot": 1 if int(active[0]) == 1 else 0}
		if active[0] == 0 and active[1] == 1:
			return {"type": "L", "base_rot": 0}
		if active[0] == 1 and active[1] == 2:
			return {"type": "L", "base_rot": 1}
		if active[0] == 2 and active[1] == 3:
			return {"type": "L", "base_rot": 2}
		return {"type": "L", "base_rot": 3}
	return {"type": "I", "base_rot": int(active[0]) if active.size() == 1 else 0}

func _make_energy_times(grid: RefCounted) -> Dictionary:
	var solver = ConnectionSolverScript.new()
	var watered_tiles: Dictionary = solver.get_watered_tiles(grid)
	var now := Time.get_ticks_msec() / 1000.0
	var times: Dictionary = {}
	for raw_cell_pos in watered_tiles.keys():
		var cell_pos: Vector2i = raw_cell_pos
		times[FlowVisualStateScript.get_cell_key(cell_pos)] = now - 1.0
	return times

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		scene.queue_free()
		scene = null
