# Dynamic Reflection-Based Asset Auditor for Godot 4 Projects.
# Uses runtime property reflection to audit any resource inheriting from ThemeConfig.
# Works globally across all game clients (Glyphflow Arrays, BloxChain, or future projects).
extends RefCounted
class_name AssetAuditor

# Audits a given theme resource and returns a report of configured vs missing assets
static func audit_theme(theme_res: Resource) -> Dictionary:
	var report = {
		"theme_name": "unknown",
		"ready": [],
		"missing": []
	}
	
	if theme_res == null:
		return report
		
	if "theme_name" in theme_res:
		report["theme_name"] = theme_res.get("theme_name")
		
	# Get all properties defined in the resource class
	var prop_list = theme_res.get_property_list()
	for prop in prop_list:
		var prop_name: String = prop["name"]
		var prop_type: int = prop["type"]
		var prop_usage: int = prop["usage"]
		
		# Inspect only editor-exported variables (PROPERTY_USAGE_EDITOR = 2 or 6)
		# and check for Object types (which include Texture2D, Font, AudioStream, PackedScene)
		if (prop_usage & PROPERTY_USAGE_EDITOR) and prop_type == TYPE_OBJECT:
			# Exclude script property itself
			if prop_name == "script":
				continue
				
			var value = theme_res.get(prop_name)
			if value == null:
				report["missing"].append(prop_name)
			else:
				var path = ""
				if value is Resource:
					path = value.resource_path
				report["ready"].append({
					"name": prop_name,
					"path": path
				})
				
	return report

# Prints a formatted console report of the audit results
static func print_report(theme_res: Resource) -> void:
	var report = audit_theme(theme_res)
	print("\n==================================================")
	print("🔍 ENGINE ASSET AUDIT REPORT FOR THEME: '%s'" % report["theme_name"].to_upper())
	print("==================================================")
	
	print("\n✅ READY / CONFIGURED ASSETS (%d):" % report["ready"].size())
	for item in report["ready"]:
		print("  - %s -> %s" % [item["name"], item["path"]])
		
	if report["missing"].size() > 0:
		print("\n🚨 MISSING / UNCONFIGURED ASSETS (%d) - DESIGN REQUIRED:" % report["missing"].size())
		for prop in report["missing"]:
			print("  - [ ] %s" % prop)
	else:
		print("\n🎉 ALL THEME ASSETS READY! 100% CONFIGURED.")
		
	print("\n==================================================")
