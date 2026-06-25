## Top-of-screen overlay showing current/best score and a Settings button.
## Subscribes to GameState signals and animates the score label tweens.
class_name HUD extends Control

signal settings_requested
signal leaderboard_requested
signal replay_pressed

var score_label: Label
var best_label: Label
var settings_button: TextureButton
var leaderboard_button: TextureButton
var replay_button: TextureButton
var bgm_button: TextureButton
var center_capsule: PanelContainer
var best_title: Label
var score_title: Label
var badge_panel: PanelContainer

var level_badge: Label
var progress_bar: ScoreProgressBar
var _score_tween: Tween
var _displayed_score: int = 0


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.best_changed.connect(_on_best_changed)
	GameState.game_reset.connect(_on_game_reset)

	ThemeManager.theme_changed.connect(_on_theme_changed)

	_displayed_score = GameState.current_score
	
	_setup_layout()
	_update_theme_styles()


func _setup_layout() -> void:
	# Hide the original editor-built HBox
	var original_hbox = get_node_or_null("HBox")
	if original_hbox:
		original_hbox.visible = false
		
	# Increase HUD node custom minimum height to support floating mascot pop-out
	custom_minimum_size.y = 240
	
	# Create a MarginContainer to offset the main contents, leaving room at the top
	var hud_margin = MarginContainer.new()
	hud_margin.name = "HUDMarginContainer"
	hud_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_margin.anchors_preset = Control.PRESET_FULL_RECT
	hud_margin.anchor_right = 1.0
	hud_margin.anchor_bottom = 1.0
	hud_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud_margin.grow_vertical = Control.GROW_DIRECTION_BOTH
	hud_margin.add_theme_constant_override("margin_top", 60)
	hud_margin.add_theme_constant_override("margin_bottom", 0)
	hud_margin.add_theme_constant_override("margin_left", 0)
	hud_margin.add_theme_constant_override("margin_right", 0)
	add_child(hud_margin)
	
	# Create a new main HBox container inside the MarginContainer
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "NewMainHBox"
	main_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_margin.add_child(main_hbox)
	
	# Far Left: Settings/Menu Button Container
	var left_margin = MarginContainer.new()
	left_margin.name = "LeftCol"
	left_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	left_margin.add_theme_constant_override("margin_left", 0)
	left_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(left_margin)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.name = "LeftVBox"
	left_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	left_vbox.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_vbox)
	
	var settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsButtonPanel"
	settings_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	settings_panel.custom_minimum_size = Vector2(72, 72)
	settings_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_vbox.add_child(settings_panel)
	
	settings_button = TextureButton.new()
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size = Vector2(72, 72)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_button.texture_normal = preload("res://Assets/Icons/menuList.png")
	settings_button.ignore_texture_size = true
	settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_panel.add_child(settings_button)
	settings_button.pressed.connect(_on_settings_pressed)
	
	var leaderboard_panel = PanelContainer.new()
	leaderboard_panel.name = "LeaderboardButtonPanel"
	leaderboard_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	leaderboard_panel.custom_minimum_size = Vector2(72, 72)
	leaderboard_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_vbox.add_child(leaderboard_panel)
	
	leaderboard_button = TextureButton.new()
	leaderboard_button.name = "LeaderboardButton"
	leaderboard_button.custom_minimum_size = Vector2(72, 72)
	leaderboard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leaderboard_button.texture_normal = preload("res://Assets/Icons/trophy.png")
	leaderboard_button.ignore_texture_size = true
	leaderboard_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	leaderboard_panel.add_child(leaderboard_button)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	
	# Expanding Spacer Left
	var spacer_left = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(spacer_left)
	
	# Center: Capsule Card
	center_capsule = PanelContainer.new()
	center_capsule.name = "CenterCapsule"
	center_capsule.custom_minimum_size = Vector2(420, 125)
	center_capsule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(center_capsule)
	
	# capsule_vbox contains the score containers
	var capsule_vbox = VBoxContainer.new()
	capsule_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	capsule_vbox.add_theme_constant_override("separation", 6)
	center_capsule.add_child(capsule_vbox)
	
	# Mascot Wrapper Control (floating layer on top of the capsule)
	var mascot_wrapper = Control.new()
	mascot_wrapper.name = "MascotWrapper"
	mascot_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_capsule.add_child(mascot_wrapper)
	
	# Mascot Sprite: large 160x160 character popped out of the top
	var mascot_rect = TextureRect.new()
	mascot_rect.name = "MascotRect"
	mascot_rect.custom_minimum_size = Vector2(160, 160)
	mascot_rect.texture = preload("res://Assets/Sprites/mascot_avatar.png")
	mascot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Anchor to top center of the capsule wrapper
	mascot_rect.anchor_left = 0.5
	mascot_rect.anchor_right = 0.5
	mascot_rect.anchor_top = 0.0
	mascot_rect.anchor_bottom = 0.0
	mascot_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mascot_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Position: center horizontally, offset vertically to pop out of the top border
	mascot_rect.offset_left = -80
	mascot_rect.offset_right = 80
	mascot_rect.offset_top = -90
	mascot_rect.offset_bottom = 70
	mascot_wrapper.add_child(mascot_rect)
	
	# Bottom Row: High Score | Spacer | Personal Score
	var bottom_row = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capsule_vbox.add_child(bottom_row)
	
	# 1. High Score (Left side of Bottom Row)
	var best_vbox = VBoxContainer.new()
	best_vbox.custom_minimum_size = Vector2(120, 0)
	best_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	best_vbox.add_theme_constant_override("separation", 2)
	bottom_row.add_child(best_vbox)
	
	var best_title_hbox = HBoxContainer.new()
	best_title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	best_title_hbox.add_theme_constant_override("separation", 4)
	best_vbox.add_child(best_title_hbox)
	
	# Trophy icon next to best title
	var trophy_rect = TextureRect.new()
	trophy_rect.name = "TrophyRect"
	trophy_rect.custom_minimum_size = Vector2(14, 14)
	trophy_rect.texture = preload("res://Assets/Icons/trophy.png")
	trophy_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	best_title_hbox.add_child(trophy_rect)
	
	best_title = Label.new()
	best_title.text = "ALL TIME BEST"
	best_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	best_title.add_theme_font_size_override("font_size", 10)
	best_title_hbox.add_child(best_title)
	
	best_label = Label.new()
	best_label.text = str(GameState.best_score)
	best_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 26)
	best_label.add_theme_constant_override("outline_size", 6)
	best_vbox.add_child(best_label)
	
	# 2. Expanding Spacer (Middle of Bottom Row to clear space for the mascot)
	var spacer_mid = Control.new()
	spacer_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer_mid)
	
	# 3. Personal Score (Right side of Bottom Row)
	var score_vbox = VBoxContainer.new()
	score_vbox.custom_minimum_size = Vector2(120, 0)
	score_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	score_vbox.add_theme_constant_override("separation", 2)
	bottom_row.add_child(score_vbox)
	
	score_title = Label.new()
	score_title.text = "SCORE"
	score_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	score_title.add_theme_font_size_override("font_size", 10)
	score_vbox.add_child(score_title)
	
	score_label = Label.new()
	score_label.text = str(_displayed_score)
	score_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_constant_override("outline_size", 6)
	score_vbox.add_child(score_label)
	
	# Reparent the existing ScoreProgressBar node programmatically to capsule_vbox
	# placing it below bottom_row
	var original_progress_bar = get_node_or_null("../ProgressFrame/ScoreProgressBar")
	if original_progress_bar:
		progress_bar = original_progress_bar
		original_progress_bar.reparent(capsule_vbox)
		
		# Set size flags to stretch horizontally
		original_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		original_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		original_progress_bar.custom_minimum_size = Vector2(0, 20)
		
		# Hide the outer empty ProgressFrame container
		var progress_frame = get_node_or_null("../ProgressFrame")
		if progress_frame:
			progress_frame.visible = false
	
	# Expanding Spacer Right
	var spacer_right = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(spacer_right)
	
	# Far Right: Replay & BGM Buttons Container
	var right_margin = MarginContainer.new()
	right_margin.name = "RightCol"
	right_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	right_margin.add_theme_constant_override("margin_right", 0)
	right_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(right_margin)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.name = "RightVBox"
	right_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	right_vbox.add_theme_constant_override("separation", 10)
	right_margin.add_child(right_vbox)
	
	# BGM Toggle Button Panel
	var bgm_panel = PanelContainer.new()
	bgm_panel.name = "BgmButtonPanel"
	bgm_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	bgm_panel.custom_minimum_size = Vector2(72, 72)
	bgm_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(bgm_panel)
	
	bgm_button = TextureButton.new()
	bgm_button.name = "BgmButton"
	bgm_button.custom_minimum_size = Vector2(72, 72)
	bgm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bgm_button.ignore_texture_size = true
	bgm_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	bgm_panel.add_child(bgm_button)
	
	# Helper function/lambda to update BGM button texture normal
	var update_bgm_texture = func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			if audio_mgr.is_music_muted():
				bgm_button.texture_normal = preload("res://Assets/Icons/musicOff.png")
			else:
				bgm_button.texture_normal = preload("res://Assets/Icons/musicOn.png")
				
	# Initialize texture state
	update_bgm_texture.call()
	
	bgm_button.pressed.connect(func():
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.toggle_music_mute()
			AudioManager.play_sfx("button")
			update_bgm_texture.call()
	)
	
	# Replay Button Panel
	var replay_panel = PanelContainer.new()
	replay_panel.name = "ReplayButtonPanel"
	replay_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	replay_panel.custom_minimum_size = Vector2(72, 72)
	replay_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(replay_panel)
	
	replay_button = TextureButton.new()
	replay_button.name = "ReplayButton"
	replay_button.custom_minimum_size = Vector2(72, 72)
	replay_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	replay_button.texture_normal = preload("res://Assets/Icons/return.png")
	replay_button.ignore_texture_size = true
	replay_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	replay_panel.add_child(replay_button)
	replay_button.pressed.connect(func():
		AudioManager.play_sfx("button")
		replay_pressed.emit()
	)


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if not active_theme:
		return
		
	# 1. Style Capsule background and border using theme colors
	if is_instance_valid(center_capsule):
		var capsule_sb = center_capsule.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if not capsule_sb:
			capsule_sb = StyleBoxFlat.new()
		center_capsule.add_theme_stylebox_override("panel", capsule_sb)
		
		# Semi-transparent theme panel bg for glassmorphic/premium overlay look
		var bg_color = active_theme.panel_bg_color
		bg_color.a = 0.7
		capsule_sb.bg_color = bg_color
		
		capsule_sb.border_color = active_theme.panel_border_color
		var cap_border = active_theme.capsule_border_width
		capsule_sb.border_width_left = cap_border
		capsule_sb.border_width_top = cap_border
		capsule_sb.border_width_right = cap_border
		capsule_sb.border_width_bottom = cap_border
		capsule_sb.set_corner_radius_all(active_theme.capsule_corner_radius)
		capsule_sb.content_margin_left = 16
		capsule_sb.content_margin_right = 16
		capsule_sb.content_margin_top = 12
		capsule_sb.content_margin_bottom = 12
		
	# 2. Style Left/Right Squircle Buttons
	var settings_panel = get_node_or_null("HUDMarginContainer/NewMainHBox/LeftCol/LeftVBox/SettingsButtonPanel")
	var leaderboard_panel = get_node_or_null("HUDMarginContainer/NewMainHBox/LeftCol/LeftVBox/LeaderboardButtonPanel")
	var replay_panel = get_node_or_null("HUDMarginContainer/NewMainHBox/RightCol/RightVBox/ReplayButtonPanel")
	var bgm_panel = get_node_or_null("HUDMarginContainer/NewMainHBox/RightCol/RightVBox/BgmButtonPanel")
	
	for panel_node in [settings_panel, leaderboard_panel, replay_panel, bgm_panel]:
		if is_instance_valid(panel_node):
			var sb = StyleBoxFlat.new()
			var bg_col = active_theme.button_normal_bg
			bg_col.a = 0.7
			sb.bg_color = bg_col
			sb.border_color = active_theme.accent_color
			var btn_border = active_theme.button_border_width
			sb.border_width_left = btn_border
			sb.border_width_top = btn_border
			sb.border_width_right = btn_border
			sb.border_width_bottom = btn_border
			sb.set_corner_radius_all(active_theme.button_corner_radius)
			panel_node.add_theme_stylebox_override("panel", sb)
		
	# Style the trophy icon
	var trophy = get_node_or_null("HUDMarginContainer/NewMainHBox/CenterCapsule/VBoxContainer/HBoxContainer/best_vbox/best_title_hbox/TrophyRect")
	if is_instance_valid(trophy):
		trophy.modulate = active_theme.accent_color
		
	# 3. Style text and label colors
	if is_instance_valid(best_title):
		best_title.add_theme_color_override("font_color", active_theme.text_color)
		best_title.modulate.a = 0.7
	if is_instance_valid(score_title):
		score_title.add_theme_color_override("font_color", active_theme.text_color)
		score_title.modulate.a = 0.7
		
	if is_instance_valid(best_label):
		best_label.add_theme_color_override("font_color", active_theme.accent_color)
		best_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
		best_label.add_theme_constant_override("outline_size", 6)
		
	if is_instance_valid(score_label):
		score_label.add_theme_color_override("font_color", active_theme.text_color)
		score_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.6))
		score_label.add_theme_constant_override("outline_size", 6)
		
	# Ensure the button textures modulate to white so they look crisp
	if is_instance_valid(settings_button):
		settings_button.modulate = Color.WHITE
	if is_instance_valid(leaderboard_button):
		leaderboard_button.modulate = Color.WHITE
	if is_instance_valid(replay_button):
		replay_button.modulate = Color.WHITE
	if is_instance_valid(bgm_button):
		bgm_button.modulate = Color.WHITE


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _on_score_changed(new_score: int, _delta: int) -> void:
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_method(_set_displayed_score, _displayed_score, new_score, 0.4)


func _set_displayed_score(value: float) -> void:
	_displayed_score = int(round(value))
	if is_instance_valid(score_label):
		score_label.text = str(_displayed_score)


func _on_best_changed(new_best: int) -> void:
	if is_instance_valid(best_label):
		best_label.text = str(new_best)


func _on_game_reset() -> void:
	_displayed_score = 0
	if is_instance_valid(score_label):
		score_label.text = "0"
	if is_instance_valid(best_label):
		best_label.text = str(GameState.best_score)


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button")
	settings_requested.emit()


func _on_leaderboard_pressed() -> void:
	AudioManager.play_sfx("button")
	leaderboard_requested.emit()


