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
var last_safe_ground_position: Vector3 = Vector3.ZERO

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
	
	inventory.clear()
	print("Player Ready: Inventory wiped for the new scene! Current: ", inventory)
	
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
	
	last_safe_ground_position = global_position
	
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
	
	if is_on_floor() and controls_active and not is_dead and knockback_velocity == Vector3.ZERO:
		if velocity.y >= 0: # Ensures we don't track coordinates while slipping or falling!
			last_safe_ground_position = global_position
	
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
		if is_on_floor() and knockback_velocity == Vector3.ZERO:
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

func collect_potion() -> void:
	if not "Fire Potion" in inventory:
		inventory.append("Fire Potion")
		print("Collected Fire Resistance Potion!")

func take_damage(incoming_damage: int = 2, source_position: Vector3 = Vector3.ZERO) -> void:
	if is_dead: return
	
	# 1. IMMUNITY CHECK: If holding the Fire Potion, completely ignore damage!
	if "Fire Potion" in inventory:
		print("Player: Immune to damage thanks to Fire Potion!")
		return

	print("Player taking damage: ", incoming_damage, " units.")
	
	current_health_units -= incoming_damage
	current_health_units = clamp(current_health_units, 0, max_health * 2)
	
	health_changed.emit(current_health_units)
	
	if current_health_units <= 0:
		die()
	else:
		# If a source position was passed, fly backward! 
		# If no position was passed (like a default fallback), bounce away from current spot
		var source = source_position if source_position != Vector3.ZERO else global_position - Vector3.FORWARD
		apply_knockback(source, knockback_force)

func _on_hurt_box_area_entered(area: Area3D) -> void:
	if is_dead: return
	
	if area.name.to_lower().contains("hitbox"):
		# 1. Handle string token mismatch fallback ("fire_resistance" or "Fire Potion")
		if "Fire Potion" in inventory or "fire_resistance" in inventory:
			print("Immune to hazard area thanks to potion inventory!")
			return
		
		var incoming_damage = 2
		if "damage_units" in area:
			incoming_damage = area.damage_units
			print("Player hit by ", area.name, " dealing ", incoming_damage, " units!")
		
		# Pass the data directly into our new unified damage function!
		take_damage(incoming_damage, area.global_position)
		
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
	current_health_units = 0
	health_changed.emit(current_health_units) 
	player_died.emit()
	
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

func _on_sword_hitbox_area_entered(area: Area3D) -> void:
	var parent_node = area.get_parent()
	
	if parent_node and parent_node.has_method("take_damage"):
		parent_node.take_damage()

# Inside Player.gd
@onready var alert_label: Label3D = $Label3D

func play_alert_animation(text_to_show: String) -> void:
	if not alert_label: return
	
	# Update the label with the custom text passed from the trigger line
	alert_label.text = text_to_show
	alert_label.visible = true
	alert_label.modulate = Color(1, 0, 0, 1) # Full red and visible
	
	# Start with a small scale for a pop effect
	alert_label.scale = Vector3.ZERO
	
	var tween = create_tween().set_parallel(true)
	
	# 1. Pop scale up with a slight bounce
	tween.tween_property(alert_label, "scale", Vector3(1.2, 1.2, 1.2), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Fade it out completely after a short delay
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.7) # Keep visible for 0.7 seconds
	fade_tween.tween_property(alert_label, "modulate:a", 0.0, 0.3) # Fade away
	
	# Hide it cleanly once the fade finishes
	fade_tween.finished.connect(func(): alert_label.visible = false)
	
func reset_to_safe_ground() -> void:
	if is_dead: return
	
	print("Player fell into water! Resetting to safe ground.")
	
	# 1. Deduct 1 full heart (2 health units)
	current_health_units -= 2
	current_health_units = clamp(current_health_units, 0, max_health * 2)
	health_changed.emit(current_health_units)
	
	if current_health_units <= 0:
		die()
		return
	
	# 2. Freeze movement vectors so they don't carry falling momentum
	velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO
	
	# 3. MODIFIED TELEPORTATION: Keep the X and Z from where they safely walked, 
	# but force the Y axis flat onto the floor (0.0).
	global_position = last_safe_ground_position
	
	# 4. FORCE CONTROLS BACK ON IMMEDIATELY
	controls_active = true
	
	# 5. FORCE STATE MACHINE UNLOCK
	if state_machine:
		state_machine.set_active(true)
		state_machine.dispatch("to_idle")
		print("Player State forced back to Idle. Respawn Position: ", global_position)
	
	# 6. Play the blue water hazard flash effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0, 0, 1), 0.15) # Tint blue
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)
