extends RefCounted

static func generate_level(level_id: int, is_randomized: bool = true) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if is_randomized:
		rng.randomize()
	else:
		rng.seed = level_id
	
	# Determine board size based on level ID difficulty scale
	var width := 5
	var height := 5
	
	if level_id <= 3:
		width = 5
		height = 5
	elif level_id <= 6:
		width = 6
		height = 6
	elif level_id <= 9:
		width = 7
		height = 7
	elif level_id <= 12:
		width = 8
		height = 8
	elif level_id <= 15:
		width = 9
		height = 9
	else:
		width = 10
		height = 10
		
	# Grid data structures
	# Each cell has 4 ports: [Top, Right, Bottom, Left]
	var cell_ports = {}
	for y in range(height):
		for x in range(width):
			cell_ports[Vector2i(x, y)] = [false, false, false, false]
			
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
			
			var info = _get_base_rotation_and_type(original_ports)
			var base_rot = info["base_rot"]
			var type = info["type"]
			
			# Pick a random number of 90-degree rotations (0 to 3), skipping Source and Target
			var is_src_or_tgt = (pos == source_pos or pos == target_pos)
			var rand_rot = 0 if is_src_or_tgt else (rng.randi() % 4)
			var rotations_count = 0 if is_src_or_tgt else ((base_rot + rand_rot) % 4)
			
			var scrambled_ports = original_ports.duplicate()
			
			# Rotate clockwise by shifting right
			for step in range(rand_rot):
				var last = scrambled_ports.pop_back()
				scrambled_ports.push_front(last)
				
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

static func _get_base_rotation_and_type(ports: Array) -> Dictionary:
	var active = []
	for i in range(4):
		if ports[i]:
			active.append(i)
			
	var count = active.size()
	if count == 4:
		return {"type": "X", "base_rot": 0}
	elif count == 3:
		# T-pipe: canonical has West (3) closed, find the closed port
		var closed_port = 0
		for i in range(4):
			if not ports[i]:
				closed_port = i
				break
		var base_rot = (closed_port - 3 + 4) % 4
		return {"type": "T", "base_rot": base_rot}
	elif count == 2:
		var diff = abs(active[0] - active[1])
		if diff == 2:
			# Straight pipe (I)
			# Canonical I-pipe is vertical (ports 0 and 2 active)
			var base_rot = 0
			if active[0] == 1:
				base_rot = 1 # Horizontal
			return {"type": "I", "base_rot": base_rot}
		else:
			# Corner pipe (L)
			# Canonical L-pipe is North-East (ports 0 and 1 active)
			var base_rot = 0
			if active[0] == 0 and active[1] == 1:
				base_rot = 0
			elif active[0] == 1 and active[1] == 2:
				base_rot = 1
			elif active[0] == 2 and active[1] == 3:
				base_rot = 2
			elif active[0] == 0 and active[1] == 3:
				base_rot = 3
			return {"type": "L", "base_rot": base_rot}
	elif count == 1:
		# Cap-pipe (1 active port)
		# Canonical Cap-pipe is North (port 0 active)
		var base_rot = active[0]
		return {"type": "I", "base_rot": base_rot}
	else:
		return {"type": "I", "base_rot": 0}
