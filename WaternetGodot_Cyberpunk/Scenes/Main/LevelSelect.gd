extends Control

@onready var grid_center: CenterContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridCenter
@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridCenter/GridContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var back_btn: Button = $MarginContainer/VBoxContainer/BackBtn

# Pagination UI references
@onready var pagination_hbox: HBoxContainer = $MarginContainer/VBoxContainer/HBoxPagination
@onready var prev_page_btn: Button = $MarginContainer/VBoxContainer/HBoxPagination/PrevPageBtn
@onready var page_label: Label = $MarginContainer/VBoxContainer/HBoxPagination/PageLabel
@onready var next_page_btn: Button = $MarginContainer/VBoxContainer/HBoxPagination/NextPageBtn

var levels_per_page := 0
var current_page := 0

func _ready() -> void:
	# Register theme changes
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.active_theme_name, ThemeManager.active_theme)
	
	_populate_levels_grid()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_music()

func _on_theme_changed(name: String, config: ThemeConfig) -> void:
	$Background.color = config.panel_bg_color
	if title_label:
		title_label.add_theme_color_override("font_color", config.text_color)
		title_label.add_theme_font_size_override("font_size", config.ui_level_select_title_font_size)
	if page_label:
		page_label.add_theme_color_override("font_color", config.text_color)
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", config.ui_level_select_gap)
	if pagination_hbox:
		pagination_hbox.add_theme_constant_override("separation", config.ui_level_select_pagination_gap)
		
	levels_per_page = config.levels_per_page
	
	if grid_container:
		grid_container.columns = config.grid_columns
		grid_container.add_theme_constant_override("h_separation", config.ui_level_select_grid_h_separation)
		grid_container.add_theme_constant_override("v_separation", config.ui_level_select_grid_v_separation)
		grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if grid_center:
		grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	var margin_container = $MarginContainer as MarginContainer
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_right", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(config.menu_margin_y))
		margin_container.add_theme_constant_override("margin_bottom", int(config.menu_margin_y))
		
	if back_btn:
		back_btn.custom_minimum_size.x = config.menu_button_width
		back_btn.custom_minimum_size.y = config.utility_button_height
		back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
	if prev_page_btn:
		prev_page_btn.custom_minimum_size.x = config.ui_level_select_pagination_button_width
		prev_page_btn.custom_minimum_size.y = config.utility_button_height
		
	if next_page_btn:
		next_page_btn.custom_minimum_size.x = config.ui_level_select_pagination_button_width
		next_page_btn.custom_minimum_size.y = config.utility_button_height

func _populate_levels_grid() -> void:
	# Clear existing grid children
	for child in grid_container.get_children():
		child.queue_free()
		
	# Find max unlocked level
	var max_unlocked = 1
	if has_node("/root/SaveManager"):
		max_unlocked = SaveManager.get_setting("max_unlocked_level_id", 1)
	
	# Determine page bounds
	var theme: ThemeConfig = ThemeManager.active_theme
	if levels_per_page <= 0:
		levels_per_page = theme.levels_per_page
	var start_lvl = current_page * levels_per_page + 1
	var end_lvl = start_lvl + levels_per_page - 1
	
	page_label.text = "PAGE %d (%d-%d)" % [current_page + 1, start_lvl, end_lvl]
	
	# Enable/Disable page buttons
	prev_page_btn.disabled = current_page == 0
	
	# If first level of next page is locked, next page is disabled
	var next_page_first_lvl = (current_page + 1) * levels_per_page + 1
	next_page_btn.disabled = next_page_first_lvl > max_unlocked
	
	# Populate buttons for this page
	var btn_size = theme.level_button_size
	var btn_font_size = theme.ui_level_select_button_font_size
	var locked_alpha = theme.ui_level_select_locked_alpha
	for lvl_id in range(start_lvl, end_lvl + 1):
		var btn = Button.new()
		btn.text = str(lvl_id)
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.add_theme_font_size_override("font_size", btn_font_size)
		
		# If level is locked, disable it
		if lvl_id > max_unlocked:
			btn.disabled = true
			btn.modulate.a = locked_alpha
		else:
			btn.pressed.connect(_on_level_selected.bind(lvl_id))
			
		grid_container.add_child(btn)

func _on_level_selected(level_id: int) -> void:
	GameState.current_level_id = level_id
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Gameplay/GameScene.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScene.tscn")

func _on_prev_page_btn_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_populate_levels_grid()

func _on_next_page_btn_pressed() -> void:
	current_page += 1
	_populate_levels_grid()

func _on_back_btn_pressed() -> void:
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/MainMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/MainMenu.tscn")
