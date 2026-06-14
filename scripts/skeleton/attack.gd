extends SkeletonState

func enter() -> void:
	_execute_attack()

func _execute_attack() -> void:
	if not actor or actor.is_dead: return
	
	actor.velocity.x = 0
	actor.velocity.z = 0
	
	# Double check orientation instantly before locking physics movement down
	if actor.player:
		var dir_x = actor.player.global_position.x - actor.global_position.x
		actor.update_facing_direction(dir_x)
		
	actor.play_animation("attack")
	
	if actor.animation_player:
		await actor.animation_player.animation_finished
	
	if not actor.is_dead and not actor.is_hurt:
		state_machine.change_state("chase")
