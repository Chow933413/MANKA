extends Area3D

@export var descriptive_word: String = "rope":
	set(value):
		descriptive_word = value
		if is_inside_tree() and has_node("Label3D"):
			$Label3D.text = value
@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.2
@export var float_speed: float =  2.0

var base_y: float
var is_popping: bool = true
var time_passed: float = 0.0

func _ready():
	$Visuals/Meshy_AI_Solar_Lattice_Orb_0602134435_texture/Label3D.text = descriptive_word
	base_y = global_position.y
	play_pop_up_animation()
	
func play_pop_up_animation():
	is_popping = true
	var tween = create_tween()
	
	var target_y = base_y + 0.5
	
	tween.tween_property(self, "global_position:y", target_y, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.finished.connect(_on_pop_finished)

func _on_pop_finished():
	base_y = global_position.y
	is_popping = false

func _process(delta: float) -> void:
	# Rotate the visuals specifically, not the whole Area3D
	# This assumes you grouped your Mesh and Label under a node called "Visuals"
	if has_node("Visuals"):
		$Visuals.rotate_y(rotation_speed * delta)
	
	if not is_popping:
		time_passed += delta
		var bob = sin(time_passed * float_speed) * float_amplitude
		global_position.y = base_y + bob

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("collect_word"):
			body.collect_word(descriptive_word)
			
		print("Collected token: ", descriptive_word)
		queue_free()
