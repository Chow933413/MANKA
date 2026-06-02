extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName

# Called when the node enters the scene tree for the first time.
func _enter() -> void:
	animation_player.play(animation)
	agent.velocity.y = agent.JUMP_VELOCITY
	
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _update(delta: float) -> void:
	agent.apply_movement(delta)
	agent.update_sprite_direction()
	
	if agent.velocity.y < 0 and !agent.is_on_floor():
		get_root().dispatch("to_fall")
