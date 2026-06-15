extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_boss_trigger_line_body_entered(body: Node3D) -> void:
# Check if it's the player stepping through the gate
	if body.is_in_group("player") or body.name == "Player":
		# Find the Lich King in your scene tree
		var boss = get_node_or_null("LichKing") # Change this path to match your map tree layout!
		if boss and boss.has_method("start_boss_fight"):
			boss.start_boss_fight()
			
			# Turn off this trigger line so it doesn't accidentally fire twice!
			$BossTriggerLine.queue_free()
