extends Control

const UiModalPresenter = preload("res://Scripts/ui_modal_presenter.gd")
const LEADERBOARD_POPUP_SCENE_PATH := "res://Scenes/Common/LeaderboardPopup.tscn"
const PROFILE_POPUP_SCENE_PATH := "res://Scenes/Common/ProfilePopup.tscn"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/SubtitleLabel
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var logo_rect: TextureRect = $MarginContainer/VBoxContainer/LogoRect
@onready var play_btn: Button = $MarginContainer/VBoxContainer/PlayBtn
@onready var leader_btn: Button = $MarginContainer/VBoxContainer/LeaderboardBtn
@onready var mute_btn: Button = $MarginContainer/VBoxContainer/HBoxVolume/MuteBtn

var modal_overlay_root: Control

func _ready() -> void:
	modal_overlay_root = _ensure_modal_overlay_root()
	# Register theme change signal
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.active_theme_name, ThemeManager.active_theme)
	
	# Load volume states
	_update_mute_button()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_music()
	if has_node("/root/GameCoreManager"):
		if not GameCoreManager.username_required.is_connected(_on_username_required):
			GameCoreManager.username_required.connect(_on_username_required)
		GameCoreManager.ensure_profile_ready()

func _on_theme_changed(_theme_name: String, config: ThemeConfig) -> void:
	if title_label:
		title_label.text = "GLYPHFLOW ARRAYS"
		title_label.add_theme_color_override("font_color", config.text_color)
		title_label.add_theme_font_size_override("font_size", config.ui_main_menu_title_font_size)
	if subtitle_label:
		subtitle_label.text = config.theme_subtitle.to_upper()
		subtitle_label.add_theme_color_override("font_color", config.accent_color)
		subtitle_label.add_theme_font_size_override("font_size", config.ui_main_menu_subtitle_font_size)
		
	var copyright_label = get_node_or_null("MarginContainer/VBoxContainer/CopyrightLabel")
	if copyright_label:
		copyright_label.add_theme_color_override("font_color", config.text_color.darkened(0.2))
		copyright_label.add_theme_font_size_override("font_size", config.ui_main_menu_copyright_font_size)
		
	# Redraw background ColorRect
	$Background.color = config.panel_bg_color
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", config.ui_main_menu_gap)
	if logo_rect:
		logo_rect.custom_minimum_size = Vector2(config.ui_main_menu_logo_size, config.ui_main_menu_logo_size)
	
	# Apply dynamic layout dimensions from ThemeConfig SSOT
	var margin_container = $MarginContainer as MarginContainer
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_right", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(config.menu_margin_y))
		margin_container.add_theme_constant_override("margin_bottom", int(config.menu_margin_y))
		
	if play_btn:
		play_btn.custom_minimum_size.x = config.menu_button_width
		play_btn.custom_minimum_size.y = config.play_button_height
		play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		play_btn.add_theme_font_size_override("font_size", config.ui_main_menu_primary_button_font_size)
		
	if leader_btn:
		leader_btn.custom_minimum_size.x = config.menu_button_width
		leader_btn.custom_minimum_size.y = config.ui_main_menu_secondary_button_height
		leader_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		leader_btn.add_theme_font_size_override("font_size", config.ui_main_menu_secondary_button_font_size)
		
	if mute_btn:
		mute_btn.custom_minimum_size.x = config.menu_button_width
		mute_btn.custom_minimum_size.y = config.utility_button_height
		mute_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mute_btn.add_theme_font_size_override("font_size", config.ui_main_menu_secondary_button_font_size)

func _on_play_btn_pressed() -> void:
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/LevelSelect.tscn")

func _on_leaderboard_btn_pressed() -> void:
	show_leaderboard_modal()

func show_leaderboard_modal() -> void:
	var popup_scene: PackedScene = load(LEADERBOARD_POPUP_SCENE_PATH) as PackedScene
	if popup_scene == null:
		return
	_clear_modal_overlay()
	var popup := popup_scene.instantiate()
	if popup.has_signal("dismissed"):
		popup.connect("dismissed", Callable(self, "_on_modal_dismissed"))
	UiModalPresenter.show_leaderboard_modal(modal_overlay_root, popup, ThemeManager.active_theme)

func show_profile_modal() -> void:
	var popup_scene: PackedScene = load(PROFILE_POPUP_SCENE_PATH) as PackedScene
	if popup_scene == null:
		return
	_clear_modal_overlay()
	var popup := popup_scene.instantiate()
	if popup.has_signal("dismissed"):
		popup.connect("dismissed", Callable(self, "_on_modal_dismissed"))
	UiModalPresenter.present_centered_modal(modal_overlay_root, popup, ThemeManager.active_theme)

func _on_username_required() -> void:
	show_profile_modal()

func _on_modal_dismissed() -> void:
	UiModalPresenter.hide_modal_root(modal_overlay_root)

func _clear_modal_overlay() -> void:
	if modal_overlay_root == null:
		modal_overlay_root = _ensure_modal_overlay_root()
	for child in modal_overlay_root.get_children():
		child.queue_free()
	modal_overlay_root.visible = false

func _ensure_modal_overlay_root() -> Control:
	var existing := get_node_or_null("ModalOverlayRoot")
	if existing is Control:
		return existing as Control
	var root := Control.new()
	root.name = "ModalOverlayRoot"
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.anchor_left = 0.0
	root.anchor_top = 0.0
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	add_child(root)
	return root

func _on_mute_btn_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.toggle_master_mute()
		_update_mute_button()

func _update_mute_button() -> void:
	if has_node("/root/AudioManager") and mute_btn:
		var is_muted = AudioManager.is_master_muted()
		mute_btn.text = "VOLUME: MUTED" if is_muted else "VOLUME: ON"
