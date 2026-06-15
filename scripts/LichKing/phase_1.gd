extends BossState

@export var action_cooldown: float = 3.0
var cooldown_timer: float = 0.0

func enter() -> void:
	_execute_phase_one_attack_cycle()

func physics_update(delta: float) -> void:
	if not actor or actor.is_dead or actor.is_hurt: return
	
	# Face the player using our brand new rotation matrix
	if actor.player:
		var dir_to_player = actor.player.global_position.x - actor.global_position.x
		actor.update_facing_direction(dir_to_player)

	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = action_cooldown
		_execute_phase_one_attack_cycle()

func _execute_phase_one_attack_cycle() -> void:
	# 1. Cast Skull Spell
	if actor.animation_player.has_animation("attack"):
		actor.animation_player.play("attack")
		await actor.animation_player.animation_finished
	
	if not actor or actor.is_dead or actor.is_hurt or actor.current_phase != 1: 
		return
		
	actor.spawn_skull_projectile()
	if actor and actor.animation_player.has_animation("idle"):
		actor.animation_player.play("idle")
	
	# Wait brief recovery frames before blinking away
	await actor.get_tree().create_timer(0.5).timeout
	if actor.is_dead or actor.current_phase != 1: return
	
	# 2. Teleport away cleanly
	await actor.teleport_within_range_box(5.0)
	
	if actor.animation_player.has_animation("idle"):
		actor.animation_player.play("idle")
