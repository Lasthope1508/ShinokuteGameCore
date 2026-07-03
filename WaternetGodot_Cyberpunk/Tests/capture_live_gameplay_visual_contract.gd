extends SceneTree

const GAME_SCENE_PATH = "res://Scenes/Gameplay/GameScene.tscn"
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")
const OUTPUT_PATH = "res://debug/live_gameplay_visual_contract.png"

const BOARD_SIZE = 5

var frame_count: int = 0
var scene = null
var setup_done: bool = false
var contract_level_installed: bool = false
var passed: bool = true

func _init() -> void:
	root.size = Vector2i(720, 1280)

func _process(_delta):
	frame_count += 1
	if scene == null:
		_setup_scene()
		return
	if not contract_level_installed and frame_count >= 4:
		_install_contract_level()
		return
	if frame_count < 12:
		if scene != null:
			scene.queue_redraw()
		return
	_capture_and_validate()
	if passed:
		print("capture_live_gameplay_visual_contract: PASS")
		_cleanup()
		quit(0)
	else:
		print("capture_live_gameplay_visual_contract: FAIL")
		_cleanup()
		quit(1)

func _setup_scene() -> void:
	var theme_manager = root.get_node_or_null("ThemeManager")
	if theme_manager != null:
		theme_manager.load_theme("cyberpunk_theme")
	var game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.current_level_id = 16
	scene = load(GAME_SCENE_PATH).instantiate()
	root.add_child(scene)
	frame_count = 0
	setup_done = true

func _install_contract_level() -> void:
	var grid = PipeGridScript.new()
	grid.initialize(_make_comb_level(BOARD_SIZE, BOARD_SIZE))
	scene.grid = grid
	scene.solver = ConnectionSolverScript.new()
	scene.level_id = 16
	scene.moves = 0
	scene.is_solved = scene.solver.check_connection(scene.grid)
	scene.energy_flow_start_times = _make_energy_times(scene.grid)
	if scene.has_method("_recalculate_layout"):
		scene._recalculate_layout()
	if scene.has_method("_update_flow_visual_state"):
		scene._update_flow_visual_state(Time.get_ticks_msec() / 1000.0)
	if scene.has_method("_sync_vfx_layer"):
		scene._sync_vfx_layer()
	if scene.has_method("_update_hud"):
		scene._update_hud()
	scene.queue_redraw()
	contract_level_installed = true
	frame_count = 0

func _capture_and_validate() -> void:
	if scene == null or scene.grid == null:
		_fail("Scene and grid should exist")
		return
	var endpoints: Dictionary = scene.get_endpoint_cell_positions()
	_assert_equal(endpoints.get("source", Vector2i(-1, -1)), Vector2i(0, 0), "Source should be top-left")
	_assert_equal(endpoints.get("target", Vector2i(-1, -1)), Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1), "Target should be bottom-right")
	var board_rect: Rect2 = scene.get_board_rect()
	var viewport_size: Vector2 = scene.get_viewport_rect().size
	_assert_true(board_rect.position.x >= 0.0 and board_rect.position.y >= 0.0, "Board should start inside viewport")
	_assert_true(board_rect.end.x <= viewport_size.x, "Board should fit viewport width")
	_assert_true(board_rect.end.y <= viewport_size.y, "Board should fit viewport height")
	_assert_true(scene.pipe_vfx_layer != null, "VFX layer should exist in live scene")
	_assert_true(scene.flow_visual_state.size() == BOARD_SIZE * BOARD_SIZE, "Live visual state should cover watered contract board")

	var image: Image = root.get_texture().get_image()
	if image == null:
		_fail("Viewport image is null")
		return
	_assert_true(_image_has_variation(image), "Live capture should not be blank")
	var source_rect: Rect2 = scene.get_cell_rect(Vector2i(0, 0))
	var target_rect: Rect2 = scene.get_cell_rect(Vector2i(BOARD_SIZE - 1, BOARD_SIZE - 1))
	var image_scale: Vector2 = Vector2(float(image.get_width()) / viewport_size.x, float(image.get_height()) / viewport_size.y)
	_assert_true(_region_has_variation(image, _scale_rect(source_rect, image_scale)), "Source cell region should render visible detail")
	_assert_true(_region_has_variation(image, _scale_rect(target_rect, image_scale)), "Target cell region should render visible detail")

	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Failed to save %s: %s" % [OUTPUT_PATH, str(err)])
		return
	print("capture_live_gameplay_visual_contract: %s" % OUTPUT_PATH)

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

func _make_energy_times(grid: RefCounted) -> Dictionary:
	var solver = ConnectionSolverScript.new()
	var watered_tiles: Dictionary = solver.get_watered_tiles(grid)
	var now: float = Time.get_ticks_msec() / 1000.0
	var times: Dictionary = {}
	for raw_cell_pos in watered_tiles.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var age: float = 1.0
		if cell_pos == Vector2i(0, 0):
			age = 0.08
		elif cell_pos.x <= 2 and cell_pos.y == 0:
			age = 0.16
		times[FlowVisualStateScript.get_cell_key(cell_pos)] = now - age
	return times

func _image_has_variation(image: Image) -> bool:
	return _region_has_variation(image, Rect2(Vector2.ZERO, Vector2(image.get_size())))

func _region_has_variation(image: Image, rect: Rect2) -> bool:
	var start_x: int = clampi(int(rect.position.x), 0, image.get_width() - 1)
	var start_y: int = clampi(int(rect.position.y), 0, image.get_height() - 1)
	var end_x: int = clampi(int(rect.end.x), start_x + 1, image.get_width())
	var end_y: int = clampi(int(rect.end.y), start_y + 1, image.get_height())
	var base: Color = image.get_pixel(start_x, start_y)
	var step_x: int = max(1, (end_x - start_x) / 6)
	var step_y: int = max(1, (end_y - start_y) / 6)
	for y in range(start_y, end_y, step_y):
		for x in range(start_x, end_x, step_x):
			if _color_distance(base, image.get_pixel(x, y)) > 0.04:
				return true
	return false

func _scale_rect(rect: Rect2, scale: Vector2) -> Rect2:
	return Rect2(rect.position * scale, rect.size * scale)

func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) + abs(a.a - b.a)

func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail("%s: expected true" % message)

func _fail(message: String) -> void:
	passed = false
	push_error(message)

func _cleanup() -> void:
	if scene != null:
		if scene.energy_sheet_texture_cache != null:
			scene.energy_sheet_texture_cache.clear()
		if scene.energy_frame_texture_cache != null:
			scene.energy_frame_texture_cache.clear()
		scene.queue_free()
		scene = null
