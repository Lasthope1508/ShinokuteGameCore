class_name ShinokuteProgressionLevel
extends Resource

@export var level_id: String = ""
@export var display_name: String = ""
@export var difficulty_tier: int = 1
@export var completion_condition: Dictionary = {}
@export var failure_policy: Dictionary = {}
@export var layout_profile: Dictionary = {}
@export var stage_segments: Array = []
@export var environment_segments: Array = []
@export var difficulty_curve: Dictionary = {}
@export var next_level_id: String = ""

func difficulty_profile() -> Dictionary:
	var profile := {
		"level_id": level_id,
		"next_level_id": next_level_id,
		"display_name": display_name,
		"difficulty_tier": difficulty_tier,
		"completion_condition": completion_condition.duplicate(true),
		"failure_policy": failure_policy.duplicate(true),
		"layout_profile": layout_profile.duplicate(true),
		"stage_segments": stage_segments.duplicate(true),
		"environment_segments": environment_segments.duplicate(true),
		"difficulty_curve": difficulty_curve.duplicate(true)
	}
	for key in difficulty_curve.keys():
		profile[key] = difficulty_curve[key]
	return profile

func validate(required_difficulty_keys: Array = []) -> Array[String]:
	var errors: Array[String] = []
	if level_id.strip_edges().is_empty():
		errors.append("level_id is required")
	if completion_condition.is_empty():
		errors.append("%s completion_condition is required" % level_id)
	if failure_policy.is_empty():
		errors.append("%s failure_policy is required" % level_id)
	if layout_profile.is_empty():
		errors.append("%s layout_profile is required" % level_id)
	if stage_segments.size() < 2:
		errors.append("%s stage_segments must include at least start and goal" % level_id)
	for key in required_difficulty_keys:
		if not difficulty_curve.has(key):
			errors.append("%s difficulty_curve missing %s" % [level_id, key])
		elif not _is_number(difficulty_curve[key]):
			errors.append("%s difficulty_curve %s must be numeric" % [level_id, key])
	return errors

func validate_layout(required_layout_keys: Array = []) -> Array[String]:
	var errors: Array[String] = []
	for key in required_layout_keys:
		if not layout_profile.has(key):
			errors.append("%s layout_profile missing %s" % [level_id, key])
		elif not _is_number(layout_profile[key]):
			errors.append("%s layout_profile %s must be numeric" % [level_id, key])
	return errors

func _is_number(value) -> bool:
	return value is int or value is float
