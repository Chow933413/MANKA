extends Area3D

# Type whatever text you want to pop up in the Inspector panel!
@export var alert_text: String = "!!!"

# We track this so the trigger only fires once
var has_triggered: bool = false

signal player_crossed_trigger # Let the Level Root know if you still need it

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if has_triggered: return
	
	if body.is_in_group("player"):
		has_triggered = true
		
		# Pass the text directly to the player's alert system!
		if body.has_method("play_alert_animation"):
			body.play_alert_animation(alert_text)
			
		# Emit a signal so your level root script can still trigger Phase 1 or Phase 2
		player_crossed_trigger.emit()
		
		# Optional: turn off monitoring to save physics processing
		monitoring = false
