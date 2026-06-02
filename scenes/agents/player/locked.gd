extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName

func _enter() -> void:
	agent.velocity = Vector3.ZERO
	animation_player.play(animation)
	agent.movement_input = Vector2.ZERO
	
func _update(delta: float) -> void:
	agent.velocity = Vector3.ZERO
	
