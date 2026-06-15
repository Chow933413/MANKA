extends CharacterBody3D

@export_category("State Machine Node Link")
@export var state_machine: Node

@export_category("Combat Stats")
@export var max_health: int = 5
@export var speed: float = 0.0 # Stays completely stationary outside of active teleport sequences

@export_category("Packed Battle Scenes")
@export var skull_spell_scene: PackedScene     # Drop your Spell Scene file reference here
@export var skeleton_minion_scene: PackedScene # Drop your Skeleton Enemy Scene file reference here

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite3D = $Sprite3D
@onready var projectile_spawn: Marker3D = $ProjectileSpawn

var fight_started: bool = false
var current_health: int = 5
var player: CharacterBody3D = null
var is_dead: bool = false
var is_hurt: bool = false
var current_phase: int = 1

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	if state_machine and state_machine.has_method("init"):
		state_machine.init(self)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		
	if state_machine and state_machine.has_method("physics_update"):
		state_machine.physics_update(delta)
		
	move_and_slide()

func take_damage(amount: int = 1) -> void:
	if is_dead or is_hurt: return
	
	current_health -= amount
	print("[BOSS] Lich King hit! Current Hearts: ", current_health)
	
	if current_health <= 0:
		_die()
		return
		
	if current_health <= 3 and current_phase == 1:
		_transition_to_phase_two()
	else:
		_trigger_hurt_state()

func _trigger_hurt_state() -> void:
	is_hurt = true
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("Hurt")

func _transition_to_phase_two() -> void:
	current_phase = 2
	is_hurt = true 
	print("[BOSS] HEALTH CRITICAL. Switching to Phase 2!")
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("Hurt")

func _die() -> void:
	is_dead = true
	print("[BOSS] Lich King health hit 0!")
	
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("death")


func spawn_skull_projectile() -> void:
	if not skull_spell_scene or not player: return
	
	var skull = skull_spell_scene.instantiate() as Node3D
	get_tree().get_root().add_child(skull)
	skull.global_position = projectile_spawn.global_position
	
	if current_phase == 2 and "damage" in skull:
		skull.damage = 2 
		
	if skull.has_method("launch_at_target"):
		skull.launch_at_target(player.global_position + Vector3(0, 0.5, 0))

func summon_skeletons() -> void:
	if not skeleton_minion_scene: return
	
	# Place minions symmetrically along the X axis relative to boss global coordinates
	var spawn_offsets = [Vector3(-2.0, 0, 0), Vector3(2.0, 0, 0)]
	
	for offset in spawn_offsets:
		var skeleton = skeleton_minion_scene.instantiate() as CharacterBody3D
		get_tree().get_root().add_child(skeleton)
		skeleton.global_position = global_position + offset
		print("[BOSS] Summoned minion at: ", skeleton.global_position)

func teleport_to(target_position: Vector3) -> void:
	var boss_hurtbox = get_node_or_null("Hurtbox")
	if boss_hurtbox:
		boss_hurtbox.set_deferred("monitoring", false)
		boss_hurtbox.set_deferred("monitorable", false)
		
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.1, 0.6, 0.9, 0.0), 0.15) # Cool ice/necromancy blue
		await tween.finished
	
	global_position = target_position
	
	if sprite:
		var tween_in = create_tween()
		sprite.modulate = Color(0.1, 0.6, 0.9, 1.0)
		tween_in.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)
		await tween_in.finished
	
	if boss_hurtbox: 
		boss_hurtbox.set_deferred("monitoring", true)
		boss_hurtbox.set_deferred("monitorable", true)

func teleport_within_range_box(min_range: float = 4.0) -> void:
	if not player: return
	
	var box = get_tree().get_first_node_in_group("TeleportRange")
	if not box: 
		print("[TELEPORT ERROR] Node in group 'TeleportRange' was not found in the scene tree!")
		return
	
	var box_shape_node = box.get_node_or_null("CollisionShape3D")
	if not box_shape_node or not (box_shape_node.shape is BoxShape3D):
		print("[TELEPORT ERROR] TeleportRange node is missing a CollisionShape3D or it isn't a BoxShape3D!")
		return

	var box_transform = box_shape_node.global_transform
	var box_size = box_shape_node.shape.size * box_shape_node.global_transform.basis.get_scale()
	
	var margin = 1.0 
	var min_bounds = box_transform.origin - (box_size / 2) + Vector3(margin, 0, margin)
	var max_bounds = box_transform.origin + (box_size / 2) - Vector3(margin, 0, margin)
	
	var best_spot = Vector3.ZERO
	var max_dist = -1.0
	var found_valid_spot = false
	
	# Loop to find a spot away from the player
	for i in range(30):
		var random_spot = Vector3(
			randf_range(min_bounds.x, max_bounds.x),
			global_position.y, # Maintain current floor height
			randf_range(min_bounds.z, max_bounds.z)
		)
		
		var dist_to_player = random_spot.distance_to(player.global_position)
		
		if dist_to_player >= min_range:
			if dist_to_player > max_dist:
				max_dist = dist_to_player
				best_spot = random_spot
				found_valid_spot = true
				

	if not found_valid_spot:
		print("[TELEPORT WARN] Couldn't find a spot 5m away! Forcing fallback bounds.")
		var target_x = max_bounds.x if player.global_position.x < box_transform.origin.x else min_bounds.x
		var target_z = max_bounds.z if player.global_position.z < box_transform.origin.z else min_bounds.z
		best_spot = Vector3(target_x, global_position.y, target_z)
	
	print("[TELEPORT EXECUTE] Moving from: ", global_position, " -> To New Spot: ", best_spot)
	await teleport_to(best_spot)

func update_facing_direction(dir_x: float) -> void:
	if dir_x == 0 or is_dead: return
	
	if sprite:
		if dir_x > 0:
			sprite.rotation_degrees.y = 0
			if projectile_spawn: projectile_spawn.rotation_degrees.y = 0
		elif dir_x < 0:
			sprite.rotation_degrees.y = 180
			if projectile_spawn: projectile_spawn.rotation_degrees.y = 180

func start_boss_fight() -> void:
	if fight_started: return
	
	fight_started = true
	print("[BOSS] Trigger line stepped on! Starting intro dialogue...")
	
	
	if player and "controls_active" in player:
		player.controls_active = false
		if player.has_node("LimboHSM"):
			player.state_machine.dispatch("to_idle")

	DialogueManager.start_dialogue("THE LICH KING", "Who dares disturb the eternal frost of this chamber?")
	while DialogueManager.is_dialogue_active: 
		await get_tree().physics_frame
		
	DialogueManager.start_dialogue("THE LICH KING", "You are far from home, little mortal. Your journey ends here...")
	while DialogueManager.is_dialogue_active: 
		await get_tree().physics_frame
		
	DialogueManager.start_dialogue("THE LICH KING", "Arise, my magic! Tear them apart!")
	while DialogueManager.is_dialogue_active: 
		await get_tree().physics_frame

	if player and "controls_active" in player:
		player.controls_active = true
		
	print("[BOSS] Dialogue complete! Initiating Phase 1 combat loop.")
	
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("Phase1")
