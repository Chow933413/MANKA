extends CanvasLayer

var current_cauldron: Node3D
var slots = ["", ""] # 2 slot memory

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_menu()

func _ready():
	visible = false
	
func set_cauldron(c):
	current_cauldron = c
	
func open_menu():
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Find the player and freeze them
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.state_machine.dispatch("to_locked")
		update_inventory_buttons(player.inventory)
		
func update_inventory_buttons(inventory: Array):
	# 1. Clear the VBoxContainer (or whatever container holds your buttons)
	for child in $Panel/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	
	# 2. Create a button for every single token the player has
	for word in inventory:
		var btn = Button.new()
		btn.text = word
		
		btn.mouse_filter = Control.MOUSE_FILTER_STOP # Ensures the button catches the click
		btn.focus_mode = Control.FOCUS_NONE         # Prevents the button from "trapping" focus
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL    # Ensures the button has a clickable area
		
		# We use a lambda to pass the specific word of THIS button
		btn.pressed.connect(func(): _on_token_selected(word))
		$Panel/ScrollContainer/VBoxContainer.add_child(btn)
		
func _on_token_selected(item: String):
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var already_slotted = slots.count(item)
	var player_has = player.inventory.count(item)
	
	if already_slotted >= player_has:
		print("You don't have another " + item + " token!")
		return
		
	if slots[0] == "":
		fill_slot(0, item)
	elif slots[1] == "":
		fill_slot(1, item)
	else:
		print("Both slots are full!")
	
func fill_slot(index: int, word: String):
	slots[index] = word
	
	# fill in the text of the button
	var btn = $Panel/HBoxContainer.get_child(index)
	btn.text = word
	
func _on_create_button_pressed():
	var player = get_tree().get_first_node_in_group("player")
	
	if slots[0] != "" and slots[1] != "":
		current_cauldron.craft(slots)
		
		player.consume_tokens(slots[0], slots[1])
		
		close_menu()
		
func close_menu():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	slots = ["", ""]
	var slot1 = $Panel/HBoxContainer.get_child(0)
	var slot2 = $Panel/HBoxContainer.get_child(1)
	
	if slot1:
		slot1.text = "Empty" 
	if slot2:
		slot2.text = "Empty"
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.state_machine.dispatch("to_idle")
	
func _on_close_pressed() -> void:
	close_menu()
