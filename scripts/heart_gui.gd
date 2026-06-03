extends Panel

@onready var sprite = $Sprite2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update(state: int) -> void:
	if state == 2:
		sprite.frame = 0
	elif state == 1:
		sprite.frame = 1
	else:
		sprite.frame = 2
