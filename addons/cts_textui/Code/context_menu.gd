class_name ContextMenu
extends Control
## A wrapper class for PopupMenu that provides a convenient context menu API.

enum PositionMode {
	CURSOR = 0,
	NODE_CENTER,
	NODE_BOTTOM
}

var _menu: PopupMenu
var _current_position_mode: PositionMode = PositionMode.CURSOR
var _actions: Dictionary = {}  # int -> Callable
var _checkbox_actions: Dictionary = {}  # int -> Callable
var _next_id: int = 0


func _init() -> void:
	_menu = PopupMenu.new()
	_menu.hide()
	_menu.id_pressed.connect(_on_item_pressed)


## Attach the context menu to a parent node.
## Uses call_deferred to avoid errors when parent is setting up children.
func attach_to(parent: Node) -> void:
	parent.add_child.call_deferred(_menu, true)


## Add a regular menu item.
func add_item(label: String, callback: Callable = Callable(), disabled_item: bool = false, icon_texture: Texture2D = null) -> void:
	_menu.add_item(label, _next_id)
	_menu.set_item_disabled(_next_id, disabled_item)
	
	if icon_texture:
		_menu.set_item_icon(_next_id, icon_texture)
	
	if callback.is_valid():
		_actions[_next_id] = callback
	
	_next_id += 1


## Add a checkbox menu item.
func add_checkbox_item(label: String, callback: Callable = Callable(), disabled_item: bool = false, checked: bool = false, icon_texture: Texture2D = null) -> void:
	_menu.add_check_item(label, _next_id)
	_menu.set_item_disabled(_next_id, disabled_item)
	_menu.set_item_checked(_next_id, checked)
	
	if icon_texture:
		_menu.set_item_icon(_next_id, icon_texture)
	
	if callback.is_valid():
		_checkbox_actions[_next_id] = callback
	
	_next_id += 1


## Add a placeholder item (no action).
func add_placeholder_item(label: String, disabled_item: bool = false, icon_texture: Texture2D = null) -> void:
	_menu.add_item(label, _next_id)
	_menu.set_item_disabled(_next_id, disabled_item)
	
	if icon_texture:
		_menu.set_item_icon(_next_id, icon_texture)
	
	_next_id += 1


## Add a separator.
func add_separator() -> void:
	_menu.add_separator()


## Connect the context menu to a control (shows on right-click).
func connect_to(node: Control) -> void:
	node.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				show_menu(node)
	)


## Set the minimum size of the menu.
func set_minimum_size(size: Vector2i) -> void:
	_menu.size = size


## Set an item's disabled state by ID or label.
func set_item_disabled(id: Variant, disabled_item: bool) -> void:
	if id is int:
		_menu.set_item_disabled(id, disabled_item)
	elif id is String:
		for i in range(_menu.get_item_count()):
			if _menu.get_item_text(i) == id:
				_menu.set_item_disabled(i, disabled_item)
				break


## Set an item's checked state by ID or label.
func set_item_checked(id: Variant, checked: bool) -> void:
	if id is int:
		_menu.set_item_checked(id, checked)
	elif id is String:
		for i in range(_menu.get_item_count()):
			if _menu.get_item_text(i) == id:
				_menu.set_item_checked(i, checked)
				break


## Set the position mode for the menu.
func set_position_mode(mode: PositionMode) -> void:
	_current_position_mode = mode


## Add a submenu and return it.
func add_submenu(label: String) -> ContextMenu:
	var submenu := ContextMenu.new()
	submenu.name = "submenu_%d" % _next_id
	
	_menu.add_child(submenu._menu)
	_menu.add_submenu_node_item(label, submenu._menu)
	
	_next_id += 1
	return submenu


## Update an item's label by ID or current label.
func update_item_label(id: Variant, new_label: String) -> void:
	if id is int:
		_menu.set_item_text(id, new_label)
	elif id is String:
		for i in range(_menu.get_item_count()):
			if _menu.get_item_text(i) == id:
				_menu.set_item_text(i, new_label)
				break


## Show the menu at the appropriate position.
## Accepts any CanvasItem (Control or Node2D) as parent.
func show_menu(parent: CanvasItem) -> void:
	var position: Vector2
	
	match _current_position_mode:
		PositionMode.CURSOR:
			# Use viewport mouse position - already in screen coordinates
			position = parent.get_viewport().get_mouse_position()
		PositionMode.NODE_CENTER:
			# For Node2D, use global_position; for Control, use rect center
			if parent is Control:
				var ctrl := parent as Control
				position = ctrl.get_global_rect().get_center()
			else:
				position = _world_to_screen(parent, parent.global_position)
		PositionMode.NODE_BOTTOM:
			# For Node2D, offset from global_position; for Control, use rect bottom
			if parent is Control:
				var ctrl := parent as Control
				var rect: Rect2 = ctrl.get_global_rect()
				position = Vector2(rect.position.x, rect.position.y + rect.size.y)
			else:
				# Approximate bottom for Node2D (offset in world, then transform)
				var world_pos: Vector2 = parent.global_position + Vector2(0, 16)
				position = _world_to_screen(parent, world_pos)
		_:
			position = parent.get_viewport().get_mouse_position()
	
	_menu.position = Vector2i(position)
	_menu.popup()


## Transform world coordinates to screen coordinates for Node2D parents.
## Takes into account camera position, zoom, and viewport transform.
func _world_to_screen(parent: CanvasItem, world_pos: Vector2) -> Vector2:
	var canvas_transform := parent.get_canvas_transform()
	return canvas_transform * world_pos


func _on_item_pressed(id: int) -> void:
	if _checkbox_actions.has(id) and _checkbox_actions[id] is Callable:
		var callback: Callable = _checkbox_actions[id]
		_menu.set_item_checked(id, not _menu.is_item_checked(id))
		var is_checked := _menu.is_item_checked(id)
		if callback.is_valid():
			callback.call_deferred(is_checked)
	elif _actions.has(id) and _actions[id] is Callable:
		var callback: Callable = _actions[id]
		if callback.is_valid():
			callback.call_deferred()
