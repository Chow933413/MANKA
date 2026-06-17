extends StaticBody3D

@export var ui: CanvasLayer
@export var spawn_point_path: Marker3D   # Used for standard items and bridges
@export var spawn_point_path2: Marker3D  # Used for your Health Potion & Explosions
@export var explosion_scene: PackedScene 

# --- Grab a reference to our floating prompt node ---
@onready var interaction_prompt: Label3D = $InteractionPrompt

# Keep recipes dictionary simple for tracking static combinations
@export var recipes: Dictionary = {
	"Rope_Wood": null, # Handled explicitly via target_bridge_scene now!
	"Fire Powder_Frog Leg": preload("res://scenes/entities/Potion.scn"),
	"Bottle_Hearts": preload("res://scenes/entities/HealthPotion.tscn"), # Your health potion!
}

# ─── NEW: ASSIGN A SPECIFIC BRIDGE TO THIS SPECIFIC CAULDRON IN THE INSPECTOR ───
@export_category("Custom Assignment")
@export var target_bridge_scene: PackedScene = preload("res://scenes/surrounding/bridge.tscn") # Default fallback

func _ready() -> void:
	if ui:
		ui.set_cauldron(self)
	else:
		print("Error: You forgot to drag the CauldronUI into the Inspector!")
		
	# Setup interaction area signals
	var detection_area = $InteractArea
	if detection_area:
		detection_area.area_entered.connect(_on_area_entered_range)
		detection_area.area_exited.connect(_on_area_left_range)
		
	if interaction_prompt:
		interaction_prompt.hide()
	
func interact() -> void:
	if interaction_prompt:
		interaction_prompt.hide()
	ui.open_menu()

func _on_area_entered_range(area: Area3D) -> void:
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		if interaction_prompt and not ui.visible:
			interaction_prompt.show()

func _on_area_left_range(area: Area3D) -> void:
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		if interaction_prompt:
			interaction_prompt.hide()
	
func craft(selected_slots: Array) -> void:
	var cleaned_slots = []
	for slot in selected_slots:
		if slot != null and str(slot).strip_edges() != "":
			cleaned_slots.append(str(slot).strip_edges())
			
	if cleaned_slots.is_empty():
		return

	cleaned_slots.sort()
	var combination = "_".join(cleaned_slots)

	# 1. SPECIAL CASE: EXPLICIT CAULDRON-TO-BRIDGE CONFIGURATION
	if combination == "Rope_Wood":
		if spawn_point_path and target_bridge_scene:
			spawn_result(target_bridge_scene, spawn_point_path.global_position, spawn_point_path.global_rotation)
			print("Crafting Success: Spawned this specific cauldron's assigned bridge scene!")
			activate_exit_portal()
		else:
			print("Error: Missing spawn_point_path or target_bridge_scene assigned on this Cauldron!")
		return

	# 2. STANDARD STATIC DICTIONARY CHECK (For potions, etc.)
	if recipes.has(combination) and recipes[combination] != null:
		var scene_to_spawn = recipes[combination]
		
		var chosen_spawn_marker: Marker3D = spawn_point_path
		if combination == "Bottle_Hearts":
			chosen_spawn_marker = spawn_point_path2
			
		if chosen_spawn_marker:
			var is_victory = (combination == "Fire Powder_Frog Leg")
			
			spawn_result(scene_to_spawn, chosen_spawn_marker.global_position, chosen_spawn_marker.global_rotation, is_victory)
			print("Crafting Success: Generated ", combination, " at marker: ", chosen_spawn_marker.name)
		else:
			print("Error: The assigned spawn point marker for ", combination, " is missing in the Inspector!")
			
	elif "Spider Eye" in cleaned_slots or ("Fire Powder" in cleaned_slots and "Frog Leg" in cleaned_slots):
		refund_items_to_player(cleaned_slots)
		trigger_cauldron_explosion()
	else:
		refund_items_to_player(cleaned_slots)
		print("Unknown combination: ", combination)
		
func spawn_result(scene: PackedScene, target_pos: Vector3, target_rot: Vector3, is_victory_potion: bool = false) -> void:
	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = target_pos
	instance.global_rotation = target_rot

	if is_victory_potion and instance.has_signal("potion_collected"):
		instance.potion_collected.connect(_start_victory_cutscene)

func activate_exit_portal() -> void:
	var portals = get_tree().get_nodes_in_group("LevelPortal")
	for portal in portals:
		if portal.has_method("unlock") and portal.is_locked:
			portal.unlock()

func refund_items_to_player(items_to_return: Array) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and "inventory" in player:
		for item in items_to_return:
			player.inventory.append(item)
		print("Crafting Failed: Refunded items back to player inventory: ", player.inventory)

func trigger_cauldron_explosion() -> void:
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
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("take_damage"):
			player.take_damage() 
		elif "current_health_units" in player:
			player.current_health_units -= 1
			if player.current_health_units <= 0 and player.has_method("die"):
				player.die()
	
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Woah! Watch it, dearie! That combination is highly volatile. Clean yourself up and keep trying!")
	while DialogueManager.is_dialogue_active: 
		await get_tree().physics_frame
	
	if player and "controls_active" in player:
		player.controls_active = true
	if ui and ui.has_method("close_menu"):
		ui.close_menu()
		
	_reshow_prompt_if_near()

func _start_victory_cutscene() -> void:
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
		
	_reshow_prompt_if_near()

func _reshow_prompt_if_near() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and $InteractArea:
		var range_node = player.get_node_or_null("InteractionRange")
		if range_node and $InteractArea.overlaps_area(range_node):
			if interaction_prompt:
				interaction_prompt.show()
