extends StaticBody3D

@export var ui: CanvasLayer
@export var bridge_scene: PackedScene
@export var spawn_point_path: Marker3D

@export var recipes: Dictionary = {
	"rope_wood":preload("res://scenes/surrounding/bridge.tscn")
}

func _ready() -> void:
	if ui:
		ui.set_cauldron(self)
	else:
		print("Error: You forget to drag the CauldronUI into the Inspector!")
	
func interact():
	ui.open_menu()
	
func craft(selected_slots: Array):
	var sorted_recipe = selected_slots.duplicate()
	sorted_recipe.sort()
	var combination = "_".join(sorted_recipe)

	if recipes.has(combination):
		var scene_to_spawn = recipes[combination]
		
		if spawn_point_path:
			spawn_result(scene_to_spawn, spawn_point_path.global_position, spawn_point_path.global_rotation)
		else:
			print("Error: No spawn point assigned in the Inspector!")
	else:
		print("Unknown recipe: ", combination)
		
func spawn_result(scene: PackedScene, target_pos: Vector3, target_rot: Vector3):
	var instance = scene.instantiate()
	# Add to the level root
	get_tree().current_scene.add_child(instance)
	
	# Apply the Marker's position and rotation
	instance.global_position = target_pos
	instance.global_rotation = target_rot
