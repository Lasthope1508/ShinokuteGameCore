## Modal settings panel: volume sliders, optional Restart / Main Menu buttons,
## Close. Inherits the elastic animation from ElasticOverlay.gd.
## Set `show_game_actions = true` BEFORE open() to reveal the gameplay actions.
extends "res://Scenes/Common/ElasticOverlay.gd"

# Caller handles scene changes via these signals.
signal restart_requested
signal main_menu_requested

@export var show_game_actions: bool = false

var _previous_skin_index: int = 0
var _pending_skin_index: int = 0
@onready var _confirm_overlay: Control = $ConfirmOverlay

@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/VBox/SfxRow/SfxSlider
@onready var theme_button: OptionButton = $Panel/Margin/VBox/ThemeRow/ThemeButton
@onready var name_input: LineEdit = $Panel/Margin/VBox/UsernameRow/LineEdit
@onready var save_name_button: Button = $Panel/Margin/VBox/UsernameRow/SaveNameButton
@onready var restart_button: Button = $Panel/Margin/VBox/RestartButton
@onready var main_menu_button: Button = $Panel/Margin/VBox/MainMenuButton
@onready var close_button: TextureButton = $Panel/CloseButton


func _ready() -> void:
	# Fully opaque dim — no transparency over the underlying screen.
	dim_alpha = 1.0
	super()
	music_slider.value = AudioManager.get_bus_volume(AudioManager.BUS_MUSIC)
	sfx_slider.value = AudioManager.get_bus_volume(AudioManager.BUS_SFX)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Populate themes
	theme_button.clear()
	theme_button.add_item("Fruits") # index 0
	theme_button.add_item("Brick")  # index 1
	var current_skin = ThemeManager.get_active_skin()
	if current_skin == "brick":
		theme_button.selected = 1
	else:
		theme_button.selected = 0
	theme_button.item_selected.connect(_on_theme_selected)
	
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	close_button.pressed.connect(_on_close_pressed)
	save_name_button.pressed.connect(_on_save_name_pressed)
	restart_button.visible = show_game_actions
	main_menu_button.visible = show_game_actions

	# Load current username
	var username = SaveManager.get_username()
	if username == "":
		username = "Player_%s" % SaveManager.get_device_uuid().substr(0, 5)
		SaveManager.set_username(username)
	name_input.text = username

	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme_styles()
	
	panel.custom_minimum_size = Vector2(440, 540)
	panel.size = Vector2(440, 540)
	
	# Initialize confirm overlay
	_confirm_overlay.visible = false
	_confirm_overlay.get_node("CenterContainer/ConfirmPanel/Margin/VBox/ButtonsRow/BtnYes").pressed.connect(_on_confirm_yes)
	_confirm_overlay.get_node("CenterContainer/ConfirmPanel/Margin/VBox/ButtonsRow/BtnNo").pressed.connect(_on_confirm_cancel)

	# Dynamic Country Row creation
	var country_row = HBoxContainer.new()
	country_row.name = "CountryRow"
	country_row.add_theme_constant_override("separation", 12)
	
	var country_lbl = Label.new()
	country_lbl.name = "CountryLabel"
	country_lbl.custom_minimum_size = Vector2(80, 0)
	country_lbl.text = "Region"
	country_row.add_child(country_lbl)
	
	# Flag Icon
	var flag_icon = TextureRect.new()
	flag_icon.name = "FlagIcon"
	flag_icon.custom_minimum_size = Vector2(40, 40)
	flag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	flag_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Apply circular mask shader
	var shader = load("res://Assets/Shaders/circular_mask.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		flag_icon.material = mat
		
	country_row.add_child(flag_icon)
	
	# Option Button
	var country_btn = OptionButton.new()
	country_btn.name = "CountryButton"
	country_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	country_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	country_row.add_child(country_btn)
	
	# Populate Option Button
	var countries_dict = {
		"VN": {"name": "Vietnam", "continent": "AS", "flag": "res://Assets/Flags/vn.png"},
		"US": {"name": "United States", "continent": "NA", "flag": "res://Assets/Flags/us.png"},
		"JP": {"name": "Japan", "continent": "AS", "flag": "res://Assets/Flags/jp.png"},
		"KR": {"name": "South Korea", "continent": "AS", "flag": "res://Assets/Flags/kr.png"},
		"SG": {"name": "Singapore", "continent": "AS", "flag": "res://Assets/Flags/sg.png"},
		"GB": {"name": "United Kingdom", "continent": "EU", "flag": "res://Assets/Flags/gb.png"},
		"DE": {"name": "Germany", "continent": "EU", "flag": "res://Assets/Flags/de.png"},
		"FR": {"name": "France", "continent": "EU", "flag": "res://Assets/Flags/fr.png"},
		"CA": {"name": "Canada", "continent": "NA", "flag": "res://Assets/Flags/ca.png"},
		"AU": {"name": "Australia", "continent": "OC", "flag": "res://Assets/Flags/au.png"}
	}
	
	var current_code = SaveManager.get_country_code()
	if current_code == "":
		current_code = "VN" # default fallback
		
	var current_index = -1
	var keys = countries_dict.keys()
	
	for i in range(keys.size()):
		var key = keys[i]
		var c_data = countries_dict[key]
		country_btn.add_item(c_data["name"])
		country_btn.set_item_metadata(i, key)
		if key == current_code:
			current_index = i
			
	if current_index == -1 and current_code != "":
		var custom_name = SaveManager.get_country_name()
		if custom_name == "":
			custom_name = current_code
		var idx = country_btn.item_count
		country_btn.add_item(custom_name)
		country_btn.set_item_metadata(idx, current_code)
		current_index = idx
		
	country_btn.selected = current_index
	
	var update_flag_texture = func(code: String):
		var flag_path = "res://Assets/Flags/un.png" # default UN flag
		if countries_dict.has(code):
			flag_path = countries_dict[code]["flag"]
		if ResourceLoader.exists(flag_path):
			flag_icon.texture = load(flag_path)
			
	update_flag_texture.call(current_code)
	
	if SaveManager.is_country_changed_manually():
		country_btn.disabled = true
		country_btn.tooltip_text = "Country can only be changed once"
	else:
		country_btn.item_selected.connect(func(index):
			var selected_code = country_btn.get_item_metadata(index)
			var selected_data = countries_dict.get(selected_code, {"name": country_btn.get_item_text(index), "continent": "AS"})
			
			SaveManager.set_country_code(selected_code)
			SaveManager.set_country_name(selected_data["name"])
			SaveManager.set_continent_code(selected_data["continent"])
			SaveManager.set_country_changed_manually(true)
			
			update_flag_texture.call(selected_code)
			country_btn.disabled = true
			
			LeaderboardManager.player_country_code = selected_code
			LeaderboardManager.player_country_name = selected_data["name"]
			LeaderboardManager.player_continent_code = selected_data["continent"]
			LeaderboardManager.geolocation_resolved.emit()
			
			SaveManager.set_last_submitted_score(0)
			var best = SaveManager.get_best_score()
			if best > 0:
				LeaderboardManager.submit_score(best)
		)
		
	var vbox = $Panel/Margin/VBox
	var theme_row = $Panel/Margin/VBox/ThemeRow
	vbox.add_child(country_row)
	vbox.move_child(country_row, theme_row.get_index() + 1)



func _on_theme_selected(index: int) -> void:
	AudioManager.play_sfx("button")
	var current_skin = ThemeManager.get_active_skin()
	var current_index = 1 if current_skin == "brick" else 0
	
	if current_index == index:
		return
		
	if show_game_actions:
		# Mid-game: show confirmation prompt before applying
		_pending_skin_index = index
		_previous_skin_index = current_index
		_show_confirm_dialog()
	else:
		# Main menu: apply immediately
		_apply_skin_change(index)


func _show_confirm_dialog() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = active_theme.panel_bg_color
		panel_style.border_color = active_theme.accent_color
		panel_style.set_border_width_all(4)
		panel_style.set_corner_radius_all(12)
		$ConfirmOverlay/CenterContainer/ConfirmPanel.add_theme_stylebox_override("panel", panel_style)
		
		var label = $ConfirmOverlay/CenterContainer/ConfirmPanel/Margin/VBox/Label
		label.text = "Changing the skin will reset your current game.\n\nDo you want to restart?"
		label.add_theme_color_override("font_color", active_theme.text_color)
		if active_theme.custom_font:
			label.add_theme_font_override("font", active_theme.custom_font)
			
		var btn_yes = $ConfirmOverlay/CenterContainer/ConfirmPanel/Margin/VBox/ButtonsRow/BtnYes
		if active_theme.custom_font:
			btn_yes.add_theme_font_override("font", active_theme.custom_font)
		
		var yes_normal = StyleBoxFlat.new()
		yes_normal.bg_color = active_theme.alert_color
		yes_normal.border_color = active_theme.alert_color.lightened(0.2)
		yes_normal.set_border_width_all(2)
		yes_normal.set_corner_radius_all(8)
		btn_yes.add_theme_stylebox_override("normal", yes_normal)
		
		var yes_hover = StyleBoxFlat.new()
		yes_hover.bg_color = active_theme.alert_color.lightened(0.1)
		yes_hover.border_color = active_theme.alert_color.lightened(0.3)
		yes_hover.set_border_width_all(2)
		yes_hover.set_corner_radius_all(8)
		btn_yes.add_theme_stylebox_override("hover", yes_hover)
		
		var btn_no = $ConfirmOverlay/CenterContainer/ConfirmPanel/Margin/VBox/ButtonsRow/BtnNo
		if active_theme.custom_font:
			btn_no.add_theme_font_override("font", active_theme.custom_font)
			
		var no_normal = StyleBoxFlat.new()
		no_normal.bg_color = active_theme.button_normal_bg
		no_normal.border_color = active_theme.button_border_color
		no_normal.set_border_width_all(2)
		no_normal.set_corner_radius_all(8)
		btn_no.add_theme_stylebox_override("normal", no_normal)
		
		var no_hover = StyleBoxFlat.new()
		no_hover.bg_color = active_theme.button_hover_bg
		no_hover.border_color = active_theme.button_border_color
		no_hover.set_border_width_all(2)
		no_hover.set_corner_radius_all(8)
		btn_no.add_theme_stylebox_override("hover", no_hover)
		
	_confirm_overlay.visible = true


func _on_confirm_yes() -> void:
	AudioManager.play_sfx("button")
	_confirm_overlay.visible = false
	
	# Apply theme
	_apply_skin_change(_pending_skin_index)
	
	# Close settings overlay and trigger restart
	await close()
	restart_requested.emit()


func _on_confirm_cancel() -> void:
	AudioManager.play_sfx("button")
	_confirm_overlay.visible = false
	
	# Revert option button selection to previous
	theme_button.selected = _previous_skin_index


func _apply_skin_change(index: int) -> void:
	if index == 0:
		ThemeManager.set_active_skin("fruits")
	else:
		ThemeManager.set_active_skin("brick")


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		var title_node = get_node_or_null("Panel/Margin/VBox/Title")
		if title_node:
			title_node.add_theme_color_override("font_color", active_theme.accent_color)
			title_node.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			title_node.add_theme_constant_override("outline_size", 16)
		
		var music_label = get_node_or_null("Panel/Margin/VBox/MusicRow/MusicLabel")
		if music_label:
			music_label.add_theme_color_override("font_color", active_theme.text_color)
			music_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			music_label.add_theme_constant_override("outline_size", 8)
			
		var sfx_label = get_node_or_null("Panel/Margin/VBox/SfxRow/SfxLabel")
		if sfx_label:
			sfx_label.add_theme_color_override("font_color", active_theme.text_color)
			sfx_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			sfx_label.add_theme_constant_override("outline_size", 8)
			
		var theme_label = get_node_or_null("Panel/Margin/VBox/ThemeRow/ThemeLabel")
		if theme_label:
			theme_label.add_theme_color_override("font_color", active_theme.text_color)
			theme_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			theme_label.add_theme_constant_override("outline_size", 8)
			
		var username_label = get_node_or_null("Panel/Margin/VBox/UsernameRow/UsernameLabel")
		if username_label:
			username_label.add_theme_color_override("font_color", active_theme.text_color)
			username_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			username_label.add_theme_constant_override("outline_size", 8)

		if name_input:
			name_input.add_theme_color_override("font_color", active_theme.text_color)
			var input_style = name_input.get_theme_stylebox("normal") as StyleBoxFlat
			if not input_style:
				input_style = StyleBoxFlat.new()
				name_input.add_theme_stylebox_override("normal", input_style)
			input_style.bg_color = active_theme.panel_bg_color.darkened(0.2)
			input_style.border_color = active_theme.panel_border_color.darkened(0.4)
			input_style.border_width_left = 1
			input_style.border_width_right = 1
			input_style.border_width_top = 1
			input_style.border_width_bottom = 1

		if theme_button:
			theme_button.add_theme_color_override("font_color", active_theme.text_color)
			theme_button.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))

		# Style dynamic country labels
		var country_lbl = get_node_or_null("Panel/Margin/VBox/CountryRow/CountryLabel")
		if country_lbl:
			country_lbl.add_theme_color_override("font_color", active_theme.text_color)
			country_lbl.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
			country_lbl.add_theme_constant_override("outline_size", 8)
			
		var country_btn = get_node_or_null("Panel/Margin/VBox/CountryRow/CountryButton")
		if country_btn:
			country_btn.add_theme_color_override("font_color", active_theme.text_color)
			country_btn.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))



func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, value)
	AudioManager.play_sfx("button")


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button")
	await close()
	restart_requested.emit()


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button")
	await close()
	main_menu_requested.emit()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("button")
	close()


func _on_save_name_pressed() -> void:
	var new_name = name_input.text.strip_edges()
	if new_name == "":
		return
		
	SaveManager.set_username(new_name)
	
	# Submit best score with the new name!
	var best = SaveManager.get_best_score()
	if best > 0:
		LeaderboardManager.submit_score(best)
	else:
		LeaderboardManager.submit_score(0)
		
	# Visual confirmation
	save_name_button.disabled = true
	save_name_button.text = "Saved!"
	
	await get_tree().create_timer(1.5).timeout
	save_name_button.disabled = false
	save_name_button.text = "Save"
	AudioManager.play_sfx("button")
