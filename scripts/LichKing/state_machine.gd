extends Node

@export var initial_state: Node

var current_state: Node
var states: Dictionary = {}

func init(actor: CharacterBody3D) -> void:
	for child in get_children():
		states[child.name.to_lower()] = child
		
		if "actor" in child:
			child.actor = actor
		if "state_machine" in child:
			child.state_machine = self
			
	if initial_state:
		change_state(initial_state.name.to_lower())

func change_state(new_state_name: String) -> void:
	var target_state = states.get(new_state_name.to_lower())
	if not target_state:
		print("Warning: State '", new_state_name, "' does not exist!")
		return
		
	if current_state and current_state.has_method("exit"):
		current_state.exit()
		
	current_state = target_state
	
	if current_state and current_state.has_method("enter"):
		current_state.enter()
		
	print(get_parent().name, " FSM shifted to state: ", current_state.name)
	
# The root script calls this every physics tick!
func physics_update(delta: float) -> void:
	if current_state and current_state.has_method("physics_update"): 
		current_state.physics_update(delta)
