extends CanvasLayer


const INVENTORY_ITEM_SCENE = preload("res://scenes/GUI/CauldronUI/InventoryItem.tscn")
const CRAFTING_ROW_SCENE = preload("res://scenes/GUI/CauldronUI/CraftingRow.tscn")

@onready var crafting_list: GridContainer = $Control/CraftAreaPanel/VBoxContainer/ScrollContainer/CraftingList
@onready var inventory_grid: GridContainer = $Control/InventoryPanel/VBoxContainer/InventoryGrid
@onready var cauldron_button: TextureButton = $Control/CraftAreaPanel/CauldronButton
@onready var exit_button: TextureButton = $Control/ExitButton


var cauldron_3d: Node = null 
var selected_ingredients: Array = []  

func _ready() -> void:
	hide() 
	

	if cauldron_button:
		cauldron_button.pressed.connect(_on_cauldron_pressed)
	if exit_button:
		exit_button.pressed.connect(close_menu)


func set_cauldron(cauldron_node: Node) -> void:
	cauldron_3d = cauldron_node


func open_menu() -> void:
	show()
	selected_ingredients.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Показываем мышку
	
	
	var player = get_tree().get_first_node_in_group("player")
	if player and "controls_active" in player:
		player.controls_active = false
		
	update_ui()

func close_menu() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Прячем мышку обратно в 3D игру
	

	var player = get_tree().get_first_node_in_group("player")
	if player and "controls_active" in player:
		player.controls_active = true


func update_ui() -> void:
	
	for child in crafting_list.get_children():
		child.queue_free()
	for child in inventory_grid.get_children():
		child.queue_free()
		
	var player = get_tree().get_first_node_in_group("player")
	if not player or not "inventory" in player:
		print("UI Error: No player or inventory found!")
		return


	for item in player.inventory:
		var item_slot = INVENTORY_ITEM_SCENE.instantiate()
		inventory_grid.add_child(item_slot)
		
		var label = item_slot.get_node_or_null("Label")
		if label: label.text = str(item)
		

		item_slot.pressed.connect(_on_inventory_item_clicked.bind(item))


	for item in selected_ingredients:
		var craft_row = CRAFTING_ROW_SCENE.instantiate()
		crafting_list.add_child(craft_row)
		
		var label = craft_row.get_node_or_null("HBoxContainer/Label")
		if label: label.text = str(item)
		
		
		craft_row.pressed.connect(_on_crafting_row_clicked.bind(item))
				
	
	if cauldron_button:
		cauldron_button.disabled = selected_ingredients.is_empty()
		if selected_ingredients.is_empty():
			cauldron_button.modulate = Color(0.5, 0.5, 0.5) # Темная
		else:
			cauldron_button.modulate = Color(1.0, 1.0, 1.0) # Яркая активная

func _on_inventory_item_clicked(item: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.inventory.erase(item)
		selected_ingredients.append(item)
		update_ui()

func _on_crafting_row_clicked(item: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		selected_ingredients.erase(item)
		player.inventory.append(item)
		update_ui()


func _on_cauldron_pressed() -> void:
	if cauldron_3d and cauldron_3d.has_method("craft"):
		var ingredients_to_send = selected_ingredients.duplicate()
		selected_ingredients.clear()
		close_menu()
		cauldron_3d.craft(ingredients_to_send) # Запуск варки в 3D-котле!
