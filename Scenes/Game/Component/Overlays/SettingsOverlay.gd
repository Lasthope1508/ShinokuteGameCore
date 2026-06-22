## Modal settings panel: volume sliders, optional Restart / Main Menu buttons,
## Close. Inherits the elastic animation from ElasticOverlay.gd.
## Set `show_game_actions = true` BEFORE open() to reveal the gameplay actions.
extends "res://Scenes/Common/ElasticOverlay.gd"

# Caller handles scene changes via these signals.
signal restart_requested
signal main_menu_requested

@export var show_game_actions: bool = false

@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/VBox/SfxRow/SfxSlider
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
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	close_button.pressed.connect(_on_close_pressed)
	restart_button.visible = show_game_actions
	main_menu_button.visible = show_game_actions


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
