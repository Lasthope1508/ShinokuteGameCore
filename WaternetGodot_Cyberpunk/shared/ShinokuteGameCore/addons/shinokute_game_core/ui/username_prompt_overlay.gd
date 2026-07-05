extends CanvasLayer

signal username_submitted(username: String)
signal username_skipped

@onready var name_edit: LineEdit = $Panel/Margin/VBox/NameEdit
@onready var error_label: Label = $Panel/Margin/VBox/ErrorLabel
@onready var skip_button: Button = $Panel/Margin/VBox/Buttons/SkipButton
@onready var confirm_button: Button = $Panel/Margin/VBox/Buttons/ConfirmButton

var profile: Node

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	name_edit.text_submitted.connect(func(_text: String): _on_confirm_pressed())

func configure(player_profile: Node) -> void:
	profile = player_profile
	if profile != null and profile.config != null:
		skip_button.visible = profile.config.allow_skip_username

func _on_confirm_pressed() -> void:
	if profile == null:
		_show_error("Profile service missing.")
		return
	var username := name_edit.text.strip_edges()
	var errors: Array = profile.validate_username(username)
	if not errors.is_empty():
		_show_error(String(errors[0]))
		return
	if profile.commit_username(username):
		username_submitted.emit(username)
		queue_free()
	else:
		_show_error("Could not save username.")

func _on_skip_pressed() -> void:
	if profile == null or not profile.skip_username():
		_show_error("Skip is not available.")
		return
	username_skipped.emit()
	queue_free()

func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
