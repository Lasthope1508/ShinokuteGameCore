extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Wait for lifetime plus a safety margin, then auto-delete
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
