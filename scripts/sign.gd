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
	
	var speaker = "OLD SIGN"
	var text = "WORLD OF WORDS\n\nWords create form.\nTokens are words.\nCollect words. Create meaning."
	
	DialogueManager.start_dialogue(speaker, text)
	
	var normal_title_color = Color(0.2, 0.6, 1.0)
	var normal_sub_color = Color(0.9, 0.9, 0.9, 1.0) 
	var flash_color = Color(1.0 * 8.0, 4.0 * 8.0, 6.0 * 8.0)
	
	var text_tween = create_tween()
	
	text_tween.tween_property(title_label, "outline_modulate", flash_color, 0.1)
	text_tween.tween_property(title_label, "outline_modulate", normal_title_color, 0.3)

	text_tween.tween_property(subline_label, "modulate", normal_sub_color, 0.6).set_trans(Tween.TRANS_SINE)
	
	if not has_been_read:
		has_been_read = true
		open_the_border()
		
	while DialogueManager.is_dialogue_active:
		await get_tree().physics_frame
		
	# Check if the player area is still inside our InteractArea before reshowing
	var player_area = get_tree().get_first_node_in_group("player")
	if player_area:
		# If the group is on the character body, find its InteractionRange area node
		var range_node = player_area.get_node_or_null("InteractionRange")
		if range_node and $InteractArea.overlaps_area(range_node):
			if interaction_prompt:
				interaction_prompt.show()
		
func open_the_border() -> void:
	if invisible_border == null: return
	
	invisible_border.process_mode = Node.PROCESS_MODE_DISABLED
	
	var border_tween = create_tween()
	border_tween.tween_property(invisible_border, "global_position:y", invisible_border.global_position.y - 10.0, 1.0)
