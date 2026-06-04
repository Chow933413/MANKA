extends WitchState

var is_instructor_mode: bool = false

func enter() -> void:
	var instructor_spot = get_tree().get_root().find_child("InstructorSpot", true, false)
	if instructor_spot:
		witch.global_position = instructor_spot.global_position
	
	print("Witch FSM: Witch defeated! Initiating defeat dialogue sequence.")
	is_instructor_mode = false
	
	# 1. Freeze her completely in space
	witch.velocity = Vector3.ZERO
	
	# 2. TURN OFF her combat Hurtbox immediately
	var witch_hurtbox = witch.get_node_or_null("Hurtbox") 
	if witch_hurtbox:
		witch_hurtbox.monitoring = false
		witch_hurtbox.monitorable = false
		
	# 3. Play her Hurt animation AND make her flash red!
	if witch.animation_player.has_animation("Hurt"):
		witch.animation_player.play("Hurt")
	else:
		witch.animation_player.play("Idle")
		
	# --- NEW: FLASH RED TWEEN EFFECT ---
	# Check if your witch node uses a Sprite3D or CanvasItem
	var witch_sprite = witch.get_node_or_null("Sprite3D") # Change "Sprite3D" to your actual visual node name
	if witch_sprite:
		var tween = create_tween()
		# Instantly snap to pure red, then blend back to standard white over 0.25 seconds
		tween.tween_property(witch_sprite, "modulate", Color(1, 0, 0, 1), 0.05)
		tween.tween_property(witch_sprite, "modulate", Color(1, 1, 1, 1), 0.25)
	
	# 4. Freeze the player right away so they stop and listen
	_freeze_player(true)
	
	await get_tree().create_timer(0.5).timeout
	
	# 5. Play her immediate automatic defeat line
	DialogueManager.start_dialogue(
		"THE WOODLAND WITCH", 
		"Ah... directly to my breaking point! You are... too strong... I yield!"
	)
	
	while DialogueManager.is_dialogue_active:
		await get_tree().physics_frame
		
	if witch.animation_player.has_animation("Idle"):
		witch.animation_player.play("Idle")
		
	# 6. Release the player from the cinematic freeze
	_freeze_player(false)
	
	# Mark her as ready to be spoken to as an instructor!
	is_instructor_mode = true
	print("Witch FSM: Shifting into permanent Instructor mode. Ready for instant talk!")
	
	trigger_interaction() 


# This function is called by your player pressing E via witch.gd's interact()
func trigger_interaction() -> void:
	if not is_instructor_mode: return 

	var interaction_zone = witch.get_node_or_null("InteractionArea")
	var player_is_inside = false
	
	if interaction_zone:
		var overlapping_areas = interaction_zone.get_overlapping_areas()
		for area in overlapping_areas:
			if area.name == "InteractionRange" or area.get_parent().is_in_group("player"):
				player_is_inside = true
				break
				
	if player_is_inside:
		print("Player interacted with Instructor. Starting lesson...")
		_freeze_player(true)
		
		DialogueManager.start_dialogue(
			"THE WOODLAND WITCH (INSTRUCTOR)", 
			"Since your mind is sharper than mine, it is only fair I guide you further. Let me teach you the deep secrets of Word Magic."
		)
		
		while DialogueManager.is_dialogue_active:
			await get_tree().physics_frame
			
		_freeze_player(false)
		print("Lesson completed. Player is free.")


func _freeze_player(should_freeze: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "cinematic_frozen" in player:
			player.cinematic_frozen = should_freeze
		if "controls_active" in player:
			player.controls_active = not should_freeze
			
		if should_freeze and player.has_node("AnimationPlayer"):
			player.get_node("AnimationPlayer").play("Idle")

func physics_update(_delta: float) -> void:
	pass
