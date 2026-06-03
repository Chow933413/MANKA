extends CanvasLayer

@onready var heartContainer = $HeartContainer
@onready var respawn_button = $RespawnButton

# Remove the @onready declaration from up here!
@onready var player = get_parent()

func _ready() -> void:
	if player:
		# 1. Connect the signal FIRST so it catches every single message
		player.health_changed.connect(heartContainer.updateHearts)
		player.player_died.connect(_on_player_died)
		
		# 2. Build the containers
		heartContainer.setMaxHearts(player.max_health)
		
		# 3. Manually push the current health into the protected container
		heartContainer.updateHearts(player.current_health_units)
	
	respawn_button.pressed.connect(_on_respawn_pressed)
	respawn_button.visible = false
	
func _on_player_died() -> void:
	respawn_button.visible = true

func _on_respawn_pressed() -> void:
	respawn_button.visible = false
	if player:
		player.respawn()
