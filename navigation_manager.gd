extends Node

# Stores the name or ID of the portal the player should spawn at
var target_portal_id: String = ""
var respawn_scene_path: String = ""
var respawn_portal_id: String = ""
var saved_health_units: int = -1

func teleport_to_scene(scene_path: String, portal_id: String):
	target_portal_id = portal_id
	get_tree().change_scene_to_file(scene_path)
