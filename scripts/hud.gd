extends Control

func _on_coin_collected(coins):
	$Coins.text = str(coins)

func _on_level_started(level_index: int, _display_name: String, _difficulty_tier: int) -> void:
	var level_label := get_node_or_null("Level") as Label
	if level_label != null:
		level_label.text = "LEVEL %s" % str(level_index + 1)
