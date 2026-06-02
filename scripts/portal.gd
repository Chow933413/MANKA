extends Area3D

@export_file("*.tscn") var target_scene: String
@export var portal_id: String
@export var target_portal_id: String

func _ready() -> void:
	await get_tree().process_frame
	
	if NavigationManager.target_portal_id == portal_id:
		spawn_player_here()

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if target_scene:
			NavigationManager.teleport_to_scene(target_scene, target_portal_id)

func spawn_player_here():
	await get_tree().process_frame
	
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.global_transform.origin = global_transform.origin
		NavigationManager.target_portal_id = ""
