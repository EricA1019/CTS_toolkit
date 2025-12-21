extends Control
## Example demonstrating CTS Text UI addon features.
## Note: TooltipService must be enabled as an autoload for tooltips to work.

var _tooltip_service: Node


func _ready() -> void:
	# Get the TooltipService autoload (will be null if not enabled)
	_tooltip_service = get_node_or_null("/root/TooltipService")
	
	# Context menu example
	var context_menu = ContextMenu.new()
	context_menu.attach_to(self)
	context_menu.add_item("Show Simple Tooltip", _show_simple_tooltip)
	context_menu.add_item("Show Data Tooltip", _show_data_tooltip)
	context_menu.add_separator()
	context_menu.add_checkbox_item("Enable Feature", _toggle_feature, false, false)
	
	# Connect to a button if you have one
	if has_node("TestButton"):
		context_menu.connect_to($TestButton)


func _show_simple_tooltip() -> void:
	if not _tooltip_service:
		push_error("TooltipService autoload not found. Enable CTS Text UI plugin.")
		return
	
	var tooltip = _tooltip_service.show_tooltip(
		get_global_mouse_position(),
		TooltipPivot.Position.TOP_LEFT,
		"[b]Simple Tooltip[/b]\nThis is a basic tooltip with BBCode support!"
	)
	# Automatically release after 3 seconds
	await get_tree().create_timer(3.0).timeout
	_tooltip_service.release_tooltip(tooltip)


func _show_data_tooltip() -> void:
	if not _tooltip_service:
		push_error("TooltipService autoload not found. Enable CTS Text UI plugin.")
		return
	
	# First, set up a data provider
	var provider = TooltipDataProvider.BasicTooltipDataProvider.new()
	
	var data = TooltipData.new()
	data.id = "test_item"
	data.text = "[color=yellow]Special Item[/color]\nThis tooltip comes from a data provider!"
	data.desired_width = 200
	
	provider.add_tooltip(data)
	_tooltip_service.set_tooltip_data_provider(provider)
	
	# Show tooltip by ID
	var tooltip = _tooltip_service.show_tooltip_by_id(
		get_global_mouse_position(),
		TooltipPivot.Position.CENTER,
		"test_item"
	)
	
	# Automatically release after 3 seconds
	await get_tree().create_timer(3.0).timeout
	_tooltip_service.release_tooltip(tooltip)


func _toggle_feature() -> void:
	print("Feature toggled!")
