extends Area3D

@onready var life_timer: Timer = $LifeTimer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	# Add to the group we check for in player.gd
	add_to_group("ground_trap")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	life_timer.timeout.connect(_on_life_timer_timeout)
	
	# Optional: Start a visual tell (like a glowing ring) here before 
	# turning the collision on, but since it's a scripted one-shot, we keep it active!

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var player = body
		
		if "inventory" in player and "fire_resistance" in player.inventory:
			queue_free()
			return
			
		if has_meta("lethal") and get_meta("lethal") == true:
			# Give a tiny 0.2 second delay so the particle/sprite effect actually renders
			await get_tree().create_timer(0).timeout 
			if player.has_method("die"):
				
				player.die()

func _on_life_timer_timeout() -> void:
	# Clean up the trap scene from memory when it expires
	queue_free()
