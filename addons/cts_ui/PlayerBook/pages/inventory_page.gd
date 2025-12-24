class_name InventoryPage
extends BookPage

@onready var item_list: ItemList = $VBoxContainer/ItemList

func setup(event_bus: Node, data_provider: Node) -> void:
	name = "Inventory"
	# Wait for node to be ready before adding items
	if is_node_ready():
		_add_test_items()
	else:
		await ready
		_add_test_items()

func _add_test_items() -> void:
	if not item_list:
		push_error("[InventoryPage] ItemList node not found!")
		return
	item_list.clear()
	item_list.add_item("Iron Sword")
	item_list.add_item("Health Potion x3")
	item_list.add_item("Leather Armor")
	item_list.add_item("Gold Coins x50")
	item_list.add_item("Magic Scroll")
