extends StaticBody3D

@onready var bottom_detector = $BottomDetector
@onready var mesh = $Mesh
@onready var particles = $Particles
@onready var cleanup_timer := Timer.new()

var exploded = false

func _ready():
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = 1.0
	cleanup_timer.timeout.connect(queue_free)
	add_child(cleanup_timer)
	bottom_detector.body_entered.connect(_on_bottom_hit)

func _on_bottom_hit(body: Node3D) -> void:
	if body.is_in_group("player"):
		explode()

func explode():
	
	if exploded:
		return
		
	exploded = true
	
	Audio.play_event("break") # Play sound
	
	particles.restart()
	
	mesh.hide()
	$CollisionShape3D.set_deferred("disabled", true)
	bottom_detector.set_deferred("monitoring", false)
	
	cleanup_timer.start()
