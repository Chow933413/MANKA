extends Control

var button_type = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_pressed() -> void:
	$FadeTransition.show()
	$FadeTransition/Timer.start()
	$FadeTransition/AnimationPlayer.play("FadeIn")
	FadeTransition.fade_to_next_scene("res://scenes/levels/level0.tscn")
	
	

func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_timer_timeout() -> void:
	pass
