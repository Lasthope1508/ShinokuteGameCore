class_name ShinokutePublishAudit
extends RefCounted

const DEFAULT_FORBIDDEN_MARKERS := ["debug", "scratch", "raw", "reference", ".psd", ".kra", ".aseprite"]

func validate_manifest(entries: Array, required_keys: Array = ["path", "role"]) -> Dictionary:
	var errors: Array = []
	for index in range(entries.size()):
		if not (entries[index] is Dictionary):
			errors.append({"code": "invalid_entry", "index": index})
			continue
		var entry := Dictionary(entries[index])
		for key in required_keys:
			if not entry.has(String(key)) or String(entry.get(String(key), "")).strip_edges().is_empty():
				errors.append({"code": "missing_required", "index": index, "field": String(key)})
		var path := String(entry.get("path", ""))
		var marker := _first_forbidden_marker(path, DEFAULT_FORBIDDEN_MARKERS)
		if not marker.is_empty():
			errors.append({"code": "forbidden_marker", "index": index, "path": path, "marker": marker})
	return {"accepted": errors.is_empty(), "errors": errors}

func scan_forbidden_markers(paths: Array, markers: Array = DEFAULT_FORBIDDEN_MARKERS) -> Dictionary:
	var matches: Array = []
	for path_value in paths:
		var path := String(path_value)
		var marker := _first_forbidden_marker(path, markers)
		if not marker.is_empty():
			matches.append({"path": path, "marker": marker})
	return {"accepted": matches.is_empty(), "matches": matches}

func audit_export_presets_text(text: String, required_presets: Array) -> Dictionary:
	var missing: Array = []
	for preset in required_presets:
		var name := String(preset)
		if text.find("name=\"%s\"" % name) == -1 and text.find("platform=\"%s\"" % name) == -1:
			missing.append(name)
	return {"accepted": missing.is_empty(), "missing_presets": missing}

func audit_hosting_headers(headers: Dictionary, required_headers: Array) -> Dictionary:
	var missing: Array = []
	for header in required_headers:
		var key := String(header)
		if not headers.has(key) or String(headers.get(key, "")).strip_edges().is_empty():
			missing.append(key)
	return {"accepted": missing.is_empty(), "missing_headers": missing}

func _first_forbidden_marker(path: String, markers: Array) -> String:
	var normalized := path.to_lower()
	for marker_value in markers:
		var marker := String(marker_value).to_lower()
		if not marker.is_empty() and normalized.find(marker) != -1:
			return marker
	return ""
