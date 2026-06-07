extends Area3D

func _ready() -> void:
	# Connect the body entered signal to detect the player character
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D) -> void:
	# Match your player group name check
	if body.is_in_group("player"):
		if body.has_method("reset_to_safe_ground"):
			body.reset_to_safe_ground()
