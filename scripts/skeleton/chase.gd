extends SkeletonState

func physics_update(_delta: float) -> void:
	if not actor or actor.is_dead or actor.is_hurt: return
	
	if DialogueManager.is_dialogue_active:
		actor.play_animation("idle")
		actor.velocity.x = 0
		actor.velocity.z = 0
		return
		
	# If player walks completely outside the Area3D bubble, break chase and go back to Idle
	if not actor.player_target: 
		state_machine.change_state("idle")
		return
	
	var target_pos = actor.player_target.global_position
	var distance = actor.global_position.distance_to(target_pos)
	
	# Switch to attack if we are close enough
	if distance <= actor.attack_range:
		state_machine.change_state("attack") # Match standard lowercase naming lookup keys
		return
		
	# Clean vector calculation pointing direct TOWARD the target player
	var direction = (target_pos - actor.global_position).normalized()
	actor.velocity.x = direction.x * actor.speed
	actor.velocity.z = direction.z * actor.speed
	
	actor.play_animation("walk")
	actor.update_facing_direction(direction.x)
