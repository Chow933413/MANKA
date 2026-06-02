extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName

# Called when the node enters the scene tree for the first time.
func _enter() -> void:
	animation_player.play(animation)
	
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _update(delta: float) -> void:
	agent.apply_movement(delta)
	agent.update_sprite_direction()
	#agent.check_jump_input()

	# Check not input movement
	if agent.movement_input == Vector2.ZERO:
		get_root().dispatch("to_idle")
