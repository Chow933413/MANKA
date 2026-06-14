extends CharacterBody3D

@export_category("State Machine Node Link")
@export var state_machine: Node 

@export_category("Combat Stats")
@export var speed: float = 2.0
@export var attack_range: float = 0.5 # Boosted slightly from 0.5 for 3D clearance
@export var max_health: int = 3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite3D = $Sprite3D
@onready var sword_hitbox: Area3D = $SwordHitbox
@onready var vision_area: Area3D = $VisualArea # <-- Link your new Area3D node here!

var hitbox_position: float = 0.0	

var current_health: int = max_health
var player: CharacterBody3D = null
var local_hitbox_x: float = 0.0
var is_dead: bool = false
var is_hurt: bool = false

# This variable still holds the player tracking link for Idle and Chase states
var player_target: CharacterBody3D = null

func _ready() -> void:
	current_health = max_health
	if sword_hitbox:
		local_hitbox_x = sword_hitbox.position.x
		
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	# Connect our Area3D entry and exit signals via code automatically
	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)
	
	if state_machine and state_machine.has_method("init"):
		state_machine.init(self)

func _physics_process(delta: float) -> void:
	# Apply gravity constantly
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		
	# Call state machine manager update method
	if state_machine and state_machine.has_method("physics_update"):
		state_machine.physics_update(delta)
		
	move_and_slide()

# ─── AREA3D DETECTION SIGNALS ───
func _on_vision_area_body_entered(body: Node3D) -> void:
	if is_dead: return
	if body.is_in_group("player") or body == player:
		player_target = body as CharacterBody3D
		print("[VISION] Player stepped inside range! Target saved.")

func _on_vision_area_body_exited(body: Node3D) -> void:
	if body == player_target:
		player_target = null
		print("[VISION] Player walked out of range! Target lost.")

func update_facing_direction(dir_x: float) -> void:
	if dir_x == 0 or is_dead: return
	
	sprite.flip_h = dir_x < 0
	
	if sword_hitbox:
		if dir_x > 0:
			sword_hitbox.rotation_degrees.y = 0
		elif dir_x < 0:
			sword_hitbox.rotation_degrees.y = 180

func play_animation(anim_name: String) -> void:
	if animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func take_damage(amount: int = 1) -> void:
	if is_dead: return
	current_health -= amount
	if current_health <= 0:
		_die() 
	else:
		_trigger_hurt_state()

func _trigger_hurt_state() -> void:
	is_hurt = true
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("hurt")
	is_hurt = false

func _die() -> void:
	is_dead = true
	player_target = null # Drop tracking on death
	if state_machine and state_machine.has_method("change_state"):
		state_machine.change_state("death")
