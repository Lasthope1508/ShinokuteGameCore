extends SceneTree

const LevelDataScript = preload("res://Scripts/level_data.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const LevelGeneratorScript = preload("res://Scripts/level_generator.gd")

func _init() -> void:
	print("=========================================")
	print("  Running WaternetGodot Test Suite...    ")
	print("=========================================")
	
	var passed = true
	passed = passed and test_level_data_loading()
	passed = passed and test_tile_rotation()
	passed = passed and test_connectivity_solver()
	passed = passed and test_level_generator()
	
	if passed:
		print("=========================================")
		print("  Result: ALL TESTS PASSED! (Green)     ")
		print("=========================================")
		quit(0)
	else:
		print("=========================================")
		print("  Result: SOME TESTS FAILED! (Red)       ")
		print("=========================================")
		quit(1)

func assert_true(condition: bool, message: String) -> bool:
	if not condition:
		print("  [FAIL] ", message)
		return false
	print("  [PASS] ", message)
	return true

func test_level_data_loading() -> bool:
	print("\n--- Running test_level_data_loading ---")
	var l_data = LevelDataScript.new()
	var success = l_data.load_levels("res://Resources/levels.json")
	if not assert_true(success, "Should load levels.json successfully"):
		return false
		
	var levels = l_data.get_levels()
	if not assert_true(levels.size() >= 2, "Should parse at least 2 levels"):
		return false
		
	var lvl1 = l_data.get_level(1)
	if not assert_true(lvl1 != {}, "Level 1 data should exist"):
		return false
	if not assert_true(lvl1.get("width") == 3, "Level 1 width should be 3"):
		return false
	if not assert_true(lvl1.get("height") == 3, "Level 1 height should be 3"):
		return false
	return true

func test_tile_rotation() -> bool:
	print("\n--- Running test_tile_rotation ---")
	# Create a dummy grid for a 2x2 board
	var grid = PipeGridScript.new()
	var level_dict = {
		"width": 2,
		"height": 2,
		"source": {"x": 0, "y": 0, "ports": [false, true, true, false]},
		"target": {"x": 1, "y": 1, "ports": [true, false, false, true]},
		"grid": [
			{"type": "L", "ports": [false, true, true, false], "rotation": 0}, # (0,0) - East, South
			{"type": "I", "ports": [false, true, false, true], "rotation": 0}, # (1,0) - East, West
			{"type": "I", "ports": [true, false, true, false], "rotation": 0}, # (0,1) - North, South
			{"type": "L", "ports": [true, false, false, true], "rotation": 0}  # (1,1) - North, West
		]
	}
	grid.initialize(level_dict)
	
	# Verify initial ports of tile at (0, 0)
	var ports = grid.get_tile_ports(0, 0)
	# ports format: [North, East, South, West]
	if not assert_true(ports == [false, true, true, false], "Initial ports for (0,0) should be [false, true, true, false]"):
		return false
		
	# Rotate tile at (0, 0) once (90 degrees clockwise)
	grid.rotate_tile(0, 0)
	ports = grid.get_tile_ports(0, 0)
	# [false, true, true, false] shifted right becomes [false, false, true, true] (South, West)
	if not assert_true(ports == [false, false, true, true], "After 90 deg rotation, ports should be [false, false, true, true]"):
		return false
		
	# Rotate again (180 degrees total)
	grid.rotate_tile(0, 0)
	ports = grid.get_tile_ports(0, 0)
	# [false, false, true, true] shifted right becomes [true, false, false, true] (West, North)
	if not assert_true(ports == [true, false, false, true], "After 180 deg rotation, ports should be [true, false, false, true]"):
		return false
		
	# Rotate two more times to complete 360 degrees
	grid.rotate_tile(0, 0)
	grid.rotate_tile(0, 0)
	ports = grid.get_tile_ports(0, 0)
	if not assert_true(ports == [false, true, true, false], "After 360 deg rotation, ports should return to initial state"):
		return false
		
	return true

func test_connectivity_solver() -> bool:
	print("\n--- Running test_connectivity_solver ---")
	var grid = PipeGridScript.new()
	
	# Define a 1x3 grid: Source (0,0) -> Middle (1,0) -> Target (2,0)
	# Source has ports: [false, true, false, false] (East)
	# Target has ports: [false, false, false, true] (West)
	
	# Scenario A: Middle tile is misaligned (e.g. vertical Straight [true, false, true, false])
	# Connection should FAIL.
	var level_dict_fail = {
		"width": 3,
		"height": 1,
		"source": {"x": 0, "y": 0, "ports": [false, true, false, false]},
		"target": {"x": 2, "y": 0, "ports": [false, false, false, true]},
		"grid": [
			{"type": "S", "ports": [false, true, false, false], "rotation": 0}, # Source (0,0)
			{"type": "I", "ports": [true, false, true, false], "rotation": 0},  # Middle (1,0) - Vertical (blocked)
			{"type": "T", "ports": [false, false, false, true], "rotation": 0}  # Target (2,0)
		]
	}
	grid.initialize(level_dict_fail)
	var solver = ConnectionSolverScript.new()
	var connected = solver.check_connection(grid)
	if not assert_true(connected == false, "Connectivity check should FAIL when middle tile is vertical"):
		return false
		
	# Scenario B: Rotate Middle tile at (1,0) once -> becomes horizontal [false, true, false, true]
	# Connection should PASS!
	grid.rotate_tile(1, 0)
	connected = solver.check_connection(grid)
	if not assert_true(connected == true, "Connectivity check should PASS after rotating middle tile to horizontal"):
		return false
		
	return true

func test_level_generator() -> bool:
	print("\n--- Running test_level_generator ---")
	var lvl1 = LevelGeneratorScript.generate_level(1, false)
	if not assert_true(lvl1 != {}, "Generator should produce a non-empty level dict"):
		return false
	print("Godot Level 1 grid:")
	for cell in lvl1.get("grid"):
		print(cell)
	if not assert_true(lvl1.get("width") == 3 and lvl1.get("height") == 3, "Level 1 size should be 3x3"):
		return false
	if not assert_true(lvl1.get("grid").size() == 9, "Level 1 grid size should be 9"):
		return false
		
	# Verify seeding consistency
	var lvl1_again = LevelGeneratorScript.generate_level(1, false)
	if not assert_true(lvl1.get("grid")[3]["rotation"] == lvl1_again.get("grid")[3]["rotation"], "Generator should be deterministic with same seed"):
		return false
		
	# Verify difficulty scaling
	var lvl6 = LevelGeneratorScript.generate_level(6, false)
	if not assert_true(lvl6.get("width") == 4 and lvl6.get("height") == 4, "Level 6 size should scale up to 4x4"):
		return false
		
	return true

