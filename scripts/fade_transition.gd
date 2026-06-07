extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide() # Make sure it starts hidden on game boot

func fade_to_next_scene(target_scene: String) -> void:
	show()
	anim_player.play("FadeIn")
	await anim_player.animation_finished # Wait until the screen is completely black
	
	get_tree().change_scene_to_file(target_scene)
	
	await get_tree().process_frame
	
	anim_player.play("FadeOut")
	await anim_player.animation_finished
	hide()
