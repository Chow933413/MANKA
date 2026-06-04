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

var is_invulnerable: bool = false

func _ready() -> void:
	current_health = max_health
	state_machine.init(self)

func interact() -> void:
	if state_machine.current_state and state_machine.current_state.has_method("trigger_interaction"):
		state_machine.current_state.trigger_interaction()

func take_damage() -> void:
	if is_invulnerable: return
	
	# If the current state has a custom way to handle being hit (like Intro), let it handle it!
	if state_machine.current_state and state_machine.current_state.has_method("handle_hit_during_state"):
		state_machine.current_state.handle_hit_during_state()
		return
		
	if state_machine.current_state.name.to_lower() == "dead":
		return
		
	current_health -= 1
	print("Witch Health: ", current_health)
	
	if current_health <= 0:
		state_machine.change_state("Dead")
	else:
		state_machine.change_state("Hurt")
		
func _physics_process(delta: float) -> void:
	if state_machine: 
		state_machine._physics_process(delta)

func teleport_to(target_position: Vector3) -> void:
	var witch_hurtbox = get_node_or_null("Hurtbox")
	if witch_hurtbox:
		witch_hurtbox.monitoring = false
		witch_hurtbox.monitorable = false
		
	# Fade Out Visuals	
	if sprite:
		var tween = create_tween()
		# Flash a dark magical purple/red hue and dip opacity instantly to 0
		tween.tween_property(sprite, "modulate", Color(0.6, 0.1, 0.9, 0.0), 0.15)
		await tween.finished
	
	# Update world location coordinates
	global_position = target_position
	
	# Fade In Visuals
	if sprite:
		var tween_in = create_tween()
		sprite.modulate = Color(0.6, 0.1, 0.9, 1.0) # Bright mystical glow upon appearance
		tween_in.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)
		await tween_in.finished
	
	# Restore collision metrics ONLY if she isn't permanently down/instructor mode	
	if witch_hurtbox and state_machine.current_state.name.to_lower() != "dead": 
		witch_hurtbox.monitoring = true
		witch_hurtbox.monitorable = true
		
func teleport_away_from_player(min_range: float = 6.0, max_range: float = 10.0) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var box = get_tree().get_first_node_in_group("TeleportRange")
	if not player or not box: 
		print("Teleport failed: No player or box found.")
		return
	
	var box_shape_node = box.get_node_or_null("CollisionShape3D")
	if not box_shape_node or not (box_shape_node.shape is BoxShape3D):
		print("Teleport failed: No BoxShape3D found.")
		return

	# Use global_transform to account for node scaling and rotation
	var box_transform = box_shape_node.global_transform
	var box_size = box_shape_node.shape.size * box_shape_node.global_transform.basis.get_scale()
	
	var margin = 1.0 
	var min_bounds = box_transform.origin - (box_size / 2) + Vector3(margin, 0, margin)
	var max_bounds = box_transform.origin + (box_size / 2) - Vector3(margin, 0, margin)
	
	var best_spot = Vector3.ZERO
	var max_dist = -1.0
	var found_valid_spot = false
	
	# Try 20 times to find a good spot
	for i in range(20):
		var random_spot = Vector3(
			randf_range(min_bounds.x, max_bounds.x),
			global_position.y,
			randf_range(min_bounds.z, max_bounds.z)
		)
		
		var dist_to_player = random_spot.distance_to(player.global_position)
		
		# If we find a spot further than min_range, it's a candidate
		if dist_to_player >= min_range:
			if dist_to_player > max_dist:
				max_dist = dist_to_player
				best_spot = random_spot
				found_valid_spot = true
	
	# FALLBACK: If player is camping the whole box, just pick the furthest point
	if not found_valid_spot:
		print("Witch: No ideal spot found, teleporting to furthest possible point.")
		best_spot = Vector3(
			max_bounds.x if player.global_position.x < box_transform.origin.x else min_bounds.x,
			global_position.y,
			max_bounds.z if player.global_position.z < box_transform.origin.z else min_bounds.z
		)
	
	await teleport_to(best_spot)
