## Entry-point scene. Triggers the initial fade-in and then routes to the
## main menu. Kept intentionally tiny so it loads instantly on web exports.
extends Control


func _ready() -> void:
	# Give autoloads (and the fade overlay) one frame to settle.
	await get_tree().process_frame
	SceneRouter.fade_in()
	await get_tree().create_timer(0.8).timeout
	SceneRouter.change_scene("res://Scenes/MainMenu/MainMenu.tscn")
