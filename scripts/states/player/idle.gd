extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName

# Called when the node enters the scene tree for the first time.
func _enter() -> void:
	animation_player.play(animation)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _update(delta: float) -> void:
	#agent.check_jump_input()
	agent.check_attack_input()
	
	if agent.movement_input != Vector2.ZERO:
		get_root().dispatch("to_move")
