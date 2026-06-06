extends HBoxContainer

@onready var HeartGUIClass = preload("res://scenes/GUI/HUD/heart_gui.tscn")

func setMaxHearts(max_health: int):
	for child in get_children():
		child.queue_free()
		
	for i in range(max_health):
		var heart = HeartGUIClass.instantiate()
		add_child(heart)
		
		
func updateHearts(current_health_units: int):
	if get_child_count() == 0:
		await get_tree().process_frame
	print("--- HeartContainer received value: ", current_health_units)
	var hearts = get_children()
	
	if current_health_units <= 0:
		for heart in hearts:
			if heart.has_method("update"):
				heart.update(0)
		return
	
	for i in range(hearts.size()):
		# The health value required to fill up to this SPECIFIC heart container slot
		var heart_index_value = (i * 2) + 2
		
		if current_health_units >= heart_index_value:
			# Fully above or equal to the threshold layer
			hearts[i].update(2)
		elif current_health_units >= (heart_index_value - 1):
			# It failed the full check, but it's still above the half-way line!
			hearts[i].update(1)
		else:
			# Completely below the threshold step requirement
			hearts[i].update(0)
