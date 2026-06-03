extends StaticBody3D

@onready var title_label: Label3D = $title
@onready var subline_label: Label3D = $subline

@export_category("World Links")
@export var invisible_border: StaticBody3D

var has_been_read: bool = false
var ui_currently_open: bool = false

func _ready() -> void:
	pass

func interact() -> void:
	if DialogueManager.is_dialogue_active: return
	
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
		
func open_the_border() -> void:
	if invisible_border == null: return
	
	invisible_border.process_mode = Node.PROCESS_MODE_DISABLED
	
	var border_tween = create_tween()
	border_tween.tween_property(invisible_border, "global_position:y", invisible_border.global_position.y - 10.0, 1.0)
