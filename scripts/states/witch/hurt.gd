extends WitchState

@export var hurt_stun_duration: float = 2.0

var stun_timer: float = 0.0
var is_routing_phase: bool = false
var flash_tween: Tween

func enter() -> void:
	witch.is_invulnerable = true
	
	stun_timer = 0.0
	is_routing_phase = false # Reset this so she can route health gates on future hits!
	
	if witch.animation_player.has_animation("Hurt"):
		witch.animation_player.play("Hurt")
	witch.velocity = Vector3.ZERO
	
	_flash_red()
	
func physics_update(delta: float) -> void:
	if is_routing_phase: return
	
	stun_timer += delta
	if stun_timer >= hurt_stun_duration:
		is_routing_phase = true
		determine_next_phase()
		
func exit() -> void:
	witch.is_invulnerable = false
	
	# Clean up the tween if she exits the state early
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		
	# Ensure her color is perfectly reset when leaving the state
	var sprite = witch.get_node_or_null("Sprite3D")
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0)

func determine_next_phase() -> void:
	if witch.current_health <= 0:
		var instructor_spot = get_tree().get_root().find_child("InstructorSpot", true, false)
		if instructor_spot:
			await witch.teleport_to(instructor_spot.global_position)
		
		state_machine.change_state("Dead")
		return
	
	if witch.current_health == 2:
		_freeze_player(true)
		DialogueManager.start_dialogue(
			"THE WOODLAND WITCH",
			"Ouch! Good strike... Let's see how you handle my word traps!"
		)
		
		while DialogueManager.is_dialogue_active:
			await get_tree().physics_frame
			
		
		_freeze_player(false)
		state_machine.change_state("Phase 2") 
		return
		
	elif witch.current_health == 1:
		_freeze_player(true)
		DialogueManager.start_dialogue(
			"THE WOODLAND WITCH",
			"Insolent fool! You've driven me to my limit! Feel the full force of my magic!"
		)
		
		while DialogueManager.is_dialogue_active:
			await get_tree().physics_frame
		
		
		_freeze_player(false)
		# FIX 3: Removed space
		state_machine.change_state("Phase 3")
		
func _freeze_player(should_freeze: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "controls_active" in player:
			player.controls_active = not should_freeze
			
		if should_freeze and player.has_node("AnimationPlayer"):
			player.get_node("AnimationPlayer").play("Idle")
			
func _flash_red() -> void:
	# FIX 2: Find the sprite relative to the witch node
	var sprite = witch.get_node_or_null("Sprite3D") # Double check if your sprite is named "Sprite3D"
	if not sprite: return
	
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		
	flash_tween = create_tween()
	# Turns HDR glow red in 0.05 seconds
	flash_tween.tween_property(sprite, "modulate", Color(5.0, 0.2, 0.2), 0.1)
	# Fades beautifully back to normal in 0.15 seconds
	flash_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.15)
