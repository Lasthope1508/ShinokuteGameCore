class_name ShinokuteFunctionOverlayGroup
extends RefCounted

const META_GROUP := "shinokute_function_overlay_group"

static func register_panel(panel: CanvasItem, group_name: String) -> void:
	if panel == null:
		return
	panel.set_meta(META_GROUP, group_name)

static func disable_gameplay_button_focus(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		var button := root as Button
		button.focus_mode = Control.FOCUS_NONE
	for child in root.get_children():
		disable_gameplay_button_focus(child)

static func toggle_panel(panel: CanvasItem, group_name: String) -> void:
	if panel == null:
		return
	if panel.visible:
		hide_panel(panel)
	else:
		show_panel(panel, group_name)

static func show_panel(panel: CanvasItem, group_name: String) -> void:
	if panel == null:
		return
	register_panel(panel, group_name)
	_hide_peer_panels(panel, group_name)
	panel.visible = true
	release_ui_focus(panel)

static func hide_panel(panel: CanvasItem) -> void:
	if panel == null:
		return
	panel.visible = false
	release_ui_focus(panel)

static func release_ui_focus(owner: Node) -> void:
	if owner == null:
		return
	var viewport := owner.get_viewport()
	if viewport != null:
		viewport.gui_release_focus()

static func _hide_peer_panels(panel: CanvasItem, group_name: String) -> void:
	var parent := panel.get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		if child == panel or not child is CanvasItem:
			continue
		if String(child.get_meta(META_GROUP, "")) == group_name:
			(child as CanvasItem).visible = false
