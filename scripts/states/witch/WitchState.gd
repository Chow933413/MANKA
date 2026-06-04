class_name WitchState
extends Node

var witch: CharacterBody3D
var state_machine: Node

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func physics_update(_delta: float) -> void:
	pass

func try_teleport_away(proximity_threshold: float, chance: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var distance = witch.global_position.distance_to(player.global_position)
	
	# If player is too close, roll the dice
	if distance < proximity_threshold:
		if randf() <= chance:
			print("Witch: Teleporting away to maintain distance!")
			await witch.teleport_away_from_player(3.0, 5.0)
