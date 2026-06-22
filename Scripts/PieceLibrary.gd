## Loads PieceShape .tres files and provides weighted random picking.
## Loads from PIECE_PATHS first (required for HTML5, where DirAccess.open()
## on a res:// directory returns null), then falls back to a DirAccess scan
## on editor/desktop. When adding a new piece, append its path to PIECE_PATHS
## or it will be missing on web builds.
class_name PieceLibrary extends RefCounted

const DEFAULT_PIECES_DIR := "res://Resources/Data/Pieces/"

# Explicit registry — must contain every shipped piece.
const PIECE_PATHS: Array[String] = [
	"res://Resources/Data/Pieces/mono.tres",
	"res://Resources/Data/Pieces/domino_h.tres",
	"res://Resources/Data/Pieces/domino_v.tres",
	"res://Resources/Data/Pieces/tri_h.tres",
	"res://Resources/Data/Pieces/tri_v.tres",
	"res://Resources/Data/Pieces/corner_3.tres",
	"res://Resources/Data/Pieces/l_shape.tres",
	"res://Resources/Data/Pieces/j_shape.tres",
	"res://Resources/Data/Pieces/t_shape.tres",
	"res://Resources/Data/Pieces/i_shape_h.tres",
	"res://Resources/Data/Pieces/i_shape_v.tres",
	"res://Resources/Data/Pieces/s_shape.tres",
	"res://Resources/Data/Pieces/square_2.tres",
	"res://Resources/Data/Pieces/square_3.tres",
]

var _shapes: Array[PieceShape] = []
var _total_weight: float = 0.0


func _init(pieces_dir: String = DEFAULT_PIECES_DIR) -> void:
	_shapes.clear()
	_total_weight = 0.0
	_load_from_paths(PIECE_PATHS)
	if _shapes.is_empty():
		_load_from_dir(pieces_dir)


func _load_from_paths(paths: Array) -> void:
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var res := load(path)
		_register_shape(res)


func _load_from_dir(pieces_dir: String) -> void:
	var dir := DirAccess.open(pieces_dir)
	if dir == null:
		push_warning("PieceLibrary: cannot open dir %s" % pieces_dir)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and (fname.ends_with(".tres") or fname.ends_with(".res")):
			var path := pieces_dir.path_join(fname)
			var res := load(path)
			_register_shape(res)
		fname = dir.get_next()
	dir.list_dir_end()


func _register_shape(res: Resource) -> void:
	if res is PieceShape and (res as PieceShape).cells.size() > 0:
		_shapes.append(res)
		_total_weight += max(0.0, (res as PieceShape).weight)


# Backward-compatible alias from before the explicit registry was added.
func load_from_dir(pieces_dir: String) -> void:
	_shapes.clear()
	_total_weight = 0.0
	_load_from_dir(pieces_dir)


func get_all() -> Array[PieceShape]:
	return _shapes.duplicate()


func is_empty() -> bool:
	return _shapes.is_empty()


# Weighted random pick. Falls back to uniform if every weight is 0.
func pick_random() -> PieceShape:
	if _shapes.is_empty():
		return null
	if _total_weight <= 0.0:
		return _shapes.pick_random()
	var roll := randf() * _total_weight
	var acc := 0.0
	for s in _shapes:
		acc += max(0.0, s.weight)
		if roll <= acc:
			return s
	return _shapes.back()
