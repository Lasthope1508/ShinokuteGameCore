extends RefCounted

static func generate_level(level_id: int, is_randomized: bool = true) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if is_randomized:
		rng.randomize()
	else:
		rng.seed = level_id
	
	# Determine board size based on level ID difficulty scale
	var width := 3
	var height := 3
	
	if level_id <= 3:
		width = 3
		height = 3
	elif level_id <= 6:
		width = 4
		height = 4
	elif level_id <= 9:
		width = 5
		height = 5
	elif level_id <= 12:
		width = 6
		height = 6
	elif level_id <= 15:
		width = 8
		height = 8
	else:
		width = 10
		height = 10
		
	# Grid data structures
	# Each cell has 4 ports: [Top, Right, Bottom, Left]
	var cell_ports = {}
	for y in range(height):
		for x in range(width):
			cell_ports[Vector2i(x, y)] = [false, false, false, false]
			
	# Identify source and target positions
	var source_pos = Vector2i(0, 0)
	var target_pos = Vector2i(width - 1, height - 1)
	
	# Generate Spanning Tree using DFS
	var stack: Array[Vector2i] = []
	var visited := {}
	
	var start_cell = source_pos
	stack.append(start_cell)
	visited[start_cell] = true
	
	var directions = [
		Vector2i(0, -1), # Top (0)
		Vector2i(1, 0),  # Right (1)
		Vector2i(0, 1),  # Bottom (2)
		Vector2i(-1, 0)  # Left (3)
	]
	
	while not stack.is_empty():
		var current = stack[-1]
		if current == target_pos:
			# Target must be a dead-end (1 port)
			stack.pop_back()
			continue
			
		var unvisited_neighbors = []
		
		for i in range(4):
			var dir = directions[i]
			var neighbor = current + dir
			if neighbor.x >= 0 and neighbor.x < width and neighbor.y >= 0 and neighbor.y < height:
				if not visited.has(neighbor):
					unvisited_neighbors.append({"pos": neighbor, "dir_index": i})
					
		if not unvisited_neighbors.is_empty():
			# Pick a random neighbor
			var next_choice = unvisited_neighbors[rng.randi() % unvisited_neighbors.size()]
			var next_pos = next_choice["pos"]
			var dir_idx = next_choice["dir_index"]
			var opp_dir_idx = (dir_idx + 2) % 4
			
			# Open connections in both cells
			cell_ports[current][dir_idx] = true
			cell_ports[next_pos][opp_dir_idx] = true
			
			visited[next_pos] = true
			stack.append(next_pos)
		else:
			stack.pop_back()
			
	# Scramble the board by applying random rotations (0, 90, 180, 270)
	var grid_list = []
	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var original_ports = cell_ports[pos]
			
			# Pick a random number of 90-degree rotations (0 to 3)
			var rotations_count = rng.randi() % 4
			var scrambled_ports = original_ports.duplicate()
			
			# Rotate clockwise by shifting right
			for step in range(rotations_count):
				var last = scrambled_ports.pop_back()
				scrambled_ports.push_front(last)
				
			# Determine visual pipe type based on port count/shape for description
			var active_count = 0
			for p in scrambled_ports:
				if p: active_count += 1
				
			var type = "I"
			if active_count == 4:
				type = "X"
			elif active_count == 3:
				type = "T"
			elif active_count == 2:
				# Corner L vs Straight I
				var p = scrambled_ports
				if (p[0] and p[2]) or (p[1] and p[3]):
					type = "I"
				else:
					type = "L"
			else:
				type = "I" # End caps
				
			grid_list.append({
				"type": type,
				"ports": scrambled_ports,
				"rotation": rotations_count * 90
			})
			
	var level_dict = {
		"id": level_id,
		"width": width,
		"height": height,
		"source": {
			"x": source_pos.x,
			"y": source_pos.y,
			"ports": cell_ports[source_pos]
		},
		"target": {
			"x": target_pos.x,
			"y": target_pos.y,
			"ports": cell_ports[target_pos]
		},
		"grid": grid_list
	}
	
	return level_dict
