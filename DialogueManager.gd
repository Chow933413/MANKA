extends Node


signal dialogue_opened(speaker: String, text: String)
signal dialogue_closed

var is_dialogue_active: bool = false

func start_dialogue(speaker: String, text: String) -> void:
	is_dialogue_active = true
	dialogue_opened.emit(speaker, text)
	
func end_dialogue() -> void:
	is_dialogue_active = false
	dialogue_closed.emit()
	
