@tool
class_name InventoryGridPage
extends BookPage

## Page displaying inventory grid with filtering

var _grid: InventoryGrid
var _search_bar: LineEdit

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	if get_child_count() > 0: return
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	_search_bar = LineEdit.new()
	_search_bar.placeholder_text = "Search..."
	_search_bar.text_changed.connect(_on_search_changed)
	vbox.add_child(_search_bar)
	
	_grid = InventoryGrid.new()
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.columns_count = 6
	vbox.add_child(_grid)

func setup(event_bus: Node, data_provider: Node) -> void:
	super.setup(event_bus, data_provider)
	
	if data_provider.has_method("get_inventory_container"):
		var inv = data_provider.get_inventory_container()
		if inv:
			_grid.bind_to_inventory(inv)

func _on_search_changed(text: String) -> void:
	# Filter logic would go here
	pass
