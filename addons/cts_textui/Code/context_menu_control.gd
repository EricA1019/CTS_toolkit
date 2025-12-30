@tool
@icon("res://addons/cts_textui/Assets/Icon.png")
class_name TooltipContextMenuControl
extends Control
## A control node that sets up a context menu from exported entries.

@export_category("Context Menu Settings")
@export var node_to_connect: Control
@export var minimum_size: Vector2i = Vector2i.ZERO
@export var position_mode: TooltipContextMenu.PositionMode = TooltipContextMenu.PositionMode.CURSOR
@export var menu_entries: Array[TooltipContextMenuEntry] = []

var context_menu: TooltipContextMenu


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		_setup_menu()


func _setup_submenu(menu: TooltipContextMenu, item: TooltipContextMenuEntry) -> void:
	var submenu := menu.add_submenu(item.label)
	
	for entry in item.submenu_entries:
		var action_target: Node = get_node_or_null(entry.action_target) if entry.action_target else null
		
		match entry.item_type:
			TooltipContextMenuEntry.EntryType.SEPARATOR:
				submenu.add_separator()
			
			TooltipContextMenuEntry.EntryType.SUBMENU:
				_setup_submenu(submenu, entry)
			
			TooltipContextMenuEntry.EntryType.CHECKBOX:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				submenu.add_checkbox_item(entry.label, callback, entry.disabled, entry.is_checked, entry.icon)
			
			TooltipContextMenuEntry.EntryType.ITEM:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				submenu.add_item(entry.label, callback, entry.disabled, entry.icon)


func _setup_menu() -> void:
	context_menu = TooltipContextMenu.new()
	context_menu.attach_to(self)
	context_menu.set_minimum_size(minimum_size)
	context_menu.set_position_mode(position_mode)
	
	for entry in menu_entries:
		var action_target: Node = get_node_or_null(entry.action_target) if entry.action_target else null
		
		match entry.item_type:
			TooltipContextMenuEntry.EntryType.SEPARATOR:
				context_menu.add_separator()
			
			TooltipContextMenuEntry.EntryType.SUBMENU:
				_setup_submenu(context_menu, entry)
			
			TooltipContextMenuEntry.EntryType.CHECKBOX:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				context_menu.add_checkbox_item(entry.label, callback, entry.disabled, entry.is_checked, entry.icon)
			
			TooltipContextMenuEntry.EntryType.ITEM:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				context_menu.add_item(entry.label, callback, entry.disabled, entry.icon)
		
		if node_to_connect:
			context_menu.connect_to(node_to_connect)
