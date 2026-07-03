extends RefCounted

var _levels: Array = []

func load_levels(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
		
	var json_text = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Dictionary) or not parsed.has("levels"):
		return false
		
	_levels = parsed["levels"]
	return true

func get_levels() -> Array:
	return _levels

func get_level(level_id: int) -> Dictionary:
	for lvl in _levels:
		if lvl.get("id") == level_id:
			return lvl
	return {}
