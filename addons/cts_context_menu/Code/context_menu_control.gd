@tool
@icon("res://addons/cts_context_menu/Assets/Icon.png")
class_name ContextMenuControl
extends Control
## A control node that sets up a context menu from exported entries.

@export_category("Context Menu Settings")
@export var node_to_connect: Control
@export var minimum_size: Vector2i = Vector2i.ZERO
@export var position_mode: ContextMenu.PositionMode = ContextMenu.PositionMode.CURSOR
@export var menu_entries: Array[ContextMenuEntry] = []

var context_menu: ContextMenu


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		_setup_menu()


func _setup_submenu(menu: ContextMenu, item: ContextMenuEntry) -> void:
	var submenu := menu.add_submenu(item.label)
	
	for entry in item.submenu_entries:
		var action_target: Node = get_node_or_null(entry.action_target) if entry.action_target else null
		
		match entry.item_type:
			ContextMenuEntry.EntryType.SEPARATOR:
				submenu.add_separator()
			
			ContextMenuEntry.EntryType.SUBMENU:
				_setup_submenu(submenu, entry)
			
			ContextMenuEntry.EntryType.CHECKBOX:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				submenu.add_checkbox_item(entry.label, callback, entry.disabled, entry.is_checked, entry.icon)
			
			ContextMenuEntry.EntryType.ITEM:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				submenu.add_item(entry.label, callback, entry.disabled, entry.icon)


func _setup_menu() -> void:
	context_menu = ContextMenu.new()
	context_menu.attach_to(self)
	context_menu.set_minimum_size(minimum_size)
	context_menu.set_position_mode(position_mode)
	
	for entry in menu_entries:
		var action_target: Node = get_node_or_null(entry.action_target) if entry.action_target else null
		
		match entry.item_type:
			ContextMenuEntry.EntryType.SEPARATOR:
				context_menu.add_separator()
			
			ContextMenuEntry.EntryType.SUBMENU:
				_setup_submenu(context_menu, entry)
			
			ContextMenuEntry.EntryType.CHECKBOX:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				context_menu.add_checkbox_item(entry.label, callback, entry.disabled, entry.is_checked, entry.icon)
			
			ContextMenuEntry.EntryType.ITEM:
				if action_target and not action_target.has_method(entry.action_method):
					push_error("Target node does not have method '%s'" % entry.action_method)
				
				var callback := Callable()
				if action_target and entry.action_method:
					callback = Callable(action_target, entry.action_method)
				
				context_menu.add_item(entry.label, callback, entry.disabled, entry.icon)
		
		if node_to_connect:
			context_menu.connect_to(node_to_connect)
