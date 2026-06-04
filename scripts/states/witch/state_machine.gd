extends Node

@export var initial_state: WitchState

var current_state: WitchState
var states: Dictionary = {}

func init(witch_node: CharacterBody3D) -> void:
	for child in get_children():
		if child is WitchState:
			states[child.name.to_lower()] = child
			child.witch = witch_node
			child.state_machine = self
			
	if initial_state:
		change_state(initial_state.name.to_lower())

func change_state(new_state_name: String) -> void:
	var target_state = states.get(new_state_name.to_lower())
	if not target_state:
		print("Warning: State '", new_state_name, "' does not exist!")
		return
		
	if current_state:
		current_state.exit()
		
	current_state = target_state
	current_state.enter()
	print("Witch FSM shifted to state: ", current_state.name)
	
func _physics_process(delta: float) -> void:
	if current_state: 
		current_state.physics_update(delta)
			
