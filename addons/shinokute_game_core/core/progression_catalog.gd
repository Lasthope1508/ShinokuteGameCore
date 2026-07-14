class_name ShinokuteProgressionCatalog
extends Resource

const COMPLETION_NEXT_LOOP := "next_loop"
const COMPLETION_NEXT_HOLD := "next_hold"
const SORT_ASCENDING := "ASCENDING"
const SORT_DESCENDING := "DESCENDING"
const SORT_NONE := "NONE"

@export var game_family: String = ""
@export_enum("next_loop", "next_hold") var completion_policy: String = COMPLETION_NEXT_LOOP
@export var required_difficulty_keys: Array = []
@export var difficulty_sort_directions: Dictionary = {}
@export var required_layout_keys: Array = []
@export var layout_sort_directions: Dictionary = {}
@export var level_catalog: Array = []

func get_level(index: int) -> Resource:
	if level_catalog.is_empty():
		return null
	return level_catalog[clamp(index, 0, level_catalog.size() - 1)]

func get_level_index(level_id: String) -> int:
	for index in level_catalog.size():
		var level = level_catalog[index]
		if level != null and level.get("level_id") == level_id:
			return index
	return -1

func get_next_level_index(index: int) -> int:
	var level := get_level(index)
	if level != null:
		var next_level_id := String(level.get("next_level_id")).strip_edges()
		if not next_level_id.is_empty():
			var explicit_index := get_level_index(next_level_id)
			if explicit_index >= 0:
				return explicit_index
	var next_index := index + 1
	if next_index < level_catalog.size():
		return next_index
	if completion_policy == COMPLETION_NEXT_HOLD:
		return max(0, level_catalog.size() - 1)
	return 0

func get_difficulty_profile(index: int) -> Dictionary:
	var level := get_level(index)
	if level == null:
		return {}
	if level.has_method("difficulty_profile"):
		return level.difficulty_profile()
	return {
		"level_id": String(level.get("level_id")),
		"next_level_id": String(level.get("next_level_id")),
		"display_name": String(level.get("display_name")),
		"difficulty_tier": int(level.get("difficulty_tier")),
		"completion_condition": Dictionary(level.get("completion_condition")).duplicate(true),
		"failure_policy": Dictionary(level.get("failure_policy")).duplicate(true),
		"layout_profile": Dictionary(level.get("layout_profile")).duplicate(true),
		"stage_segments": Array(level.get("stage_segments")).duplicate(true),
		"environment_segments": Array(level.get("environment_segments")).duplicate(true),
		"difficulty_curve": Dictionary(level.get("difficulty_curve")).duplicate(true)
	}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if game_family.strip_edges().is_empty():
		errors.append("game_family is required")
	if level_catalog.is_empty():
		errors.append("level_catalog is required")
	var seen_ids := {}
	var previous_values := {}
	var previous_layout_values := {}
	for index in level_catalog.size():
		var level = level_catalog[index]
		if level == null:
			errors.append("level %s is null" % index)
			continue
		if level.has_method("validate"):
			for error in level.validate(required_difficulty_keys):
				errors.append("level %s: %s" % [index, error])
		if level.has_method("validate_layout"):
			for error in level.validate_layout(required_layout_keys):
				errors.append("level %s: %s" % [index, error])
		var level_id := String(level.get("level_id")).strip_edges()
		if level_id.is_empty():
			errors.append("level %s level_id is required" % index)
		elif seen_ids.has(level_id):
			errors.append("level %s duplicates level_id %s" % [index, level_id])
		else:
			seen_ids[level_id] = true
		var curve := Dictionary(level.get("difficulty_curve"))
		for key in required_difficulty_keys:
			if not curve.has(key):
				continue
			var value = curve[key]
			if not _is_number(value):
				continue
			var direction := String(difficulty_sort_directions.get(key, SORT_NONE)).to_upper()
			if previous_values.has(key):
				var previous := float(previous_values[key])
				var current := float(value)
				if direction == SORT_ASCENDING and current < previous:
					errors.append("level %s %s decreases" % [index, key])
				elif direction == SORT_DESCENDING and current > previous:
					errors.append("level %s %s increases" % [index, key])
			previous_values[key] = value
		var layout := Dictionary(level.get("layout_profile"))
		for key in required_layout_keys:
			if not layout.has(key):
				continue
			var value = layout[key]
			if not _is_number(value):
				continue
			var direction := String(layout_sort_directions.get(key, SORT_NONE)).to_upper()
			if previous_layout_values.has(key):
				var previous := float(previous_layout_values[key])
				var current := float(value)
				if direction == SORT_ASCENDING and current < previous:
					errors.append("level %s %s decreases" % [index, key])
				elif direction == SORT_DESCENDING and current > previous:
					errors.append("level %s %s increases" % [index, key])
			previous_layout_values[key] = value
	return errors

func _is_number(value) -> bool:
	return value is int or value is float
