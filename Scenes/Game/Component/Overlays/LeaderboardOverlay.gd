## Controller for the regional leaderboard overlay. Displays top 15 ranks
## divided into World, Continent, and Country tabs.
extends Control

@onready var close_button: TextureButton = $Panel/CloseButton
@onready var world_tab: Button = $Panel/Margin/VBox/Tabs/WorldTab
@onready var continent_tab: Button = $Panel/Margin/VBox/Tabs/ContinentTab
@onready var country_tab: Button = $Panel/Margin/VBox/Tabs/CountryTab
@onready var scroll_list: VBoxContainer = $Panel/Margin/VBox/RankingScroll/List
@onready var loading_label: Label = $Panel/Margin/VBox/LoadingLabel
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel

var active_tab: String = "world"

func _ready() -> void:
	# Clean list
	for child in scroll_list.get_children():
		child.queue_free()
		
	# Connections
	close_button.pressed.connect(_on_close_pressed)
	
	world_tab.pressed.connect(func(): _select_tab("world"))
	continent_tab.pressed.connect(func(): _select_tab("continent"))
	country_tab.pressed.connect(func(): _select_tab("country"))
	
	LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	
	# Display detected location
	_update_region_display()
	LeaderboardManager.geolocation_resolved.connect(_update_region_display)
	
	_update_my_highest()
		
	# Connect resize
	resized.connect(_on_resized)
	_on_resized()
	
	# Initial fetch
	_select_tab("world")
	
	# Apply style overrides to match our design system
	_apply_styles()


func _update_region_display() -> void:
	var country = LeaderboardManager.player_country_name
	var continent = LeaderboardManager.player_continent_code
	if country != "":
		status_label.text = "Your Region: %s (%s)" % [country, continent]
		continent_tab.text = "Continent"
		country_tab.text = "Country"
	else:
		status_label.text = "Detecting region..."
	_update_my_highest()


func _apply_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if not active_theme:
		return
		
	# Set panel container theme colors (Deep Space Indigo background, Neon Orchid borders)
	var panel: PanelContainer = $Panel
	var panel_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not panel_style:
		panel_style = StyleBoxFlat.new()
		panel.add_theme_stylebox_override("panel", panel_style)
		
	panel_style.bg_color = active_theme.panel_bg_color
	panel_style.border_color = active_theme.panel_border_color
	var border_w = active_theme.popup_border_width
	panel_style.border_width_left = border_w
	panel_style.border_width_right = border_w
	panel_style.border_width_top = border_w
	panel_style.border_width_bottom = border_w
	panel_style.set_corner_radius_all(active_theme.popup_corner_radius)
	
	# Style MyHighestRow panel container
	var my_row: PanelContainer = $Panel/Margin/VBox/MyHighestRow
	var my_row_style = StyleBoxFlat.new()
	my_row_style.bg_color = active_theme.accent_color
	my_row_style.bg_color.a = 0.20 # 20% opacity for distinction
	my_row_style.border_color = active_theme.accent_color
	my_row_style.border_width_left = 2
	my_row_style.border_width_right = 2
	my_row_style.border_width_top = 2
	my_row_style.border_width_bottom = 2
	my_row_style.set_corner_radius_all(active_theme.inner_button_corner_radius)
	my_row.add_theme_stylebox_override("panel", my_row_style)
	
	# Style labels in MyHighestRow
	var my_rank_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/RankLabel
	var my_name_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/NameLabel
	var my_score_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/ScoreLabel
	my_rank_lbl.add_theme_color_override("font_color", active_theme.accent_color)
	my_name_lbl.add_theme_color_override("font_color", active_theme.text_color)
	my_score_lbl.add_theme_color_override("font_color", active_theme.accent_color)
	my_rank_lbl.custom_minimum_size = Vector2(110, 0)
	
	# Style tabs (purple backdrop, cyan borders)
	for tab_btn in [world_tab, continent_tab, country_tab]:
		tab_btn.add_theme_color_override("font_color", active_theme.text_color)
		tab_btn.add_theme_color_override("font_hover_color", active_theme.accent_color)
		



func _on_resized() -> void:
	var parent_size = size
	var max_w = parent_size.x - 40.0
	var max_h = parent_size.y - 120.0
	var min_panel_size = $Panel.get_combined_minimum_size()
	var panel_width = clamp(min_panel_size.x, 480.0, max_w)
	var panel_height = clamp(min_panel_size.y, 760.0, max_h)
	$Panel.custom_minimum_size = Vector2(panel_width, panel_height)
	$Panel.size = Vector2(panel_width, panel_height)
	$Panel.position = (parent_size - Vector2(panel_width, panel_height)) * 0.5


func _select_tab(tab: String) -> void:
	active_tab = tab
	loading_label.visible = true
	loading_label.text = "Loading..."
	
	# Clear previous list items
	for child in scroll_list.get_children():
		child.queue_free()
		
	# Update tab visual indicators
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		world_tab.add_theme_color_override("font_color", active_theme.accent_color if tab == "world" else active_theme.text_color)
		var is_continent = (tab == "continent")
		var is_country = (tab == "country")
		continent_tab.add_theme_color_override("font_color", active_theme.accent_color if is_continent else active_theme.text_color)
		country_tab.add_theme_color_override("font_color", active_theme.accent_color if is_country else active_theme.text_color)
		
	# Trigger query
	LeaderboardManager.fetch_leaderboard(tab)
	AudioManager.play_sfx("button")


func _on_leaderboard_loaded(tab: String, scores: Array) -> void:
	if tab != active_tab:
		return
		
	loading_label.visible = false
	
	# Clear previous list items in case of rapid clicks
	for child in scroll_list.get_children():
		child.queue_free()
		
	if scores.is_empty():
		loading_label.text = "No scores found."
		loading_label.visible = true
		return
		
	# Populate list
	var active_theme = ThemeManager.get_active_theme()
	
	var rank_idx = 1
	for entry in scores:
		var item := HBoxContainer.new()
		item.custom_minimum_size = Vector2(0, 56)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Inner padding container
		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		item.add_child(margin)
		
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(hbox)
		
		# Check if current entry is the player
		var is_current_player = (entry["username"] == SaveManager.get_username() and entry["score"] == SaveManager.get_best_score())
		
		# Create rank block container
		var rank_container := HBoxContainer.new()
		rank_container.custom_minimum_size = Vector2(110, 0)
		rank_container.add_theme_constant_override("separation", 8)
		
		var rank_lbl := Label.new()
		rank_lbl.text = "%d." % rank_idx
		rank_lbl.theme_type_variation = "HeaderSmall"
		rank_container.add_child(rank_lbl)
		
		# Trophy texture if rank 1, 2, 3
		if rank_idx in [1, 2, 3]:
			var trophy_icon := TextureRect.new()
			trophy_icon.texture = preload("res://Assets/Icons/trophy.png")
			trophy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trophy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trophy_icon.custom_minimum_size = Vector2(24, 24)
			trophy_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			if rank_idx == 1:
				trophy_icon.modulate = Color("#FFD700") # Gold
			elif rank_idx == 2:
				trophy_icon.modulate = Color("#E0E0E0") # Silver
			elif rank_idx == 3:
				trophy_icon.modulate = Color("#CD7F32") # Bronze
			rank_container.add_child(trophy_icon)
			
		hbox.add_child(rank_container)
		
		# Username Label
		var name_lbl := Label.new()
		name_lbl.text = entry["username"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true
		
		# Add country suffix to name if present
		if entry["country_code"] != "" and tab != "country":
			name_lbl.text += " (%s)" % entry["country_code"]
		hbox.add_child(name_lbl)
		
		# Score Label
		var score_lbl := Label.new()
		score_lbl.text = str(entry["score"])
		score_lbl.custom_minimum_size = Vector2(90, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(score_lbl)
		
		# Apply premium styling for Top 1, 2, 3
		if rank_idx == 1:
			# Gold Rank text
			rank_lbl.add_theme_color_override("font_color", Color("#FFF3A3"))
			rank_lbl.add_theme_color_override("font_outline_color", Color("#7C5900"))
			rank_lbl.add_theme_constant_override("outline_size", 6)
			
			# Gold Name & Score text
			name_lbl.add_theme_color_override("font_color", Color("#FFD700"))
			name_lbl.add_theme_color_override("font_outline_color", Color("#5A4000"))
			name_lbl.add_theme_constant_override("outline_size", 4)
			
			score_lbl.add_theme_color_override("font_color", Color("#FFD700"))
			score_lbl.add_theme_color_override("font_outline_color", Color("#5A4000"))
			score_lbl.add_theme_constant_override("outline_size", 4)
			
		elif rank_idx == 2:
			# Silver Rank text
			rank_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
			rank_lbl.add_theme_color_override("font_outline_color", Color("#4A4A4A"))
			rank_lbl.add_theme_constant_override("outline_size", 6)
			
			# Silver Name & Score text
			name_lbl.add_theme_color_override("font_color", Color("#E0E0E0"))
			name_lbl.add_theme_color_override("font_outline_color", Color("#3A3A3A"))
			name_lbl.add_theme_constant_override("outline_size", 4)
			
			score_lbl.add_theme_color_override("font_color", Color("#E0E0E0"))
			score_lbl.add_theme_color_override("font_outline_color", Color("#3A3A3A"))
			score_lbl.add_theme_constant_override("outline_size", 4)
			
		elif rank_idx == 3:
			# Bronze Rank text
			rank_lbl.add_theme_color_override("font_color", Color("#FFE6D5"))
			rank_lbl.add_theme_color_override("font_outline_color", Color("#7D3E15"))
			rank_lbl.add_theme_constant_override("outline_size", 6)
			
			# Bronze Name & Score text
			name_lbl.add_theme_color_override("font_color", Color("#D27D2D"))
			name_lbl.add_theme_color_override("font_outline_color", Color("#4A240E"))
			name_lbl.add_theme_constant_override("outline_size", 4)
			
			score_lbl.add_theme_color_override("font_color", Color("#D27D2D"))
			score_lbl.add_theme_color_override("font_outline_color", Color("#4A240E"))
			score_lbl.add_theme_constant_override("outline_size", 4)
			
		else:
			if active_theme:
				rank_lbl.add_theme_color_override("font_color", active_theme.accent_color)
				name_lbl.add_theme_color_override("font_color", active_theme.text_color)
				score_lbl.add_theme_color_override("font_color", active_theme.accent_color)

		# Wrap item in a PanelContainer if it is top 3 OR current player
		if rank_idx in [1, 2, 3] or is_current_player:
			var bg_style := StyleBoxFlat.new()
			bg_style.border_width_left = 2
			bg_style.border_width_right = 2
			bg_style.border_width_top = 2
			bg_style.border_width_bottom = 2
			bg_style.set_corner_radius_all(active_theme.inner_button_corner_radius)
			
			if rank_idx == 1:
				bg_style.bg_color = Color("#FFD700", 0.08)
				bg_style.border_color = Color("#FFD700", 0.90 if is_current_player else 0.40)
				if is_current_player:
					bg_style.border_width_left = 3
					bg_style.border_width_right = 3
					bg_style.border_width_top = 3
					bg_style.border_width_bottom = 3
			elif rank_idx == 2:
				bg_style.bg_color = Color("#E0E0E0", 0.08)
				bg_style.border_color = Color("#E0E0E0", 0.90 if is_current_player else 0.35)
				if is_current_player:
					bg_style.border_width_left = 3
					bg_style.border_width_right = 3
					bg_style.border_width_top = 3
					bg_style.border_width_bottom = 3
			elif rank_idx == 3:
				bg_style.bg_color = Color("#CD7F32", 0.08)
				bg_style.border_color = Color("#CD7F32", 0.90 if is_current_player else 0.35)
				if is_current_player:
					bg_style.border_width_left = 3
					bg_style.border_width_right = 3
					bg_style.border_width_top = 3
					bg_style.border_width_bottom = 3
			else:
				if active_theme:
					bg_style.bg_color = active_theme.accent_color
					bg_style.bg_color.a = 0.15
					bg_style.border_color = active_theme.accent_color
					bg_style.set_corner_radius_all(active_theme.inner_button_corner_radius)
				bg_style.border_width_left = 2
				bg_style.border_width_right = 2
				bg_style.border_width_top = 2
				bg_style.border_width_bottom = 2
				
			var panel_item := PanelContainer.new()
			panel_item.add_theme_stylebox_override("panel", bg_style)
			panel_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.remove_child(margin)
			panel_item.add_child(margin)
			item.add_child(panel_item)
			
		scroll_list.add_child(item)
		rank_idx += 1
		
	# Try to find current player's rank in loaded scores
	var player_rank = -1
	var entry_idx = 1
	for entry in scores:
		if entry["username"] == SaveManager.get_username() and entry["score"] == SaveManager.get_best_score():
			player_rank = entry_idx
			break
		entry_idx += 1
		
	var my_rank_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/RankLabel
	if player_rank != -1:
		my_rank_lbl.text = "Rank #%d:" % player_rank
	else:
		my_rank_lbl.text = "My Best:"


func _update_my_highest() -> void:
	# Ensure the node exists in case of early calls
	if not has_node("Panel/Margin/VBox/MyHighestRow"):
		return
	var my_name_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/NameLabel
	var my_score_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/ScoreLabel
	var my_rank_lbl: Label = $Panel/Margin/VBox/MyHighestRow/Margin/HBox/RankLabel
	
	var username = SaveManager.get_username()
	var country_code = LeaderboardManager.player_country_code
	if country_code != "":
		my_name_lbl.text = "%s (%s)" % [username, country_code]
	else:
		my_name_lbl.text = username
		
	var best_score = SaveManager.get_best_score()
	my_score_lbl.text = str(best_score)
	my_rank_lbl.text = "My Best:"


func _on_close_pressed() -> void:
	AudioManager.play_sfx("button")
	queue_free()
