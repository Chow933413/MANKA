extends SkeletonState

func physics_update(_delta: float) -> void:
	if not actor or actor.is_dead or actor.is_hurt: return
	
	# Keep momentum completely zeroed out
	actor.velocity.x = 0
	actor.velocity.z = 0
	actor.play_animation("idle")
	
	# If the vision area bubble signals found a player target, swap to chase!
	if actor.player_target != null:
		state_machine.change_state("chase")
