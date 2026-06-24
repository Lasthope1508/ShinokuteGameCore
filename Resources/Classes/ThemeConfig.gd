## Global palette and visual constants for the template. A single instance is
## referenced by Game/HUD/Piece nodes so the user can recolor the whole project
## from the Inspector by editing one .tres asset.
class_name ThemeConfig extends Resource

@export var theme_name: String = ""
@export var theme_title: String = "BLOCK PUZZLE"
@export var theme_subtitle: String = "Classic Edition"
@export var theme_title_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var theme_subtitle_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var block_textures: Array[Texture2D] = []
@export var default_block_texture: Texture2D
@export var piece_slot_texture: Texture2D
@export var logo_texture: Texture2D = preload("res://Assets/Sprites/bloxchain_logo.png")
@export var playboard_scale: float = 1.0

# Shared / SSOT properties loaded from Fruit Theme but declared to avoid resource errors
@export var cell_empty_texture: Texture2D
@export var background_texture: Texture2D
@export var milestone_backgrounds: Array[Texture2D] = []
@export var background_score_step: int = 500
@export var show_background_in_game: bool = false
@export var quadrant_dark_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var quadrant_light_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var cell_empty_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var preview_valid_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var preview_clear_highlight: Color = Color(1.0, 1.0, 1.0, 1.0)

# Theme sound streams
@export var sfx_pick: AudioStream
@export var sfx_drop: AudioStream
@export var sfx_clear: AudioStream
@export var sfx_combo: AudioStream
@export var sfx_invalid: AudioStream
@export var sfx_fail: AudioStream


# Palette used by PieceTray when picking a color for a new piece.
@export var piece_colors: Array[Color] = [
	Color("#7c3aed"), # violet
	Color("#ef4444"), # red
	Color("#22c55e"), # green
	Color("#3b82f6"), # blue
	Color("#f59e0b"), # amber
	Color("#ec4899"), # pink
	Color("#06b6d4"), # cyan
	Color("#eab308"), # yellow
]

# Modulate multiplier applied to blocks after they are placed on the grid
@export var placed_block_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

# Particle visual settings (VFX)
@export var particles_use_cell_color: bool = false
@export var particles_gradient: Gradient
@export var particles_texture: Texture2D
@export var particles_amount: int = 24
@export var particles_spread: float = 180.0
@export var particles_gravity: Vector2 = Vector2(0, 200)
@export var particles_initial_velocity_min: float = 100.0
@export var particles_initial_velocity_max: float = 220.0
@export var particles_scale_min: float = 2.0
@export var particles_scale_max: float = 6.0

@export_group("UI Colors & Style Overrides")
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var accent_color: Color = Color(1.0, 0.78, 0.05) # Yellow/Gold
@export var alert_color: Color = Color(0.95, 0.18, 0.12) # Red

@export var button_normal_bg: Color = Color(0.55, 0.38, 0.22, 1)
@export var button_hover_bg: Color = Color(0.65, 0.48, 0.32, 1)
@export var button_pressed_bg: Color = Color(0.4, 0.28, 0.15, 1)
@export var button_border_color: Color = Color(0.83, 0.69, 0.22, 1)

@export var panel_bg_color: Color = Color(0.18, 0.14, 0.1, 1)
@export var panel_border_color: Color = Color(0.45, 0.35, 0.25, 1)

@export var custom_font: Font = preload("res://Assets/Fonts/Poppins-Bold.ttf")
