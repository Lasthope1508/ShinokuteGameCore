extends Node3D

signal goal_reached(body: Node)

@onready var goal_area: Area3D = $GoalArea

func _ready() -> void:
	goal_area.body_entered.connect(_on_goal_area_body_entered)

func _on_goal_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		goal_reached.emit(body)
