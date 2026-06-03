extends Area3D

@export_file("*.tscn") var target_scene: String
@export var portal_id: String
@export var target_portal_id: String

var is_active: bool = false

func _ready() -> void:
	await get_tree().process_frame
	
	if NavigationManager.target_portal_id == portal_id:
		spawn_player_here()
	
	await get_tree().create_timer(0.5).timeout
	is_active = true

func _on_body_entered(body: Node3D) -> void:
	if not is_active: return
	
	if body.name == "Player":
		NavigationManager.saved_health_units = body.current_health_units
		NavigationManager.respawn_scene_path = get_tree().current_scene.scene_file_path
		NavigationManager.respawn_portal_id = portal_id
		
		if target_scene:
			NavigationManager.teleport_to_scene(target_scene, target_portal_id)

func spawn_player_here():
	
	await get_tree().process_frame
	
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		NavigationManager.respawn_scene_path = get_tree().current_scene.scene_file_path
		NavigationManager.respawn_portal_id = portal_id
		
		player.global_transform.origin = global_transform.origin
		NavigationManager.target_portal_id = ""
