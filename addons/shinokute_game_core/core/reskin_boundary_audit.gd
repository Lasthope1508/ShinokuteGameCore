class_name ShinokuteReskinBoundaryAudit
extends RefCounted

const DEFAULT_FORBIDDEN_CORE_MARKERS := [
	"CandyGameCore",
	"candySky",
	"candy-touch",
	"__candy",
	"Candy Sky",
	"assets/themes/",
	"Resources/Data/Themes/",
	"sounds/candy",
	"GameProgressionConfig",
	"GameLevelDefinition"
]

static func default_forbidden_core_markers() -> Array:
	return DEFAULT_FORBIDDEN_CORE_MARKERS.duplicate()

func scan_text(text: String, source_label: String = "", markers: Array = []) -> Array[String]:
	var findings: Array[String] = []
	var active_markers: Array = markers
	if active_markers.is_empty():
		active_markers = default_forbidden_core_markers()
	var label := source_label
	if label.strip_edges().is_empty():
		label = "<text>"
	for marker in active_markers:
		var marker_text := String(marker)
		if not marker_text.strip_edges().is_empty() and text.contains(marker_text):
			findings.append("%s contains forbidden marker '%s'" % [label, marker_text])
	return findings

func scan_file(path: String, markers: Array = []) -> Array[String]:
	if not FileAccess.file_exists(path):
		return ["%s is missing" % path]
	return scan_text(FileAccess.get_file_as_string(path), path, markers)

func scan_paths(paths: Array, markers: Array = []) -> Array[String]:
	var findings: Array[String] = []
	for path in paths:
		findings.append_array(scan_file(String(path), markers))
	return findings
