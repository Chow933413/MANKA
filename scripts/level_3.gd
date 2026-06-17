extends Node3D

# Add an export slot so you can drag your specific marker into it via the Inspector
@export var boss_respawn_marker: Marker3D

func _ready() -> void:
	# ─── NEW: CHECK IF PLAYER RE-ENTERED ROOM VIA DEATH CHECKPOINT ───
	if NavigationManager.target_portal_id == "BOSS_ARENA_CHECKPOINT":
		spawn_player_at_boss_checkpoint()

func _process(delta: float) -> void:
	pass

func spawn_player_at_boss_checkpoint() -> void:
	# Wait one frame to let the scene hierarchy fully construct itself
	await get_tree().process_frame
	
	# Locate your player and the marker node dynamically
	var player = find_child("Player", true, false)
	var marker = boss_respawn_marker if boss_respawn_marker else get_node_or_null("BossSpawnPoint")
	
	if player and marker:
		# Teleport the player directly onto the checkpoint marker
		player.global_position = marker.global_position
		
		# Update their local internal tracking variables so falling features behave cleanly
		if "respawn_position" in player:
			player.respawn_position = marker.global_position
		if "last_safe_ground_position" in player:
			player.last_safe_ground_position = marker.global_position
			
		# Clean up target_portal_id so passing through other normal portals works later
		NavigationManager.target_portal_id = ""
		
		print("[CHECKPOINT SYSTEM] Successfully intercepted reload! Player placed at boss arena.")

func _on_boss_trigger_line_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		
		var marker = boss_respawn_marker if boss_respawn_marker else get_node_or_null("BossSpawnPoint")
		
		if marker:
			# 1. Store the current scene file path so it knows what room to reload
			NavigationManager.respawn_scene_path = get_tree().current_scene.scene_file_path
			
			# 2. Give it a unique custom string instead of a portal ID
			NavigationManager.respawn_portal_id = "BOSS_ARENA_CHECKPOINT"
			
			# 3. Update the local variable on the player just in case
			body.respawn_position = marker.global_position
			body.last_safe_ground_position = marker.global_position
			
			print("Global checkpoint updated to Boss Arena Marker!")

		# Find the Lich King in your scene tree
		var boss = get_node_or_null("LichKing") 
		if boss and boss.has_method("start_boss_fight"):
			boss.start_boss_fight()
			
			# Turn off this trigger line so it doesn't accidentally fire twice!
			if has_node("BossTriggerLine"):
				$BossTriggerLine.queue_free()
