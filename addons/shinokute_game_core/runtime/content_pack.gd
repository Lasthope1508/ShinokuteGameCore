class_name ShinokuteContentPack
extends RefCounted

const ContentTableScript := preload("res://addons/shinokute_game_core/runtime/content_table.gd")
const ContentReferenceGraphScript := preload("res://addons/shinokute_game_core/runtime/content_reference_graph.gd")
const ContentQueryScript := preload("res://addons/shinokute_game_core/runtime/content_query.gd")
const ContentTableValidatorScript := preload("res://addons/shinokute_game_core/runtime/content_table_validator.gd")

var _id := ""
var _version := ""
var _dependencies: Array = []
var _schemas: Dictionary = {}
var _tables: Dictionary = {}
var _errors: Array = []
var _options: Dictionary = {}

func configure(pack: Dictionary, options: Dictionary = {}) -> void:
	_id = String(pack.get("id", "")).strip_edges()
	_version = String(pack.get("version", "")).strip_edges()
	_dependencies = Array(pack.get("dependencies", [])).duplicate(true)
	_schemas = Dictionary(pack.get("schemas", {})).duplicate(true)
	_tables = {}
	_errors = []
	_options = options.duplicate(true)
	if _id.is_empty():
		_errors.append({"code": "missing_pack_id"})
	var raw_tables := Dictionary(pack.get("tables", {}))
	for table_name in raw_tables.keys():
		var schema := Dictionary(_schemas.get(table_name, {}))
		var raw_entries := Array(raw_tables.get(table_name, []))
		_validate_raw_table(String(table_name), raw_entries, schema)
		var table = ContentTableScript.new()
		table.configure(String(table_name), raw_entries, schema)
		_tables[String(table_name)] = table
		_errors.append_array(table.errors())
	var graph = ContentReferenceGraphScript.new()
	var graph_result: Dictionary = graph.validate(_tables, _schemas)
	_errors.append_array(Array(graph_result.get("errors", [])))

func pack_id() -> String:
	return _id

func version() -> String:
	return _version

func dependencies() -> Array:
	return _dependencies.duplicate(true)

func table_names() -> Array:
	return _tables.keys()

func is_valid() -> bool:
	return _errors.is_empty()

func errors() -> Array:
	return _errors.duplicate(true)

func entries(table_name: String, include_abstract: bool = false) -> Array:
	var table = _tables.get(table_name)
	if table == null:
		return []
	return table.entries(include_abstract)

func entry(table_name: String, id: String) -> Dictionary:
	var table = _tables.get(table_name)
	if table == null:
		return {}
	return table.entry_for_id(id)

func query(table_name: String, criteria: Dictionary = {}) -> Array:
	var query_runner = ContentQueryScript.new()
	query_runner.configure(_options)
	return query_runner.filter(entries(table_name, false), criteria)

func resolve_group(group_table_name: String, group_id: String) -> Array:
	var group := entry(group_table_name, group_id)
	if group.is_empty():
		return []
	var resolved: Array = []
	for item in Array(group.get("items", [])):
		if not (item is Dictionary):
			continue
		var item_dict := Dictionary(item)
		var ref := String(item_dict.get("ref", "")).strip_edges()
		var parts := ref.split("/", false, 1)
		if parts.size() != 2:
			continue
		var target := entry(parts[0], parts[1])
		if target.is_empty() or bool(target.get("abstract", false)):
			continue
		var merged := target.duplicate(true)
		for key in item_dict.keys():
			if String(key) != "ref":
				merged[key] = item_dict[key]
		resolved.append(merged)
	return resolved

func _validate_raw_table(table_name: String, raw_entries: Array, schema: Dictionary) -> void:
	var validator = ContentTableValidatorScript.new()
	var normalized_schema := schema.duplicate(true)
	normalized_schema["refs"] = []
	var result: Dictionary = validator.validate_table(raw_entries, normalized_schema)
	for error in Array(result.get("errors", [])):
		var normalized := Dictionary(error).duplicate(true)
		normalized["table"] = table_name
		_errors.append(normalized)
