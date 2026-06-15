extends Control

@onready var main_menu_button: Button = $VBoxContainer/mainmenu
@onready var quit_button: Button = $VBoxContainer/quit

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Start with buttons completely invisible so the player absorbs "THE END" first
	main_menu_button.modulate.a = 0.0
	quit_button.modulate.a = 0.0
	
	# Connect your button signals cleanly
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Animate the buttons fading in gently after a brief pause
	_fade_in_buttons()

func _fade_in_buttons() -> void:
	await get_tree().create_timer(0.7).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_property(main_menu_button, "modulate:a", 1.0, 1.0)
	tween.tween_property(quit_button, "modulate:a", 1.0, 1.0)

func _on_main_menu_pressed() -> void:
	main_menu_button.disabled = true
	
	var custom_canvas = get_parent()
	if custom_canvas and custom_canvas is CanvasLayer:
		custom_canvas.queue_free()
	
	if typeof(FadeTransition) != TYPE_NIL:
		FadeTransition.fade_to_next_scene("res://scenes/Menu/MainMenu.tscn") 
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
