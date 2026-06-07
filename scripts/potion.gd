extends Area3D

signal potion_collected

@export var descriptive_word: String = "Potion":
	set(value):
		descriptive_word = value
		if is_inside_tree() and has_node("Label3D"):
			$Label3D.text = value
@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.2
@export var float_speed: float =  2.0

var base_y: float
var time_passed: float = 0.0

func _ready():
	base_y = global_position.y
	
	
func play_pop_up_animation():

	var tween = create_tween()
	
	var target_y = base_y + 0.5
	
	tween.tween_property(self, "global_position:y", target_y, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.finished.connect(_on_pop_finished)

func _on_pop_finished():
	base_y = global_position.y
	

func _process(delta: float) -> void:
	$Potion.rotate_y(rotation_speed * delta)
	
	time_passed += delta
	var bob = sin(time_passed * float_speed) * float_amplitude
	global_position.y = base_y + bob

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("collect_word"):
			body.collect_word(descriptive_word)
			
		potion_collected.emit()
			
		print("Collected token: ", descriptive_word)
		queue_free()
