extends BossState

@export var phase_two_cooldown: float = 2.5 # Faster attack actions loop
var cooldown_timer: float = 0.0
var has_summoned_reinforcements: bool = false
var is_summoning_intro: bool = false

func enter() -> void:
	if actor:
		actor.velocity = Vector3.ZERO
		
	cooldown_timer = phase_two_cooldown
	if not has_summoned_reinforcements:
		is_summoning_intro = true
		has_summoned_reinforcements = true
		
		if actor and actor.animation_player.has_animation("attack"):
			actor.animation_player.play("attack")
			
			# Cleanly wait for the physical wind-up animation to finish playing
			await actor.animation_player.animation_finished
		
		# Safety check: Did he die or get hit while raising his hands?
		if not actor or actor.is_dead: return
		
		# Spawn the minions!
		actor.summon_skeletons()
		
		# Return back to idle frames to signify the summon action is complete
		if actor.animation_player.has_animation("idle"):
			actor.animation_player.play("idle")
			
		is_summoning_intro = false

func physics_update(delta: float) -> void:
	if not actor or actor.is_dead or actor.is_hurt: return
	
	# If he is actively running the intro minion spawn sequence, freeze his combat loop
	if is_summoning_intro: return
	
	# Face the player using our clean Y-axis rotation setup from earlier
	if actor.player:
		var dir_to_player = actor.player.global_position.x - actor.global_position.x
		actor.update_facing_direction(dir_to_player)

	# Process his accelerated attack timers safely
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = phase_two_cooldown
		_execute_phase_two_attack_cycle()

func _execute_phase_two_attack_cycle() -> void:
	# 1. Wind up the attack animation timeline completely
	if actor.animation_player.has_animation("attack"):
		actor.animation_player.play("attack")
		await actor.animation_player.animation_finished
		
	if not actor or actor.is_dead or actor.is_hurt or actor.current_phase != 2: 
		return
		
	# 2. Launch the upgraded skull projectile
	actor.spawn_skull_projectile()
	actor.summon_skeletons()
	
	# 3. Quick recovery break before vanishing
	await actor.get_tree().create_timer(0.4).timeout
	if actor.is_dead or actor.is_hurt or actor.current_phase != 2: return
	
	# 4. Perform the fast range blink
	await actor.teleport_within_range_box(4.0)
	
	if actor.animation_player.has_animation("idle"):
		actor.animation_player.play("idle")
