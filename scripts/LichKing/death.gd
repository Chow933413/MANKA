extends BossState

func enter() -> void:
	if not actor: return
	
	print("[BOSS] Lich King has fallen! Executing dramatic death monologue...")
	
	actor.velocity = Vector3.ZERO
	var boss_hurtbox = actor.get_node_or_null("Hurtbox")
	if boss_hurtbox:
		boss_hurtbox.set_deferred("monitoring", false)
		boss_hurtbox.set_deferred("monitorable", false)
		
	if actor.player and "controls_active" in actor.player:
		actor.player.controls_active = false
		if actor.player.has_node("LimboHSM"):
			actor.player.state_machine.dispatch("to_idle")
		
	_execute_coded_death()

func _execute_coded_death() -> void:
	var sprite = actor.sprite
	if not sprite:
		_cleanup_and_release_player()
		return

	var original_sprite_pos = sprite.position
	
	
	var shake_tween = actor.create_tween()
	for i in range(10):
		var random_offset = Vector3(randf_range(-0.15, 0.15), randf_range(-0.05, 0.05), 0)
		shake_tween.tween_property(sprite, "position", original_sprite_pos + random_offset, 0.05)
	
	shake_tween.tween_property(sprite, "position", original_sprite_pos, 0.05)
	await shake_tween.finished
	
	
	sprite.modulate = Color(0.4, 0.8, 1.0, 1.0)
	
	DialogueManager.start_dialogue("THE LICH KING", "Graaaah! Impossible... defeated by a mere mortal...")
	while DialogueManager.is_dialogue_active:
		await actor.get_tree().physics_frame
		
	DialogueManager.start_dialogue("THE LICH KING", "Do not rejoice... My death changes nothing. The darkness... is already here...")
	while DialogueManager.is_dialogue_active:
		await actor.get_tree().physics_frame

	var fade_tween = actor.create_tween().set_parallel(true)
	
	# Fade out completely to nothing
	fade_tween.tween_property(sprite, "modulate", Color(0.2, 0.7, 1.0, 0.0), 1.0)
	
	# Expand scale like a bursting magical bubble
	var target_scale = sprite.scale * 1.5
	fade_tween.tween_property(sprite, "scale", target_scale, 1.0)
	
	await fade_tween.finished
	
	_cleanup_and_release_player()

func _cleanup_and_release_player() -> void:
	print("[BOSS] Death monologue complete. Preparing The End screen...")
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	actor.get_tree().get_root().add_child(canvas_layer)
	
	var end_ui_scene = load("res://scenes/Menu/EndMenu.tscn")
	if end_ui_scene:
		var end_ui_instance = end_ui_scene.instantiate() as Control
		
		end_ui_instance.modulate.a = 0.0
		canvas_layer.add_child(end_ui_instance)
		
		var fade_tween = actor.create_tween()
		fade_tween.tween_property(end_ui_instance, "modulate:a", 1.0, 2.0)
		await fade_tween.finished
		
	else:
		print("[ERROR] Could not find TheEndUI.tscn scene file at the designated path!")

	actor.queue_free()
	print("[SYSTEM] Lich King cleared from map tracking. Ending layout fully operational.")

func physics_update(_delta: float) -> void:
	pass
