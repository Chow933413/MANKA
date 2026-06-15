extends Area3D

@export_category("Movement Stats")
@export var speed: float = 5.0
@export var lifetime: float = 4.0
@export var damage: int = 1 

@export_category("Homing Settings")
@export var is_homing: bool = false
@export var homing_steering_force: float = 4.0

@onready var sprite: Sprite3D = $Sprite3D

var move_direction: Vector3 = Vector3.ZERO
var target_player: CharacterBody3D = null

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	area_entered.connect(_on_something_entered)
	body_entered.connect(_on_something_entered)
	
	target_player = get_tree().get_first_node_in_group("player") as CharacterBody3D

func launch_at_target(target_global_position: Vector3) -> void:
	move_direction = (target_global_position - global_position).normalized()
	_update_sprite_facing()

func _physics_process(delta: float) -> void:
	if is_homing and target_player and is_instance_valid(target_player):
		var player_chest = target_player.global_position + Vector3(0, 0.5, 0)
		var desired_direction = (player_chest - global_position).normalized()
		
		move_direction = move_direction.lerp(desired_direction, homing_steering_force * delta).normalized()
		_update_sprite_facing()
		
	global_position += move_direction * speed * delta

func _update_sprite_facing() -> void:
	if sprite and move_direction.x != 0:
		sprite.flip_h = move_direction.x < 0

func _on_something_entered(hit_object: Node) -> void:
	var potential_body = hit_object.get_parent() if hit_object is Area3D else hit_object
	
	if potential_body.is_in_group("player") or potential_body.name == "Player":
		if potential_body.has_method("take_damage"):
			potential_body.take_damage(damage) 
			print("[SPELL] Skull hit the player successfully for ", damage, " damage!")
			
		_explode_and_destroy()
	
	elif potential_body is StaticBody3D or potential_body.name.contains("Floor") or potential_body.name.contains("Platform"):
		_explode_and_destroy()

func _explode_and_destroy() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	hide()
	queue_free()
