extends SkeletonState

func enter() -> void:
	_process_hurt_stun()

func _process_hurt_stun() -> void:
	if not actor or actor.is_dead: return
	
	# 1. Zero out velocity so they stop moving when struck
	actor.velocity.x = 0
	actor.velocity.z = 0
	
	# 2. Trigger the damage flash effect natively on the sprite mesh
	var tween = create_tween()
	tween.tween_property(actor.sprite, "modulate", Color(1, 0, 0), 0.1) # Flash solid red
	tween.tween_property(actor.sprite, "modulate", Color(1, 1, 1), 0.1) # Return to white
	
	# 3. Fire off your lowercase animation track
	actor.play_animation("hurt")
	
	# 4. Await structural track completion
	if actor.animation_player and actor.animation_player.has_animation("hurt"):
		await actor.animation_player.animation_finished
	else:
		# Safety fallback if the 'hurt' animation doesn't exist or is missing frames
		await get_tree().create_timer(0.25).timeout
		
	# 5. Hand control back over to your tracking loop if they survived the hit
	if not actor.is_dead:
		state_machine.change_state("chase")
