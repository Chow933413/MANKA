extends CharacterBody3D

signal health_changed(current_health_units: int)
signal player_died

# State Machine
@export_category("State Machines")
@export var state_machine : LimboHSM

# States
@onready var idle_state = $LimboHSM/Idle
@onready var move_state = $LimboHSM/Move
@onready var jump_state = $LimboHSM/Jump
@onready var fall_state = $LimboHSM/Fall
@onready var attack_state = $LimboHSM/Attack
@onready var locked_state = $LimboHSM/Locked

@onready var sprite: Sprite3D = $Sprite3D
@onready var camera_mount = $Camera_controller

const SPEED = 3.0
const JUMP_VELOCITY = 4.5

# Camera Settings
@export_category("Camera Settings")
@export var sens_vertical: float = 0.2
@export var sens_horizontal: float = 0.2
@export var min_pitch: float = -15.0 # Max look up angle
@export var max_pitch: float = 15.0  # Max look down angle

var hitbox_position: float
var movement_input: Vector2 = Vector2.ZERO
var controls_active: bool = true
var inventory: Array[String] = []

# Health system
@export_category("Health Settings")
@export var max_health: int = 7
var current_health: int = max_health
var current_health_units: int = 14
var is_dead: bool = false
@onready var respawn_position: Vector3 = global_position

# Knockback Settings
@export_category("Knockback Settings")
@export var knockback_force: float = 12.0
@export var knockback_bounce: float = 4.0    # Vertical lift velocity when hurt
@export var knockback_friction: float = 40.0 # How fast the slide slows down
var knockback_velocity: Vector3 = Vector3.ZERO

# Internal tracking for vertical mouse angle clamping
var camera_pitch: float = 0.0

func collect_word(new_word: String):
	inventory.append(new_word)
	print("Inventory: ", inventory)

func has_tokens(token_a: String, token_b: String) -> bool:
	var temp_inv = inventory.duplicate()
	if token_a in temp_inv:
		temp_inv.erase(token_a)
		if token_b in temp_inv:
			return true
	return false

func consume_tokens(token_a: String, token_b: String):
	inventory.erase(token_a)
	inventory.erase(token_b)
	print("Tokens used. Remaining: ", inventory)

func _input(event: InputEvent) -> void:
	if DialogueManager.is_dialogue_active:return
	# 1. Mouse Camera Rotation Logic
	#if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and controls_active and knockback_velocity == Vector3.ZERO:
		## Horizontal rotation turns the actual player node 360 degrees
		#rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		#
		## Vertical rotation modifies the camera mount pitch
		#camera_pitch -= event.relative.y * sens_vertical
		#camera_pitch = clamp(camera_pitch, min_pitch, max_pitch)
		#camera_mount.rotation_degrees.x = camera_pitch

	# 2. Gameplay Interaction Controls
	if event.is_action_pressed("interact"): # "E" key
		var areas = $InteractionRange.get_overlapping_areas()
		for a in areas:
			if a.get_parent().has_method("interact"):
				a.get_parent().interact()
	
	if event.is_action_pressed("ui_cancel"): # The Escape key
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	if NavigationManager.saved_health_units != -1:
		current_health_units = NavigationManager.saved_health_units
		print("Player spawned! Restoring health from previous scene: ", current_health_units)
	else:
		# First time starting the game, start with full health
		current_health_units = max_health * 2
		print("Player spawned! No saved health found, starting full: ", current_health_units)
		
	# 2. Tell the HUD to draw the correct amount of hearts right away
	health_changed.emit(current_health_units)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hitbox_position = ($"Sword Hitbox".position.x)
	_initialize_state_machine()
	
	# Cache initial camera tilt tracking value
	camera_pitch = camera_mount.rotation_degrees.x

func _initialize_state_machine():
	# Define state transitions
	state_machine.add_transition(idle_state, move_state, "to_move")
	state_machine.add_transition(move_state, idle_state, "to_idle")
	state_machine.add_transition(state_machine.ANYSTATE, jump_state, "to_jump")
	state_machine.add_transition(state_machine.ANYSTATE, fall_state, "to_fall")
	state_machine.add_transition(fall_state, move_state, "to_move")
	state_machine.add_transition(fall_state, idle_state, "to_idle")
	state_machine.add_transition(idle_state, attack_state, "to_attack")
	state_machine.add_transition(attack_state, move_state, attack_state.EVENT_FINISHED)
	state_machine.add_transition(state_machine.ANYSTATE, locked_state, "to_locked")
	state_machine.add_transition(locked_state, idle_state, "to_idle")
	
	# Setup State Machine
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

func check_attack_input():
	if DialogueManager.is_dialogue_active:return
	if Input.is_action_just_pressed("attack"):
		state_machine.dispatch("to_attack")

func update_sprite_direction():
	if movement_input.x != 0:
		sprite.flip_h = movement_input.x < 0

func apply_movement(delta: float):
	var move_direction = (transform.basis * Vector3(movement_input.x, 0, movement_input.y)).normalized()
	
	if move_direction:
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _physics_process(delta: float) -> void:
	
	if DialogueManager.is_dialogue_active:
		movement_input = Vector2.ZERO
		velocity.x = 0
		velocity.z = 0
		knockback_velocity = Vector3.ZERO
		controls_active = false
		if state_machine:
			state_machine.dispatch("to_idle")
			state_machine.set_active(false)
		move_and_slide()
		return
	
	# Keep state machine active so it can process unfreeze dispatches
	if state_machine:
		if not DialogueManager.is_dialogue_active and not state_machine.is_active():
			state_machine.set_active(true)
			controls_active = true
			state_machine.dispatch("to_idle")

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# ALWAYS process and slow down knockback force over time
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_friction * delta)
		
		# Override movement vectors to force the player backward through space!
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
	else:
		knockback_velocity = Vector3.ZERO
		
		# UNFREEZE TRIGGER: Regain control only when sliding stops and player is safely grounded
		if state_machine and state_machine.get_active_state() == locked_state and not is_dead:
			if is_on_floor():
				controls_active = true
				state_machine.dispatch("to_idle")

	# Control tracking vector allocations
	if controls_active and knockback_velocity == Vector3.ZERO:
		movement_input = Input.get_vector("left", "right", "up", "down")
	else:
		movement_input = Vector2.ZERO
		
	move_and_slide()
	
	# Handle flipping hitboxes dynamically relative to input direction
	if movement_input.x > 0:
		$"Sword Hitbox".position.x = hitbox_position
	elif movement_input.x < 0:
		$"Sword Hitbox".position.x = -hitbox_position

func _on_sword_hitbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()

func _on_hurt_box_area_entered(area: Area3D) -> void:
	if is_dead: return
	
	if area.name.to_lower().contains("hitbox") or area.is_in_group("deadly_hazard"):
		var incoming_damage = 2 # Changed default to 2 units (1 full heart)
		
		if "damage_units" in area:
			incoming_damage = area.damage_units
			print("Player hit by ", area.name, " dealing ", incoming_damage, " units!")
		
		current_health_units -= incoming_damage
		current_health_units = clamp(current_health_units, 0, max_health * 2)
		
		health_changed.emit(current_health_units)
		
		if current_health_units <= 0:
			die()
		else:
			apply_knockback(area.global_position, knockback_force)
		
func apply_knockback(source_position: Vector3, force: float = 12.0) -> void:
	if is_dead: return
	controls_active = false
	
	var push_direction: Vector3 = global_position - source_position
	push_direction.y = 0
	push_direction = push_direction.normalized()
	
	knockback_velocity = push_direction * force
	
	# Give the player a classic diagonal pop upward and backward simultaneously!
	velocity.y = knockback_bounce
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

	if state_machine:
		state_machine.dispatch("to_locked")

func die() -> void:
	is_dead = true
	controls_active = false
	knockback_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	
	sprite.modulate = Color(0.2, 0.2, 0.2, 0.8)
	state_machine.dispatch("to_locked")
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit()

func respawn() -> void:
	is_dead = false
	controls_active = true
	knockback_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	sprite.modulate = Color(1, 1, 1, 1)
	
	NavigationManager.saved_health_units = max_health * 2
	current_health_units = max_health * 2
	
	# Fixed signature matching error block
	health_changed.emit(current_health_units)
	
	state_machine.dispatch("to_idle")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if NavigationManager.respawn_scene_path != "":
		NavigationManager.target_portal_id = NavigationManager.respawn_portal_id
		NavigationManager.teleport_to_scene(NavigationManager.respawn_scene_path, NavigationManager.respawn_portal_id)
	else:
		get_tree().reload_current_scene()
