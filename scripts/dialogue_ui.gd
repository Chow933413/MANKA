extends CanvasLayer

@onready var dialogue_box: Control = $DialogueBox
@onready var speaker_name: Label = $DialogueBox/SpeakerName
@onready var dialogue_text: RichTextLabel = $DialogueBox/DialogueText

@export_category("Dialogue Settings")
@export var characters_per_second: float = 30.0

var can_close: bool = false
var is_typing: bool = false
var just_skipped: bool = false
var input_shield: bool = true # NEW: Protects the typing animation from the opening keypress frame

var active_box_tween: Tween
var active_text_tween: Tween

func _ready() -> void:
	visible = false
	dialogue_box.modulate.a = 0.0
	dialogue_text.visible_ratio = 0.0
	
	DialogueManager.dialogue_opened.connect(_on_dialogue_opened)
	DialogueManager.dialogue_closed.connect(_on_dialogue_closed)

func _on_dialogue_opened(speaker: String, text: String) -> void:
	if active_box_tween: active_box_tween.kill()
	if active_text_tween: active_text_tween.kill()
		
	speaker_name.text = speaker
	dialogue_text.text = text
	
	dialogue_text.visible_ratio = 0.0 
	visible = true
	can_close = false
	is_typing = true
	just_skipped = false
	input_shield = true # Raise the shield so the opening click/keypress is completely ignored
	
	active_box_tween = create_tween()
	active_box_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	var total_characters = text.length()
	var typing_duration = total_characters / characters_per_second
	
	active_text_tween = create_tween()
	active_text_tween.tween_property(dialogue_text, "visible_ratio", 1.0, typing_duration)
	
	# Wait exactly two frames. This allows the frame that handles the "E" interaction key 
	# to completely pass before we let the player input anything inside this UI.
	await get_tree().process_frame
	await get_tree().process_frame
	input_shield = false # Drop the shield! Player can now safely skip or close.
	
	await active_text_tween.finished
	
	# If the animation finished naturally without the player skipping it:
	if not just_skipped:
		is_typing = false
		can_close = true

func _on_dialogue_closed() -> void:
	if not visible: return
	close_ui_instantly()

func close_ui_instantly() -> void:
	can_close = false
	is_typing = false
	just_skipped = false
	input_shield = true
	DialogueManager.is_dialogue_active = false
	
	if active_box_tween: active_box_tween.kill()
	if active_text_tween: active_text_tween.kill()
		
	active_box_tween = create_tween()
	active_box_tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	await active_box_tween.finished
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	# If the shield is up, ignore ALL buttons so the animation has breathing room to start!
	if not DialogueManager.is_dialogue_active or input_shield:
		return
		
	if event.is_pressed() and not event.is_echo():
		if event.is_action("left") or event.is_action("right") or \
		   event.is_action("up") or event.is_action("down") or \
		   event.is_action("attack"):
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			return
		# CASE 1: Skip typing
		if is_typing:
			get_viewport().set_input_as_handled()
			is_typing = false
			
			if active_text_tween: 
				active_text_tween.kill()
			dialogue_text.visible_ratio = 1.0
			
			# Give it one frame buffer so the skip input frame passes,
			# then immediately allow the very next press to close it!
			await get_tree().process_frame
			can_close = true
			print("Dialogue animation skipped. Next click will close.")
			return
			
		# CASE 2: Close the box directly (triggered if text finished naturally OR was skipped)
		if can_close:
			get_viewport().set_input_as_handled()
			print("Dialogue closed directly.")
			close_ui_instantly()
