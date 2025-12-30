class_name InventoryPage
extends BookPage

@onready var item_list: ItemList = $VBoxContainer/ItemList

func setup(event_bus: Node, data_provider: Node) -> void:
	super.setup(event_bus, data_provider)
	name = "Inventory"
	
	# Connect to ItemsSignalRegistry for updates
	var items_registry = Engine.get_singleton("ItemsSignalRegistry")
	if items_registry:
		if not items_registry.item_added.is_connected(_on_item_added):
			items_registry.item_added.connect(_on_item_added)
		if not items_registry.item_removed.is_connected(_on_item_removed):
			items_registry.item_removed.connect(_on_item_removed)

func refresh() -> void:
	if not _data_provider or not _data_provider.has_method("get_page_data"):
		return
		
	var data = _data_provider.get_page_data(&"inventory")
	_build_ui(data)

func _build_ui(data: Dictionary) -> void:
	if not item_list:
		return
		
	item_list.clear()
	
	if not data.has("items"):
		return
		
	var items = data["items"]
	for item in items:
		_add_item_to_list(item)

func _add_item_to_list(item: Object) -> void:
	if not item:
		return
		
	var display_name = "Unknown Item"
	var icon = null
	var amount = 1
	
	if item.has_method("get_display_name"):
		display_name = item.get_display_name()
	if item.has_method("get_icon"):
		icon = item.get_icon()
	if "amount" in item:
		amount = item.amount
		
	var text = "%s (x%d)" % [display_name, amount]
	item_list.add_item(text, icon)

func _on_item_added(entity_id: String, _item: Node, _slot_index: int) -> void:
	if is_for_this_entity(entity_id):
		refresh()

func _on_item_removed(entity_id: String, _item: Node, _slot_index: int) -> void:
	if is_for_this_entity(entity_id):
		refresh()
