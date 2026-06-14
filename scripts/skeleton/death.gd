extends SkeletonState

func enter() -> void:
	_execute_death()

func _execute_death() -> void:
	if not actor: return
	
	# 1. Freeze all remaining physics velocity entirely
	actor.velocity = Vector3.ZERO
	
	# 2. Fire off your lowercase death animation track
	actor.play_animation("death")
	
	# 3. Disable all collision logic so the player doesn't trip on a dead body
	var hurtbox = actor.get_node_or_null("HurtBox")
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		
	if actor.sword_hitbox:
		actor.sword_hitbox.set_deferred("monitoring", false)
		actor.sword_hitbox.set_deferred("monitorable", false)
		
	if actor.animation_player and actor.animation_player.has_animation("death"):
		await actor.animation_player.animation_finished
	else:
		# Safety fallback if the 'death' track doesn't exist
		await get_tree().create_timer(1.0).timeout
		
	# 4. Create a clean visual fade-out tween
	if actor.sprite:
		var tween = create_tween()
		# Wait half a second for the death animation to look natural, then fade out over 0.75 seconds
		tween.tween_property(actor.sprite, "modulate:a", 0.0, 0.75).set_delay(0.5)
		await tween.finished
		
	# 5. Safely delete the enemy node from your level tree completely
	actor.queue_free()
