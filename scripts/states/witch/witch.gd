extends CharacterBody3D

@export_category("Combat Stats")
var max_health: int = 3
var current_health: int = 3

@export_category("Packed 2.5D Battle Scenes")
@export var magic_spark_scene: PackedScene
@export var word_trap_scene: PackedScene

@onready var state_machine: Node = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var projectile_spawn: Marker3D = $ProjectileSpawn
@onready var sprite: Sprite3D = $Sprite3D

var has_talked_this_visit: bool = false
var is_invulnerable: bool = false

func _ready() -> void:
	current_health = max_health
	state_machine.init(self)
	
	# --- FIXED: Target the actual InteractionArea node instead of the Hurtbox! ---
	var interaction_area = $InteractionArea
	if interaction_area:
		if not interaction_area.body_exited.is_connected(_on_player_left_interaction):
			interaction_area.body_exited.connect(_on_player_left_interaction)
	else:
		print("Warning: InteractionArea node not found on Witch!")

func interact() -> void:
	# 1. NEW LOGIC: If she retreated to her hut, trigger her guidance dialogue!
	if is_invulnerable:
		if has_talked_this_visit:
			print("Witch: Player already talked to me this visit. Ignoring button press.")
			return
			
		has_talked_this_visit = true
		_play_guidance_dialogue()
		return

	# 2. DEFAULT COMBAT LOGIC: Only processed if she is still hostile
	if state_machine.current_state and state_machine.current_state.has_method("trigger_interaction"):
		state_machine.current_state.trigger_interaction()

# --- POST-BATTLE GUIDANCE DIALOGUE SYSTEM ---
func _play_guidance_dialogue() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and "controls_active" in player:
		player.controls_active = false
		if player.has_node("LimboHSM"):
			player.state_machine.dispatch("to_idle")
	
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Hooray. You passed. Truly, the bards will sing of the brave hero who defeated me by... drinking warm fluid they found in the dirt.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
		
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Who taught you how to fight? If I left a bottle of bleach out here with a smiley face on it, would you have swallowed that too?!")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
		
	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Stop playing dumpster-diver. Your stomach lining must look like Swiss cheese.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame

	DialogueManager.start_dialogue("THE WOODLAND WITCH", "Go track down 3 descriptive orbs hidden in these woods, smash their texts together, and generate your own mixtures.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame

	DialogueManager.start_dialogue("THE WOODLAND WITCH", "You are a literal wizard. Stop eating things off the ground and learn to cook.")
	while DialogueManager.is_dialogue_active: await get_tree().physics_frame
	
	if player and "inventory" in player:
		player.inventory.clear()
		print("Witch confiscated the player's items! Inventory cleared: ", player.inventory)
	
	if player and "controls_active" in player:
		player.controls_active = true

func take_damage() -> void:
	if is_invulnerable: return
	
	var state_name = state_machine.current_state.name.to_lower()
	if state_name == "phase 2" or state_name == "phase 1":
		var player = get_tree().get_first_node_in_group("player")
		
		if player and "inventory" in player and ("Fire Potion" in player.inventory or "fire_potion" in player.inventory):
			_retreat_to_hut_permanently()
			return

func _retreat_to_hut_permanently() -> void:
	is_invulnerable = true
	state_machine.change_state("") 
	
	has_talked_this_visit = false 
	
	var hut_spot = get_tree().get_root().find_child("WitchHutSpot", true, false)
	if hut_spot:
		await teleport_to(hut_spot.global_position)
		
	DialogueManager.start_dialogue("???", "Hehe... intriguing.")
	while DialogueManager.is_dialogue_active:
		await get_tree().physics_frame
		
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")

func _physics_process(delta: float) -> void:
	if state_machine and state_machine.current_state: 
		state_machine._physics_process(delta)

func teleport_to(target_position: Vector3) -> void:
	var witch_hurtbox = get_node_or_null("Hurtbox")
	if witch_hurtbox:
		witch_hurtbox.monitoring = false
		witch_hurtbox.monitorable = false
		
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.6, 0.1, 0.9, 0.0), 0.15)
		await tween.finished
	
	global_position = target_position
	
	if sprite:
		var tween_in = create_tween()
		sprite.modulate = Color(0.6, 0.1, 0.9, 1.0)
		tween_in.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)
		await tween_in.finished
	
	if witch_hurtbox: 
		witch_hurtbox.monitoring = true
		witch_hurtbox.monitorable = true

func teleport_away_from_player(min_range: float = 6.0, max_range: float = 10.0) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var box = get_tree().get_first_node_in_group("TeleportRange")
	if not player or not box: 
		return
	
	var box_shape_node = box.get_node_or_null("CollisionShape3D")
	if not box_shape_node or not (box_shape_node.shape is BoxShape3D):
		return

	var box_transform = box_shape_node.global_transform
	var box_size = box_shape_node.shape.size * box_shape_node.global_transform.basis.get_scale()
	
	var margin = 1.0 
	var min_bounds = box_transform.origin - (box_size / 2) + Vector3(margin, 0, margin)
	var max_bounds = box_transform.origin + (box_size / 2) - Vector3(margin, 0, margin)
	
	var best_spot = Vector3.ZERO
	var max_dist = -1.0
	var found_valid_spot = false
	
	for i in range(20):
		var random_spot = Vector3(
			randf_range(min_bounds.x, max_bounds.x),
			global_position.y,
			randf_range(min_bounds.z, max_bounds.z)
		)
		
		var dist_to_player = random_spot.distance_to(player.global_position)
		
		if dist_to_player >= min_range:
			if dist_to_player > max_dist:
				max_dist = dist_to_player
				best_spot = random_spot
				found_valid_spot = true
	
	if not found_valid_spot:
		best_spot = Vector3(
			max_bounds.x if player.global_position.x < box_transform.origin.x else min_bounds.x,
			global_position.y,
			max_bounds.z if player.global_position.z < box_transform.origin.z else min_bounds.z
		)
	
	await teleport_to(best_spot)
	
func _on_player_left_interaction(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		has_talked_this_visit = false
		print("Player left the Witch's InteractionArea. Resetting conversation status!")
