extends SceneTree

func _init() -> void:
	var passed := true
	var workflow := FileAccess.get_file_as_string("res://docs/ui_production_workflow.md")
	var language := FileAccess.get_file_as_string("res://docs/ui_design_language.md")

	passed = passed and _assert_true(not workflow.is_empty(), "UI production workflow doc should exist")
	passed = passed and _assert_true(language.contains("docs/ui_production_workflow.md"), "UI design language should point to production workflow")

	for required_text in [
		"Do not design professional game UI by hand-tweaking Godot controls first.",
		"B1. Responsive Frame",
		"B2. Owner Layout Gate",
		"B3. Background Asset",
		"B4. Fake3D Layer Asset",
		"B5. Component Object Generation",
		"B6. Visual Audit Loop",
		"vertical and horizontal screens",
		"Top region rect",
		"Bottom region rect",
		"Generate usable game assets, not poster art.",
		"Generate one isolated object per image through 9Router.",
		"`background_full` is the only full-screen generated production asset.",
		"Do not generate posters, sample gameplay screenshots, or decorative full-screen compositions for components.",
		"Do not bake text, fake logos, characters, mascots, gameplay pipes, or board screenshots into UI components.",
		"Use 9Router",
		"Use PhotoRoom",
		"Chroma key is not a production substitute.",
		"Every non-background object output must pass PhotoRoom cleanup before it can be marked production-ready.",
		"Godot integration happens only after the PhotoRoom output and owner-approved object placement exist.",
		"Text integration is a separate step after object placement approval.",
		"Only after object placement is approved, add or tune text.",
		"MUST READ BEFORE RESKIN",
		"../../Shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md",
		"Core = behavior",
		"Game skin = game-specific art",
		"Function skin = game-specific presentation for a shared feature",
		"No fallback",
		"SSOT",
		"Owner approved screenshot"
	]:
		passed = passed and _assert_true(workflow.contains(required_text), "Workflow should document %s" % required_text)

	for required_text in [
		"B5A. 9Router Component Call Queue",
		"docs/ui_cyber_9router_component_call_queue.md",
		"Every call must include the base R2 reference pack plus the matching mode/component refs.",
		"Future agents must extend the queue rather than inventing ad hoc prompts."
	]:
		passed = passed and _assert_true(workflow.contains(required_text), "Workflow should document %s" % required_text)

	for required_text in [
		"Portrait and landscape assets must both exist; do not stretch one orientation into the other.",
		"small portrait phone",
		"normal portrait phone",
		"portrait tablet",
		"landscape phone",
		"landscape tablet/desktop",
		"browser/desktop window",
		"Use `background_full_portrait` for portrait aspect families.",
		"Use `background_full_landscape` for landscape and desktop aspect families."
	]:
		passed = passed and _assert_true(workflow.contains(required_text) or language.contains(required_text), "Workflow or design language should document responsive rule %s" % required_text)

	if passed:
		print("test_ui_production_workflow_contract: PASS")
		quit(0)
	else:
		print("test_ui_production_workflow_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
