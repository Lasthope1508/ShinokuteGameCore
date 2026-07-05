extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const THEME_CONFIG_PATH := "res://Resources/Classes/ThemeConfig.gd"
const UI_TEXT_LAYOUT_PATH := "res://Scripts/ui_text_layout.gd"
const LEADERBOARD_POPUP_SCRIPT := "res://Scenes/Common/LeaderboardPopup.gd"
const WORKFLOW_DOC_PATH := "res://docs/ui_production_workflow.md"
const DESIGN_DOC_PATH := "res://docs/ui_design_language.md"
const CHECKLIST_DOC_PATH := "res://docs/ui_gameplay_layout_checklist.md"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var theme_source := FileAccess.get_file_as_string(THEME_CONFIG_PATH)
	var layout_source := FileAccess.get_file_as_string(UI_TEXT_LAYOUT_PATH)
	var leaderboard_source := FileAccess.get_file_as_string(LEADERBOARD_POPUP_SCRIPT)
	var workflow_doc := FileAccess.get_file_as_string(WORKFLOW_DOC_PATH)
	var design_doc := FileAccess.get_file_as_string(DESIGN_DOC_PATH)
	var checklist_doc := FileAccess.get_file_as_string(CHECKLIST_DOC_PATH)

	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(FileAccess.file_exists(UI_TEXT_LAYOUT_PATH), "UiTextLayout helper should exist")
	passed = passed and _assert_true(theme_source.contains("ui_text_roles"), "ThemeConfig should own text role SSOT")
	passed = passed and _assert_true(layout_source.contains("apply_label_role"), "UiTextLayout should expose label role application")
	passed = passed and _assert_true(layout_source.contains("fit_label_font_to_owner"), "UiTextLayout should expose font fitting")
	passed = passed and _assert_true(leaderboard_source.contains("UiTextLayout.apply_label_role"), "Leaderboard rows should use canonical text layout helper")
	passed = passed and _assert_true(workflow_doc.contains("Text Layout Gate"), "UI workflow should document Text Layout Gate")
	passed = passed and _assert_true(design_doc.contains("Text Layout Gate"), "UI design language should document Text Layout Gate")
	passed = passed and _assert_true(checklist_doc.contains("Text Layout Gate"), "UI checklist should track Text Layout Gate")

	if theme != null:
		var raw_roles = theme.get("ui_text_roles")
		var roles: Dictionary = raw_roles if raw_roles is Dictionary else {}
		passed = passed and _assert_true(not roles.is_empty(), "Theme should expose text role dictionary")
		passed = passed and _assert_true(roles.has("leaderboard_empty_state"), "Theme should define leaderboard empty text role")
		passed = passed and _assert_true(roles.has("leaderboard_title"), "Theme should define leaderboard title text role")
		passed = passed and _assert_true(roles.has("leaderboard_status"), "Theme should define leaderboard status text role")
		passed = passed and _assert_true(roles.has("leaderboard_score_row"), "Theme should define leaderboard score row text role")
		var label := Label.new()
		label.text = "No scores submitted yet."
		root.add_child(label)
		var UiTextLayout = load(UI_TEXT_LAYOUT_PATH)
		if UiTextLayout != null:
			UiTextLayout.apply_label_role(label, theme, "leaderboard_empty_state", Vector2(260.0, 36.0))
			passed = passed and _assert_true(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Empty state should center text")
			passed = passed and _assert_true((label.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL, "Empty state should fill owner width")
			passed = passed and _assert_true(label.clip_text, "Empty state should clip inside owner rect")
			passed = passed and _assert_true(label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "Empty state should ellipsize if needed")
		root.remove_child(label)
		label.free()

	if passed:
		print("test_ui_text_layout_gate: PASS")
		quit(0)
	else:
		print("test_ui_text_layout_gate: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
