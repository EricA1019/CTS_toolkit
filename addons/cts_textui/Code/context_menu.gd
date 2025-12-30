class_name TooltipContextMenu
extends Control
## A wrapper class for PopupMenu that provides a convenient context menu API.

enum PositionMode {
	CURSOR = 0,
	NODE_CENTER,
	NODE_BOTTOM
}

var _menu: ContextPopupMenu
var _current_position_mode: PositionMode = PositionMode.CURSOR
var _actions: Dictionary = {}  # int -> Callable
var _checkbox_actions: Dictionary = {}  # int -> Callable
var _next_id: int = 0

# Numeric-key helper state
var _listening_for_keys: bool = false
var _prev_numeric_down: Array = []
var _input_catcher: Control = null


func _init() -> void:
	_menu = ContextPopupMenu.new()
	_menu.hide()
	_menu.id_pressed.connect(_on_item_pressed)
	_menu.numeric_pressed.connect(func(index: int) -> void:
		print("[TooltipContextMenu] numeric_pressed from menu: ", index + 1)
		trigger_item_by_index(index)
	)
	# We'll use a short process loop as a fallback to capture numeric key presses while the menu is visible
	_listening_for_keys = false
	_prev_numeric_down = []


## Attach the context menu to a parent node.
## Uses call_deferred to avoid errors when parent is setting up children.
func attach_to(parent: Node) -> void:
	# Add the popup to the current scene deferred so it is in the GUI root
	var tree := Engine.get_main_loop() as SceneTree
	var scene := tree.current_scene
	if scene:
		# Prefer attaching menus to a UI root if available (Control) so popup is visible
		var ui_root := scene.get_node_or_null("UnifiedUI")
		if ui_root and ui_root is Control:
			ui_root.call_deferred("add_child", _menu)
			# create an input catcher control once under the UI root to capture key gui_input
			if not _input_catcher:
				_input_catcher = Control.new()
				_input_catcher.name = "_context_menu_input_catcher"
				# full screen anchors
				_input_catcher.anchor_left = 0.0
				_input_catcher.anchor_top = 0.0
				_input_catcher.anchor_right = 1.0
				_input_catcher.anchor_bottom = 1.0
				_input_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_input_catcher.visible = false
				# connect gui_input to our handler
				_input_catcher.gui_input.connect(_on_input_catcher_gui_input)
				ui_root.call_deferred("add_child", _input_catcher)
		else:
			scene.call_deferred("add_child", _menu)
	else:
		# fallback: defer add to provided parent
		parent.call_deferred("add_child", _menu)


## Add a regular menu item.
func add_item(label: String, callback: Callable = Callable(), disabled_item: bool = false, icon_texture: Texture2D = null) -> void:
	_menu.add_item(label, _next_id)
	_menu.set_item_disabled(_next_id, disabled_item)
	
	# Add number shortcut (1-9)
	var item_index = _menu.get_item_count() - 1
	if item_index < 9:
		var shortcut = Shortcut.new()
		var event = InputEventKey.new()
		event.keycode = KEY_1 + item_index
		event.physical_keycode = KEY_1 + item_index # Set physical too just in case
		shortcut.events.append(event)
		_menu.set_item_shortcut(_next_id, shortcut, true) # true = global
		print("[TooltipContextMenu] Added shortcut for item ", label, ": Key ", event.keycode)
	
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
func add_submenu(label: String) -> TooltipContextMenu:
	var submenu := TooltipContextMenu.new()
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
	print("[TooltipContextMenu] show_menu: parent=", parent, " position=", position, " item_count=", _menu.get_item_count(), " menu_parent=", _menu.get_parent())
	_menu.popup()
	# Start listening for numeric keys while menu is visible
	_listening_for_keys = true
	_prev_numeric_down = []
	for i in range(9):
		_prev_numeric_down.append(false)
	# show and enable input catcher if available; create if UI root exists now
	if not _input_catcher:
		var tree := Engine.get_main_loop() as SceneTree
		var scene := tree.current_scene
		if scene:
			var ui_root := scene.get_node_or_null("UnifiedUI")
			if ui_root and (ui_root is Control or ui_root is CanvasLayer):
				_input_catcher = Control.new()
				_input_catcher.name = "_context_menu_input_catcher"
				_input_catcher.anchor_left = 0.0
				_input_catcher.anchor_top = 0.0
				_input_catcher.anchor_right = 1.0
				_input_catcher.anchor_bottom = 1.0
				_input_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_input_catcher.visible = false
				# Allow it to grab focus for keyboard input
				_input_catcher.focus_mode = Control.FOCUS_ALL
				_input_catcher.gui_input.connect(_on_input_catcher_gui_input)
				ui_root.call_deferred("add_child", _input_catcher)
			else:
				print("[TooltipContextMenu] No UnifiedUI found on scene. Children:")
				for c in scene.get_children():
					print("  - ", c.name, " (", c.get_class(), ")")
				
		else:
			print("[TooltipContextMenu] No current scene found when creating input_catcher")

	if _input_catcher:
		_input_catcher.visible = true
		_input_catcher.call_deferred("grab_focus")
		print("[TooltipContextMenu] input_catcher.has_focus=", _input_catcher.has_focus())
	else:
		_menu.grab_focus()
	# Log visibility after popup
	print("[TooltipContextMenu] popup called; visible=", _menu.visible, " menu_has_focus=", _menu.has_focus(), " input_catcher=", _input_catcher != null)


## Check if the menu is currently visible.
func is_menu_visible() -> bool:
	return _menu.visible


## Trigger an item by its index (0-based).
func trigger_item_by_index(index: int) -> void:
	if index < 0 or index >= _menu.item_count:
		return
	
	var id := _menu.get_item_id(index)
	
	# Check if item is disabled or separator
	if _menu.is_item_disabled(index) or _menu.is_item_separator(index):
		return
		
	print("[TooltipContextMenu] trigger_item_by_index: index=", index, " id=", id)
	_on_item_pressed(id)
	_menu.hide()
	# stop listening
	_listening_for_keys = false


## Transform world coordinates to screen coordinates for Node2D parents.
## Takes into account camera position, zoom, and viewport transform.
func _world_to_screen(parent: CanvasItem, world_pos: Vector2) -> Vector2:
	var canvas_transform := parent.get_canvas_transform()
	return canvas_transform * world_pos


func _on_item_pressed(id: int) -> void:
	print("[TooltipContextMenu] Item pressed id=", id)
	# Try to print item text for better diagnostics
	for i in range(_menu.get_item_count()):
		if _menu.get_item_id(i) == id:
			print("[TooltipContextMenu] Item text=", _menu.get_item_text(i))
			break
	
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


func _on_input_catcher_gui_input(event: InputEvent) -> void:
	print("[TooltipContextMenu] input_catcher event=", event.get_class())
	# Handle numeric keys via the input catcher control
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = event.keycode - KEY_1
			print("[TooltipContextMenu] input_catcher numeric key pressed: ", index + 1)
			trigger_item_by_index(index)
			event.accept()


# Process loop used to capture numeric keys while popup visible
func _process(delta: float) -> void:
	if not _listening_for_keys:
		set_process(false)
		return
	
	# Fallback scan (may not pick up simulated key events reliably)
	for i in range(9):
		var keycode := KEY_1 + i
		var down := Input.is_key_pressed(keycode)
		if down and not _prev_numeric_down[i]:
			print("[TooltipContextMenu] Numeric key pressed detected in process: ", i + 1)
			trigger_item_by_index(i)
		_prev_numeric_down[i] = down
	
	# If menu hidden, stop listening
	if not _menu.visible:
		_listening_for_keys = false
		# hide input catcher if present
		if _input_catcher:
			_input_catcher.visible = false
		set_process(false)
