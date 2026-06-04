extends WitchState

var player_is_near: bool = false
var dialogue_playing: bool = false

func enter() -> void:
	dialogue_playing = false
	if DialogueManager.has_signal("dialogue_closed"):
		DialogueManager.dialogue_closed.connect(_on_dialogue_closed)
	
	witch.animation_player.play("Idle")
	player_is_near = false
	
	var interaction_zone = witch.get_node("InteractionArea")
	if not interaction_zone.area_entered.is_connected(_on_area_entered):
		interaction_zone.area_entered.connect(_on_area_entered)
	if not interaction_zone.area_exited.is_connected(_on_area_exited):
		interaction_zone.area_exited.connect(_on_area_exited)

func exit() -> void:
	if DialogueManager.has_signal("dialogue_closed") and DialogueManager.dialogue_closed.is_connected(_on_dialogue_closed):
		DialogueManager.dialogue_closed.disconnect(_on_dialogue_closed)
		
	var interaction_zone = witch.get_node("InteractionArea")
	if interaction_zone.area_entered.is_connected(_on_area_entered):
		interaction_zone.area_entered.disconnect(_on_area_entered)
	if interaction_zone.area_exited.is_connected(_on_area_exited):
		interaction_zone.area_exited.disconnect(_on_area_exited)

func handle_hit_during_state() -> void:
	if not dialogue_playing:
		dialogue_playing = true
		
		# Immediately lock the player down so they can't combo attack
		_freeze_player(true)
		
		DialogueManager.start_dialogue(
			"THE WOODLAND WITCH",
			"Nice try, but we need to talk first!"
		)

func trigger_interaction() -> void:
	if player_is_near:
		player_is_near = false 
		start_boss_encounter()
	else:
		handle_hit_during_state()

# Bulletproof freeze utility leveraging LimboHSM and cinematic_frozen
func _freeze_player(should_freeze: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "cinematic_frozen" in player:
			player.cinematic_frozen = should_freeze
			
		if "controls_active" in player:
			player.controls_active = not should_freeze
		
		
		if player.has_node("LimboHSM"):
			var p_state_machine = player.get_node("LimboHSM")
			if should_freeze:
				player.velocity = Vector3.ZERO
				p_state_machine.dispatch("to_locked")
			else:
				p_state_machine.dispatch("to_idle")
				
		if should_freeze and player.has_node("AnimationPlayer"):
			player.get_node("AnimationPlayer").play("Idle")
	
func _on_dialogue_closed() -> void:
	print("Intro State: Dialogue closed! Freezing frame...")
	
	# 1. Assert player lock first so they cannot execute any pending attacks
	_freeze_player(true)
	
	# 2. Shift the Witch out of the intro script immediately
	state_machine.change_state("Phase 1")
			
	# 3. Hold for the cinematic pause frame
	await get_tree().create_timer(1.0).timeout
	
	# 4. Cleanly open up player controls for the real battle
	_freeze_player(false)

func start_boss_encounter() -> void:
	print("Witch FSM: Interaction successful! Loading dialogue.")
	
	_freeze_player(true)
	
	DialogueManager.start_dialogue(
		"THE WOODLAND WITCH", 
		"Halt, traveler! The air grows dark with corruption... Show me you can defend your mind!"
	)
	
	while DialogueManager.is_dialogue_active:
		await get_tree().physics_frame
	
	print("Dialogue complete. Holding frame...")
	
	# Lock player explicitly to decouple from player floor calculations
	_freeze_player(true)
	await witch.teleport_away_from_player(3.0, 5.0)
	# Route the Witch out of intro logic safely
	state_machine.change_state("Phase 1")
			
	await get_tree().create_timer(1.0).timeout
	
	# Drop all restrictions and start the fight!
	_freeze_player(false)
	print("Fight officially started!")

func _on_area_entered(area: Area3D) -> void:
	if area.name == "InteractionRange" or area.get_parent().is_in_group("player"):
		player_is_near = true

func _on_area_exited(area: Area3D) -> void:
	if area.name == "InteractionRange" or area.get_parent().is_in_group("player"):
		player_is_near = false
