extends CanvasLayer

@onready var heartContainer = $HeartContainer
@onready var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	heartContainer.setMaxHearts(player.max_health)
	heartContainer.updateHearts(player.current_health)
	player.health_changed.connect(heartContainer.updateHearts)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
