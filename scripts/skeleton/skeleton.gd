extends CharacterBody3D

@export_category("State Machine Node Link")
@export var state_machine: Node 

@export_category("Combat Stats")
@export var speed: float = 2.0
@export var attack_range: float = 0.5
@export var max_health: int = 3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite3D = $Sprite3D
@onready var sword_hitbox: Area3D = $SwordHitbox

var hitbox_position: float = 0.0	

var current_health: int = max_health
var player: CharacterBody3D = null
var local_hitbox_x: float = 0.0
var is_dead: bool = false
var is_hurt: bool = false

func _ready() -> void:
	current_health = max_health
	if sword_hitbox:
		local_hitbox_x = sword_hitbox.position.x
		
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	if state_machine and state_machine.has_method("init"):
		state_machine.init(self)

func _physics_process(delta: float) -> void:
	# 1. APPLY GRAVITY CONSTANTLY HERE
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		
	# 2. FIXED: Call 'physics_update' to match your state machine manager's method!
	if state_machine and state_machine.has_method("physics_update"):
		state_machine.physics_update(delta)
		
	# 3. Process calculations into physical workspace movement
	move_and_slide()

func update_facing_direction(dir_x: float) -> void:
	if dir_x == 0 or is_dead: return
	
	# 1. Flip the 2D visual sprite sheet
	sprite.flip_h = dir_x < 0
	
	# 2. Rotate the hitbox instead of moving it!
	if sword_hitbox:
		if dir_x > 0:
			# Facing Right: Set rotation to 0 degrees (Standard)
			sword_hitbox.rotation_degrees.y = 0
		elif dir_x < 0:
			# Facing Left: Rotate 180 degrees to flip it to the other side
			sword_hitbox.rotation_degrees.y = 180

func play_animation(anim_name: String) -> void:
	if animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func take_damage(amount: int = 1) -> void:
	if is_dead: return
	
	current_health -= amount
	if current_health <= 0:
		_die() # Triggers death state when health hits zero
	else:
		_trigger_hurt_state()

func _trigger_hurt_state() -> void:
	is_hurt = true
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("hurt")
	is_hurt = false

func _die() -> void:
	is_dead = true
	
	# Hand complete control over to your Death node!
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("death")
