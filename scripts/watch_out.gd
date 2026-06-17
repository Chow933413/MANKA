extends Area3D

@export_category("Tutorial Message")
@export_multiline var message_text: String = "There's some REWARDS on the left"

func _ready() -> void:
	# Connect both entry and exit signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	var player = area.get_parent()
	if player and player.has_node("Label3D"):
		var alert_label = player.get_node("Label3D")
		
		# Show the text over the player's head immediately
		alert_label.text = message_text
		alert_label.visible = true
		alert_label.modulate.a = 1.0
		alert_label.scale = Vector3.ONE

func _on_area_exited(area: Area3D) -> void:
	var player = area.get_parent()
	if player and player.has_node("Label3D"):
		var alert_label = player.get_node("Label3D")
		
		# Cleanly fade out and hide the label the moment they step away
		var tween = create_tween()
		tween.tween_property(alert_label, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func(): alert_label.visible = false)
