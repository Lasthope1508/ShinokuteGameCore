## Title screen with a Play button. Settings and Best score are reachable
## from here so the user can tweak audio before starting the first run.
extends Control

const GAME_SCENE_PATH := "res://Scenes/Game/Game.tscn"
const SETTINGS_OVERLAY := preload("res://Scenes/Game/Component/Overlays/SettingsOverlay.tscn")

# Branding shown in the bottom-left corner of the menu.
@export var project_name: String = "Block Puzzle Template"
@export var version: String = "1.0.0"

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var settings_button: Button = $Center/VBox/SettingsButton
@onready var best_label: Label = $Center/VBox/BestLabel
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	best_label.text = "Best Score:\n %d" % GameState.best_score
	version_label.text = "%s v%s" % [project_name, version]
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	GameState.best_changed.connect(func(value: int) -> void:
		best_label.text = "Best: %d" % value
	)


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button")
	SceneRouter.change_scene(GAME_SCENE_PATH)


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button")
	var overlay := SETTINGS_OVERLAY.instantiate()
	add_child(overlay)
	overlay.open()
