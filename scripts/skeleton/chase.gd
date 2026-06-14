extends SkeletonState

func physics_update(_delta: float) -> void:
	if not actor or actor.is_dead or actor.is_hurt: return
	
	if DialogueManager.is_dialogue_active:
		actor.play_animation("idle")
		actor.velocity.x = 0
		actor.velocity.z = 0
		return
		
	if not actor.player: return
	
	var target_pos = actor.player.global_position
	var distance = actor.global_position.distance_to(target_pos)
	
	if distance <= actor.attack_range:
		state_machine.change_state("Attack")
		return
		
	var direction = (target_pos - actor.global_position).normalized()
	actor.velocity.x = direction.x * actor.speed
	actor.velocity.z = direction.z * actor.speed
	
	actor.play_animation("walk")
	actor.update_facing_direction(direction.x)
