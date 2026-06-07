extends StaticBody3D

@export_category("Loot Settings")
@export var loot_scene: PackedScene 
@export var loot_word: String = ""

@export_category("Destruction Settings")
@export var broken_model: PackedScene

func take_damage():
	spawn_loot()
	spawn_broken_pieces()
	queue_free() # This deletes the barrel

func spawn_loot():
	if loot_scene:
		var loot = loot_scene.instantiate() 
		
		if "descriptive_word" in loot:
			loot.descriptive_word = loot_word
		
		get_parent().add_child(loot)
		loot.global_position = global_position 
		
func spawn_broken_pieces() -> void:
	if broken_model:
		var broken_model_inst: Node3D = broken_model.instantiate()
		
		get_parent().add_child(broken_model_inst)
		
		broken_model_inst.global_transform = global_transform
		
