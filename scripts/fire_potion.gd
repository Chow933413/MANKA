extends Area3D

@export var descriptive_word: String = "Fire Potion":
	set(value):
		descriptive_word = value
		if is_inside_tree() and has_node("Label3D"):
			$Visuals/Potion_low_Potion_0/Label3D.text = value
@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.2
@export var float_speed: float =  2.0

var base_y: float
var is_popping: bool = true
var time_passed: float = 0.0

func _ready():
	pass
	

func _process(delta: float) -> void:
	# Rotate the visuals specifically, not the whole Area3D
	# This assumes you grouped your Mesh and Label under a node called "Visuals"
	if has_node("Visuals"):
		$Visuals.rotate_y(rotation_speed * delta)
	

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("collect_word"):
			body.collect_word(descriptive_word)
			
		print("Collected token: ", descriptive_word)
		queue_free()
