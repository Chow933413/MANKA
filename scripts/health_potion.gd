extends Area3D

signal potion_collected

@export var descriptive_word: String = "Health Potion":
	set(value):
		descriptive_word = value
		if is_inside_tree() and has_node("Label3D"):
			$Label3D.text = value
			
@export var rotation_speed: float = 2.0
@export var float_amplitude: float = 0.2
@export var float_speed: float = 2.0

@export_category("Potion Effects")
@export var heal_amount: int = 3

# ─── CHANGED: Track local offsets instead of hard global Y coordinates ───
var visual_node: Node3D
var base_local_y: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	# Find your visual model child node safely (matches your $Potion call)
	if has_node("Potion"):
		visual_node = $Potion
		base_local_y = visual_node.position.y
	
func play_pop_up_animation() -> void:
	if not visual_node: return
	
	var tween = create_tween()
	var target_y = base_local_y + 0.5
	
	# Tween the child model locally instead of moving the whole world root!
	tween.tween_property(visual_node, "position:y", target_y, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.finished.connect(_on_pop_finished)

func _on_pop_finished() -> void:
	if visual_node:
		base_local_y = visual_node.position.y

func _process(delta: float) -> void:
	if visual_node:
		# Rotate the bottle mesh
		visual_node.rotate_y(rotation_speed * delta)
		
		# Bob the bottle mesh locally up and down relative to the parent root
		time_passed += delta
		var bob = sin(time_passed * float_speed) * float_amplitude
		visual_node.position.y = base_local_y + bob

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("collect_word"):
			body.collect_word(descriptive_word)
			
		_apply_healing(body)
			
		potion_collected.emit()
		print("Collected token: ", descriptive_word)
		queue_free()

func _apply_healing(player_node: Node3D) -> void:
	if "current_health_units" in player_node:
		var max_units: int = 14
		if "max_health" in player_node:
			max_units = player_node.max_health * 2
			
		player_node.current_health_units += heal_amount
		player_node.current_health_units = clamp(player_node.current_health_units, 0, max_units)
		
		if player_node.has_signal("health_changed"):
			player_node.health_changed.emit(player_node.current_health_units)
