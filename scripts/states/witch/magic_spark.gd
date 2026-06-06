extends Area3D

@export var speed: float = 30.0
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
		var player = area.get_parent()
		
		# 1. POTION CHECK: If player has the Fire Potion, the spark breaks harmlessly!
		if "inventory" in player and "Fire Potion" in player.inventory:
			print("MagicSpark: Player has Fire Potion! Spark fizzles away.")
			
			is_splashing = true
			monitoring = false
			monitorable = false
			
			# If you want it to still play the splash visual without dealing damage:
			if animation_player.has_animation("splash"):
				animation_player.play("splash")
				await animation_player.animation_finished
				
			queue_free()
			return # Exit early so it never triggers player damage!

		# 2. NORMAL DAMAGE PATHWAY (If player has no potion)
		is_splashing = true
		monitoring = false
		monitorable = false
		
		# (Assuming your player script takes damage through a method or property, 
		# like player.take_damage(damage_units) - make sure to trigger it here if needed!)
		print("Player hit by MagicSparkHitbox dealing ", damage_units, " units!")
		
		if animation_player.has_animation("splash"):
			animation_player.play("splash")
			await animation_player.animation_finished
			
		queue_free()
