extends RefCounted

var width: int = 0
var height: int = 0
var source_pos: Vector2i = Vector2i.ZERO
var source_ports: Array = [false, false, false, false]
var target_pos: Vector2i = Vector2i.ZERO
var target_ports: Array = [false, false, false, false]

# Dictionary of Vector2i -> Dictionary (tile)
var _grid: Dictionary = {}

func initialize(level_dict: Dictionary) -> void:
	width = level_dict.get("width", 0)
	height = level_dict.get("height", 0)
	
	var src_dict = level_dict.get("source", {})
	source_pos = Vector2i(src_dict.get("x", 0), src_dict.get("y", 0))
	source_ports = src_dict.get("ports", [false, false, false, false])
	
	var tgt_dict = level_dict.get("target", {})
	target_pos = Vector2i(tgt_dict.get("x", 0), tgt_dict.get("y", 0))
	target_ports = tgt_dict.get("ports", [false, false, false, false])
	
	_grid.clear()
	var grid_array = level_dict.get("grid", [])
	
	for y in range(height):
		for x in range(width):
			var idx = x + y * width
			if idx < grid_array.size():
				var cell_data = grid_array[idx]
				# Create a deep copy of ports
				var ports = []
				for p in cell_data.get("ports", [false, false, false, false]):
					ports.append(bool(p))
					
				var tile = {
					"type": cell_data.get("type", "I"),
					"ports": ports,
					"rotation": int(cell_data.get("rotation", 0))
				}
				_grid[Vector2i(x, y)] = tile

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_tile(x: int, y: int) -> Dictionary:
	var pos = Vector2i(x, y)
	if _grid.has(pos):
		return _grid[pos]
	return {}

func get_tile_ports(x: int, y: int) -> Array:
	var tile = get_tile(x, y)
	if not tile.is_empty():
		return tile["ports"]
	return [false, false, false, false]

func rotate_tile(x: int, y: int) -> void:
	var tile = get_tile(x, y)
	if tile.is_empty():
		return
		
	var ports = tile["ports"]
	# Rotate ports array 90 degrees clockwise (shift right by 1)
	var last = ports.pop_back()
	ports.push_front(last)
	
	# Update rotation angle
	tile["rotation"] = (int(tile["rotation"]) + 90) % 360
