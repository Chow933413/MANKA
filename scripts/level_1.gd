extends Node3D

@onready var witch = $Witch/Witch
@onready var trigger_line_1 = $Witch/TriggerLine1
@onready var trigger_line_2 = $Witch/TriggerLine2

func _ready() -> void:
	trigger_line_1.body_entered.connect(_on_trigger_line_1_entered)
	trigger_line_2.body_entered.connect(_on_trigger_line_2_entered)
	_start_intro_cinematic()
	
func _start_intro_cinematic() -> void:
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player entering from air portal! Letting them fall...")
		if "controls_active" in player:
			player.controls_active = false
		if player.has_node("LimboHSM"):
			player.state_machine.dispatch("to_fall")
			
		while not player.is_on_floor():
			await get_tree().physics_frame
			
		print("Player hit the ground! Starting Witch confrontation dialogue.")
		if player.has_node("LimboHSM"):
			player.state_machine.dispatch("to_idle")
			
		DialogueManager.start_dialogue("???", "Halt, stranger! Who are you to trespass into my woods?")
		while DialogueManager.is_dialogue_active:
			await get_tree().physics_frame
			
		if "controls_active" in player:
			player.controls_active = true
			
func _on_trigger_line_1_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Player crossed Line 1: Witch starts shooting Phase 1 spells!")
		witch.state_machine.change_state("Phase 1")
		trigger_line_1.disconnect("body_entered", _on_trigger_line_1_entered)
		
func _on_trigger_line_2_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Player crossed Line 2: Handing control over to Witch Phase 2!")
		witch.state_machine.change_state("Phase 2") 
		trigger_line_2.disconnect("body_entered", _on_trigger_line_2_entered)
