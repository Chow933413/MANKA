extends Area3D

@onready var damage_timer: Timer = $Timer

# Tracks if the player is currently standing inside the flames
var player_inside: Node3D = null

func _ready() -> void:
	# Connect signals via code as a fail-safe measure
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	damage_timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = body
		
		# 1. Deal 1 heart of damage IMMEDIATELY when they step in
		deal_fire_damage()
		
		# 2. Start the ticking timer for continuous damage
		damage_timer.start()

func _on_body_exited(body: Node3D) -> void:
	if body == player_inside:
		player_inside = null
		damage_timer.stop()


func deal_fire_damage() -> void:
	if not player_inside or player_inside.is_dead:
		return

	player_inside.current_health_units -= 1
	player_inside.current_health_units = clamp(player_inside.current_health_units, 0, player_inside.max_health * 2)
	
	player_inside.health_changed.emit(player_inside.current_health_units)
	
	print("Player scorched by fire! Remaining units: ", player_inside.current_health_units)
	
	var tween = create_tween()
	tween.tween_property(player_inside.sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(player_inside.sprite, "modulate", Color(1, 1, 1), 0.1)

	if player_inside.current_health_units <= 0:
		player_inside.die()
		damage_timer.stop()


func _on_timer_timeout() -> void:
	if player_inside:
		deal_fire_damage()
