extends StaticBody3D

@onready var title_label: Label3D = $title
@onready var subline_label: Label3D = $subline

@onready var interaction_prompt: Label3D = $InteractionPrompt

@export_category("World Links")
@export var invisible_border: StaticBody3D

var has_been_read: bool = false
var ui_currently_open: bool = false

func _ready() -> void:
	var detection_area = $InteractArea
	if detection_area:
		# --- CHANGED: Connect to area signals instead of body signals ---
		detection_area.area_entered.connect(_on_area_entered_range)
		detection_area.area_exited.connect(_on_area_left_range)
		
		if interaction_prompt:
			interaction_prompt.hide()
			
func _on_area_entered_range(area: Area3D) -> void:
	# Check if this area belongs to the player (checking parent group or node name)
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		print("Player's Interaction Range entered! Showing prompt.")
		if interaction_prompt:
			interaction_prompt.show()

func _on_area_left_range(area: Area3D) -> void:
	var parent_node = area.get_parent()
	if parent_node and (parent_node.is_in_group("player") or parent_node.name == "Player" or area.name == "InteractionRange"):
		print("Player's Interaction Range left! Hiding prompt.")
		if interaction_prompt:
			interaction_prompt.hide()

func interact() -> void:
	if DialogueManager.is_dialogue_active: return

	if interaction_prompt:
		interaction_prompt.hide()
	
	var speaker = "FENCE"
	var text = "This section has been blocked, try to explore other paths."
	
	DialogueManager.start_dialogue(speaker, text)
	
	if not has_been_read:
		has_been_read = true
		return
		
	while DialogueManager.is_dialogue_active:
		await get_tree().physics_frame
		
