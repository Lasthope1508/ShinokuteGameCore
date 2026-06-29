class_name ThemeConfig extends Resource

@export_group("Theme Info")
@export var theme_name: String = "default"
@export var theme_title: String = "WATERNET"
@export var theme_subtitle: String = "Connection Puzzle"

@export_group("Brand Colors")
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var accent_color: Color = Color(0.0, 1.0, 1.0, 1.0) # Used for source tile and HUD accent
@export var alert_color: Color = Color(1.0, 0.0, 0.5, 1.0)  # Used for target tile

@export_group("UI Button Styles")
@export var button_normal_bg: Color = Color(0.05, 0.05, 0.1, 1.0)
@export var button_hover_bg: Color = Color(0.1, 0.1, 0.2, 1.0)
@export var button_pressed_bg: Color = Color(0.0, 0.15, 0.3, 1.0)
@export var button_border_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var button_corner_radius: float = 8.0
@export var button_border_width: int = 2

@export_group("UI Panel Styles")
@export var panel_bg_color: Color = Color(0.02, 0.02, 0.06, 1.0)
@export var panel_border_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var popup_corner_radius: float = 8.0
@export var popup_border_width: int = 2

@export_group("Typography")
@export var custom_font: Font

@export_group("Layout Specs")
@export var menu_margin_x: float = 40.0
@export var menu_margin_y: float = 100.0
@export var menu_button_width: float = 300.0
@export var play_button_height: float = 70.0
@export var utility_button_height: float = 50.0
@export var level_button_size: float = 100.0
@export var grid_columns: int = 4
@export var levels_per_page: int = 20
@export var game_top_margin: float = 160.0
@export var game_bottom_margin: float = 200.0
@export var game_side_padding: float = 40.0
@export var pipe_line_width_ratio: float = 0.06
@export var pipe_center_dot_ratio: float = 0.07
@export var arrow_tip_ratio: float = 0.42
@export var arrow_base_ratio: float = 0.18

@export_group("Custom Textures")
@export var cell_bg_texture: Texture2D
@export var pipe_cap_texture: Texture2D
@export var pipe_i_texture: Texture2D
@export var pipe_l_texture: Texture2D
@export var pipe_t_texture: Texture2D
@export var pipe_x_texture: Texture2D
@export var source_texture: Texture2D
@export var target_texture: Texture2D
