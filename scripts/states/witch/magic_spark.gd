extends Area3D

@export var speed: float = 5.0
@export var damage_units: int = 2

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_splashing: bool = false

func _physics_process(delta: float) -> void:
	if not is_splashing:
		global_position -= global_transform.basis.z * speed * delta

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if animation_player.has_animation("moving"):
			animation_player.play("moving")
	await get_tree().create_timer(1.5).timeout
	queue_free()
	

func _on_area_entered(area: Area3D) -> void:
	if is_splashing: return
	
	if area.name == "HurtBox" and area.get_parent().is_in_group("player"):
		is_splashing = true
		
		monitoring = false
		monitorable = false
		
		if animation_player.has_animation("splash"):
			animation_player.play("splash")
		
			await animation_player.animation_finished
		queue_free()
