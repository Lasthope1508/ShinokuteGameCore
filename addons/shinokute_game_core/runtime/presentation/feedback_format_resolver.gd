class_name ShinokuteFeedbackFormatResolver
extends RefCounted

func format_text(template: String, values: Array = []) -> String:
	if template.is_empty():
		return ""
	if values.is_empty():
		return template
	return template % values
