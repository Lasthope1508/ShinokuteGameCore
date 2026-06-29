extends RefCounted

const DIRECTIONS = [
	Vector2i(0, -1), # 0: North
	Vector2i(1, 0),  # 1: East
	Vector2i(0, 1),  # 2: South
	Vector2i(-1, 0)  # 3: West
]

func check_connection(grid: RefCounted) -> bool:
	var source = grid.source_pos
	var target = grid.target_pos
	
	if not grid.is_valid_pos(source) or not grid.is_valid_pos(target):
		return false
		
	var visited = {}
	var stack = [source]
	visited[source] = true
	
	while stack.size() > 0:
		var curr = stack.pop_back()
		
		if curr == target:
			return true
			
		var curr_ports = grid.get_tile_ports(curr.x, curr.y)
		
		for dir_idx in range(4):
			# If the current tile doesn't have an open port in this direction, skip
			if not curr_ports[dir_idx]:
				continue
				
			var neighbor = curr + DIRECTIONS[dir_idx]
			if not grid.is_valid_pos(neighbor):
				continue
				
			# If already visited, skip
			if visited.has(neighbor):
				continue
				
			var neighbor_ports = grid.get_tile_ports(neighbor.x, neighbor.y)
			var opp_dir_idx = (dir_idx + 2) % 4
			
			# Check if neighbor has matching open port in the opposite direction
			if neighbor_ports[opp_dir_idx]:
				visited[neighbor] = true
				stack.append(neighbor)
				
	return visited.has(target)

func get_watered_tiles(grid: RefCounted) -> Dictionary:
	var source = grid.source_pos
	var visited = {}
	
	if not grid.is_valid_pos(source):
		return visited
		
	var stack = [source]
	visited[source] = true
	
	while stack.size() > 0:
		var curr = stack.pop_back()
		var curr_ports = grid.get_tile_ports(curr.x, curr.y)
		
		for dir_idx in range(4):
			# If the current tile doesn't have an open port in this direction, skip
			if not curr_ports[dir_idx]:
				continue
				
			var neighbor = curr + DIRECTIONS[dir_idx]
			if not grid.is_valid_pos(neighbor):
				continue
				
			# If already visited, skip
			if visited.has(neighbor):
				continue
				
			var neighbor_ports = grid.get_tile_ports(neighbor.x, neighbor.y)
			var opp_dir_idx = (dir_idx + 2) % 4
			
			# Check if neighbor has matching open port in the opposite direction
			if neighbor_ports[opp_dir_idx]:
				visited[neighbor] = true
				stack.append(neighbor)
				
	return visited
