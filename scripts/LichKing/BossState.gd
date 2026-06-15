extends Node
class_name BossState

var actor: CharacterBody3D     # Stores the root skeleton link
var state_machine: Node       # Stores the StateMachine link

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
