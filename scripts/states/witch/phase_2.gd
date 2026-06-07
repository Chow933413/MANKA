extends WitchState


func enter() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		state_machine.change_state("Phase 1")
		return
	
	# 1. PLAYER HAS THE POTION (Fast casting loop, no talking)
	if "inventory" in player and "Fire Potion" in player.inventory:
		print("Witch Phase 2: Player has Fire Potion! Spawning harmless trap.")
		
		# Ensure her hurtbox is active and she can be hit
		witch.is_invulnerable = false
		
		# Play casting animation and spawn the trap instantly
		witch.animation_player.play("Ground Spell")
		await get_tree().create_timer(0.8).timeout
		
		if state_machine.current_state != self: return
		
		_spawn_visual_trap(player.global_position)
		witch.animation_player.play("Idle")
		print("Witch Phase 2: Trap spawned. Waiting for player to strike!")
		
	# 2. PLAYER DOES NOT HAVE POTION (Instant Kill)
	else:
		print("Witch Phase 2: No potion! Initiating instant-kill sequence.")
		witch.animation_player.play("Ground Spell")
		await get_tree().create_timer(0.8).timeout
		
		_spawn_visual_trap(player.global_position)
		
		if player.has_method("die"):
			player.current_health_units = 0
			player.die()

func _spawn_visual_trap(target_position: Vector3) -> void:
	if witch.word_trap_scene:
		var trap = witch.word_trap_scene.instantiate()
		trap.add_to_group("ground_trap")
		get_tree().current_scene.add_child(trap)
		trap.global_position = Vector3(
			target_position.x, 
			target_position.y - 0.35, 
			target_position.z
		)
