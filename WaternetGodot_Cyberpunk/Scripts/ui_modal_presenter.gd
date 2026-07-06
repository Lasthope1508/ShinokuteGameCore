extends RefCounted

static func show_leaderboard_modal(parent: Node, popup: Node, theme: ThemeConfig) -> void:
	present_centered_modal(parent, popup, theme)

static func present_centered_modal(parent: Node, popup: Node, theme: ThemeConfig) -> void:
	if parent == null or popup == null or theme == null or not (popup is Control):
		return
	if popup.get_parent() != parent:
		parent.add_child(popup)
	if parent is Control:
		var parent_control := parent as Control
		parent_control.visible = true
		parent_control.mouse_filter = Control.MOUSE_FILTER_STOP
	var control := popup as Control
	var viewport_size := _resolve_viewport_size(parent)
	var width_ratio := theme.ui_modal_landscape_width_ratio if viewport_size.x > viewport_size.y else theme.ui_modal_width_ratio
	var height_ratio := theme.ui_modal_landscape_height_ratio if viewport_size.x > viewport_size.y else theme.ui_modal_height_ratio
	var modal_width: float = viewport_size.x * width_ratio
	var modal_height: float = viewport_size.y * height_ratio
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = -modal_width * 0.5
	control.offset_right = modal_width * 0.5
	control.offset_top = -modal_height * 0.5
	control.offset_bottom = modal_height * 0.5
	if popup.has_method("apply_generated_ui_theme"):
		popup.apply_generated_ui_theme(theme)

static func hide_modal_root(parent: Node) -> void:
	if parent == null:
		return
	if parent is Control:
		(parent as Control).visible = false
	for child in parent.get_children():
		child.queue_free()

static func _resolve_viewport_size(node: Node) -> Vector2:
	if node.get_viewport() != null:
		return node.get_viewport().get_visible_rect().size
	return Vector2(720.0, 1280.0)
