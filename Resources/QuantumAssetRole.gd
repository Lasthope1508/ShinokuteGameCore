extends Resource
class_name QuantumAssetRole

const ALLOWED_MODES := ["legacy", "material", "replacement", "unused_candidate", "audio_deferred"]

@export var role_key := ""
@export var legacy_path := ""
@export var reference_path := ""
@export var replacement_path := ""
@export_enum("legacy", "material", "replacement", "unused_candidate", "audio_deferred") var mode := "legacy"
@export var proof_path := ""
@export var notes := ""

func active_path() -> String:
	if mode == "replacement" and not replacement_path.strip_edges().is_empty():
		return replacement_path
	return legacy_path

func validate_role() -> Array[String]:
	var errors: Array[String] = []
	if role_key.strip_edges().is_empty():
		errors.append("role_key is required")
	if not ALLOWED_MODES.has(mode):
		errors.append("invalid mode: %s" % mode)
	if legacy_path.strip_edges().is_empty():
		errors.append("%s legacy_path is required" % role_key)
	if mode == "replacement" and replacement_path.strip_edges().is_empty():
		errors.append("%s replacement_path is required in replacement mode" % role_key)
	return errors
