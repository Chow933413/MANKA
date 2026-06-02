extends LimboState

@export var animation_player: AnimationPlayer
@export var animation: StringName

# Called when the node enters the scene tree for the first time.
func _enter() -> void:
	animation_player.play(animation)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _update(delta: float) -> void:
	await animation_player.animation_finished
	if is_active():
		get_root().dispatch(EVENT_FINISHED)
