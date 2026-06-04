extends WitchState

var attack_timer: float = 0.0
var time_between_attacks: float = 4.0
var teleport_cooldown: float = 0.0

func enter() -> void:
	witch.animation_player.play("Idle")
	attack_timer = 1.5
	
func physics_update(delta: float) -> void:
	if teleport_cooldown > 0:
		teleport_cooldown -= delta
	
	if teleport_cooldown <= 0:
		# Check distance: if player is within 3.5 units, 30% chance to teleport
		try_teleport_away(1.0, 0.3)
		
		teleport_cooldown = 2.0
	
	attack_timer += delta
	if attack_timer >= time_between_attacks:
		attack_timer = 0.0
		cast_trap()
		
func cast_trap() -> void:
	witch.animation_player.play("Cast Spell")
	await get_tree().create_timer(0.3).timeout
	
	if state_machine.current_state != self: return
	
	if witch.word_trap_scene:
		var trap = witch.word_trap_scene.instantiate()
		get_tree(). current_scene.add_child(trap)
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			trap.global_position = Vector3(player.global_position.x, player.global_position.y - 0.5, player.gloabal_position.z)
		
