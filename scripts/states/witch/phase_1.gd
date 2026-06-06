extends WitchState

var attack_timer: float = 5.0
var time_between_attacks: float = 4.0
var teleport_cooldown: float = 0.0

func enter() -> void:
	witch.animation_player.play("Idle")
	attack_timer = 4.0
	
func physics_update(delta: float) -> void:
		
	attack_timer += delta
	if attack_timer >= time_between_attacks:
		attack_timer = 0.0
		cast_spark()
		
func cast_spark() -> void:
	witch.animation_player.play("Cast Spell")
	
	await get_tree().create_timer(0.9).timeout
	
	if state_machine.current_state != self: return
	
	if witch.magic_spark_scene:
		var spark = witch.magic_spark_scene.instantiate()
		get_tree().current_scene.add_child(spark)
		spark.global_position = witch.projectile_spawn.global_position
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			spark.look_at(player.global_position)
