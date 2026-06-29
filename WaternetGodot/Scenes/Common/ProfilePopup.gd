extends PanelContainer

@onready var username_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxEdit/UsernameEdit
@onready var score_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ScoreList
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	# Load current username
	if has_node("/root/SaveManager"):
		username_edit.text = SaveManager.get_username()
		
	# Register leaderboard loaded signal
	if has_node("/root/LeaderboardManager"):
		LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
		status_label.text = "LOADING LEADERBOARD..."
		LeaderboardManager.fetch_leaderboard("world", "classic")
	else:
		status_label.text = "LEADERBOARD NOT AVAILABLE"

func _on_leaderboard_loaded(tab: String, scores: Array, mode: String) -> void:
	status_label.text = "WORLD LEADERBOARD:"
	
	# Clear list
	for child in score_list.get_children():
		child.queue_free()
		
	if scores.is_empty():
		var lbl = Label.new()
		lbl.text = "No scores submitted yet."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_list.add_child(lbl)
		return
		
	# Add score items
	var rank = 1
	for item in scores:
		var name = item.get("username", "Unknown")
		var val = int(item.get("score", 0))
		
		var lbl = Label.new()
		lbl.text = "%d. %s - %d moves" % [rank, name, val]
		lbl.add_theme_font_size_override("font_size", 18)
		score_list.add_child(lbl)
		rank += 1

func _on_save_btn_pressed() -> void:
	var new_name = username_edit.text.strip_edges()
	if new_name == "":
		status_label.text = "USERNAME CANNOT BE EMPTY"
		return
		
	if has_node("/root/SaveManager"):
		SaveManager.set_username(new_name)
		status_label.text = "SAVED! RE-SUBMITTING SCORES..."
		
		# Submit high score again with new username
		var best = SaveManager.get_best_score("classic")
		if has_node("/root/LeaderboardManager"):
			LeaderboardManager.submit_score(best, "classic")
			LeaderboardManager.fetch_leaderboard("world", "classic")
		status_label.text = "PROFILE SAVED!"

func _on_close_btn_pressed() -> void:
	queue_free()
