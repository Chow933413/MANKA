extends StaticBody3D

@export var ui: CanvasLayer
@export var bridge_scene: PackedScene
@export var spawn_point_path: Marker3D
@export var spawn_point_path2: Marker3D
@export var explosion_scene: PackedScene 

# --- NEW: Grab a reference to our floating prompt node ---
@onready var interaction_prompt: Label3D = $InteractionPrompt

@export var recipes: Dictionary = {
	"Rope_Wood": preload("res://scenes/surrounding/bridge.tscn"),
	"Fire Powder_Frog Leg": preload("res://scenes/entities/Potion.scn")
}

func _ready() -> void:
	if ui:
		ui.set_cauldron(self)
	else:
		print("Error: You forgot to drag the CauldronUI into the Inspector!")
		
	# --- NEW: Setup interaction area signals ---
	# Ensure this matches the exact name of the Area3D child node on your cauldron!
	var detection_area = $InteractArea
	if detection_area:
		detection_area.area_entered.connect(_on_area_entered_range)
		detection_area.area_exited.connect(_on_area_left_range)
		
	if interaction_prompt:
		interaction_prompt.hide()
	
func interact():
	# Hide prompt immediately when UI takes over the screen
	if interaction_prompt:
		interaction_prompt.hide()
	ui.open_menu()

# --- NEW: Show prompt when player's InteractionRange approaches ---
func _on_area_entered_range(area: Area3D) -> void:
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		if interaction_prompt and not ui.visible: # Only show if UI isn't open
			interaction_prompt.show()

# --- NEW: Hide prompt when player walks away ---
func _on_area_left_range(area: Area3D) -> void:
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		if interaction_prompt:
			interaction_prompt.hide()
	
func craft(selected_slots: Array):
	var cleaned_slots = []
	for slot in selected_slots:
		if slot != null and str(slot).strip_edges() != "":
			cleaned_slots.append(str(slot).strip_edges())
			
	if cleaned_slots.is_empty():
		return

	cleaned_slots.sort()
	var combination = "_".join(cleaned_slots)

	# 1. CHECK FOR SUCCESSFUL RECIPE MATCH
	if recipes.has(combination):
		var scene_to_spawn = recipes[combination]
		if spawn_point_path:
			spawn_result(scene_to_spawn, spawn_point_path.global_position, spawn_point_path.global_rotation)
			print("Crafting Success: Generated ", combination)
			
			# Trigger Level 1 bridge path unlock
			if combination == "Rope_Wood":
				activate_exit_portal()
		else:
			print("Error: No spawn point assigned in the Inspector!")
			
	elif "Spider Eye" in cleaned_slots or ("Fire Powder" in cleaned_slots and "Frog Leg" in cleaned_slots):
		refund_items_to_player(cleaned_slots)
		trigger_cauldron_explosion()
	else:
		refund_items_to_player(cleaned_slots)
		print("Unknown combination: ", combination)
		
func spawn_result(scene: PackedScene, target_pos: Vector3, target_rot: Vector3):
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = target_pos
	instance.global_rotation = target_rot

	if instance.has_signal("potion_collected"):
		instance.potion_collected.connect(_start_victory_cutscene)

func activate_exit_portal():
	var portals = get_tree().get_nodes_in_group("LevelPortal")
	for portal in portals:
		if portal.has_method("unlock") and portal.is_locked:
			portal.unlock()

func refund_items_to_player(items_to_return: Array):
	var player = get_tree().get_first_node_in_group("player")
	if player and "inventory" in player:
		for item in items_to_return:
			player.inventory.append(item)
		print("Crafting Failed: Refunded items back to player inventory: ", player.inventory)

func trigger_cauldron_explosion():
	print("BOOM! The cauldron explodes due to a volatile combination!")
	
	if explosion_scene:
		var spawn_pos = spawn_point_path2.global_position if spawn_point_path2 else global_position
		var exp_instance = explosion_scene.instantiate()
		
		get_tree().current_scene.add_child(exp_instance)
		exp_instance.global_position = spawn_pos
		
		if exp_instance.has_node("AnimationPlayer"):
			exp_instance.get_node("AnimationPlayer").play("init")
		elif exp_instance is AnimationPlayer:
			exp_instance.play("init")
		else:
			print("Warning: Could not automatically find AnimationPlayer on explosion instance.")
	else:
		print("Warning: No explosion_scene assigned in Inspector!")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("take_damage"):
			player.take_damage() 
		elif "current_health_units" in player:
			player.current_health_units -= 1
			print("Player caught in explosion! Health left: ", player.current_health_units)
			
			if player.current_health_units <= 0 and player.has_method("die"):
				player.die()
	
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Woah! Watch it, dearie! That combination is highly volatile. Clean yourself up and keep trying!")
	while DialogueManager.is_dialogue_active: 
		await get_tree().physics_frame
	
	if player and "controls_active" in player:
		player.controls_active = true
	
	if ui and ui.has_method("close_menu"):
		ui.close_menu()
		
	# Reshow prompt if player stays next to the cauldron after an explosion
	_reshow_prompt_if_near()

func _start_victory_cutscene():
	var player = get_tree().get_first_node_in_group("player")
	
	if player and "controls_active" in player:
		player.controls_active = false
		if player.has_node("LimboHSM"):
			player.state_machine.dispatch("to_idle")
			
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Good job of creating your own potion! That's the reward. Now go on, drink it.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
	
	DialogueManager.start_dialogue("NARRATOR", "You drink the potion......")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
	
	DialogueManager.start_dialogue("NARRATOR", "It tasted like very spicy frog. You regret every second.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
	
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Hehe... See? Infinitely better than anything you find on the dirt floor.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame

	activate_exit_portal()
		
	if player and "controls_active" in player:
		player.controls_active = true
		
	# Clean reset check when cutscenes end
	_reshow_prompt_if_near()

# Helper checker to safely reset the prompt state after menus close
func _reshow_prompt_if_near():
	var player = get_tree().get_first_node_in_group("player")
	if player and $InteractArea:
		var range_node = player.get_node_or_null("InteractionRange")
		if range_node and $InteractArea.overlaps_area(range_node):
			if interaction_prompt:
				interaction_prompt.show()
