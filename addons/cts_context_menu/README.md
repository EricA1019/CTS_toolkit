# CTS Context Menu

A GDScript context menu addon for Godot 4.5+.

**Original Author:** Daniel Schimion ([GDContextMenu](https://github.com/DanielSchimworski/GDContextMenu))  
**Fork Maintainer:** CTS Team  
**Version:** 1.1

## Overview

This is a GDScript fork of the original C# GDContextMenu addon. It provides a convenient wrapper around Godot's `PopupMenu` with support for:

- Regular menu items with callbacks
- Checkbox items with toggle state
- Separators
- Nested submenus
- Flexible positioning (cursor, node center, node bottom)
- Both programmatic and node-based setup

## Installation

1. Copy the `cts_context_menu` folder to your project's `addons/` directory
2. Enable the plugin in Project → Project Settings → Plugins

---

## API Reference

### ContextMenu

The main wrapper class for creating and managing context menus programmatically.

```gdscript
class_name ContextMenu
extends Control
```

#### Enums

```gdscript
enum PositionMode {
    CURSOR = 0,      # Show at mouse cursor position
    NODE_CENTER,     # Show at center of connected node
    NODE_BOTTOM      # Show at bottom of connected node
}
```

#### Methods

| Method | Description |
|--------|-------------|
| `attach_to(parent: Node) -> void` | Attach the context menu to a parent node (uses call_deferred, required before showing) |
| `add_item(label: String, callback: Callable = Callable(), disabled_item: bool = false, icon_texture: Texture2D = null) -> void` | Add a regular menu item |
| `add_checkbox_item(label: String, callback: Callable = Callable(), disabled_item: bool = false, checked: bool = false, icon_texture: Texture2D = null) -> void` | Add a checkbox menu item (callback receives `is_checked: bool`) |
| `add_placeholder_item(label: String, disabled_item: bool = false, icon_texture: Texture2D = null) -> void` | Add an item with no action |
| `add_separator() -> void` | Add a visual separator line |
| `add_submenu(label: String) -> ContextMenu` | Add a submenu and return it for further configuration |
| `connect_to(node: Control) -> void` | Auto-show menu on right-click of the specified control |
| `show_menu(parent: CanvasItem) -> void` | Manually show the menu (accepts Control or Node2D) |
| `set_minimum_size(size: Vector2i) -> void` | Set minimum menu dimensions |
| `set_position_mode(mode: PositionMode) -> void` | Set where menu appears |
| `set_item_disabled(id: Variant, disabled_item: bool) -> void` | Enable/disable item by ID (int) or label (String) |
| `set_item_checked(id: Variant, checked: bool) -> void` | Set checkbox state by ID (int) or label (String) |
| `update_item_label(id: Variant, new_label: String) -> void` | Change item text by ID (int) or label (String) |

---

### ContextMenuEntry

A resource for defining menu entries declaratively (used with `ContextMenuControl`).

```gdscript
@tool
class_name ContextMenuEntry
extends Resource
```

#### Enums

```gdscript
enum EntryType {
    ITEM,        # Regular clickable item
    SEPARATOR,   # Visual separator
    CHECKBOX,    # Toggle checkbox item
    SUBMENU      # Nested submenu container
}
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `item_type` | `EntryType` | `ITEM` | The type of menu entry |
| `label` | `String` | `""` | Display text for the item |
| `action_target` | `NodePath` | `""` | Path to node containing the callback method |
| `action_method` | `String` | `""` | Name of method to call when item is clicked |
| `disabled` | `bool` | `false` | Whether the item is grayed out and unclickable |
| `is_checked` | `bool` | `false` | Initial checked state (checkbox items only) |
| `icon` | `Texture2D` | `null` | Optional icon displayed beside label |
| `submenu_entries` | `Array[ContextMenuEntry]` | `[]` | Child entries for submenu items |

---

### ContextMenuControl

A node for setting up context menus via the inspector without code.

```gdscript
@tool
class_name ContextMenuControl
extends Control
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `node_to_connect` | `Control` | `null` | The control that triggers the menu on right-click |
| `minimum_size` | `Vector2i` | `Vector2i.ZERO` | Minimum menu dimensions |
| `position_mode` | `ContextMenu.PositionMode` | `CURSOR` | Where the menu appears |
| `menu_entries` | `Array[ContextMenuEntry]` | `[]` | List of menu entries to display |

---

## Usage Examples

### Programmatic Approach

Create and configure a context menu entirely in code:

```gdscript
extends Control

var context_menu: ContextMenu


func _ready() -> void:
    context_menu = ContextMenu.new()
    context_menu.attach_to(self)
    context_menu.set_minimum_size(Vector2i(150, 0))
    
    # Add items
    context_menu.add_item("Inspect", _on_inspect)
    context_menu.add_item("Talk", _on_talk)
    context_menu.add_separator()
    
    # Add submenu
    var actions_submenu := context_menu.add_submenu("Actions")
    actions_submenu.add_item("Attack", _on_attack)
    actions_submenu.add_item("Flee", _on_flee)
    
    context_menu.add_separator()
    context_menu.add_checkbox_item("Show Details", _on_toggle_details, false, false)
    
    # Auto-show on right-click
    context_menu.connect_to(self)


func _on_inspect() -> void:
    print("Inspecting...")


func _on_talk() -> void:
    print("Talking...")


func _on_attack() -> void:
    print("Attacking!")


func _on_flee() -> void:
    print("Fleeing!")


func _on_toggle_details(is_checked: bool) -> void:
    print("Show details: ", is_checked)
```

### Node-Based Approach

Set up a context menu using the inspector:

1. Add a `ContextMenuControl` node to your scene
2. Set `node_to_connect` to the control that should trigger the menu
3. Add `ContextMenuEntry` resources to `menu_entries`
4. For each entry, set `action_target` to the node with the callback and `action_method` to the method name

```gdscript
# Your script only needs the callback methods
extends Control


func _on_menu_action() -> void:
    print("Menu action triggered!")


func _on_checkbox_toggled(is_checked: bool) -> void:
    print("Checkbox is now: ", is_checked)
```

### Manual Show (Custom Trigger)

Show the menu from custom input handling:

```gdscript
extends Node2D

var context_menu: ContextMenu


func _ready() -> void:
    context_menu = ContextMenu.new()
    context_menu.attach_to(self)
    context_menu.add_item("Custom Action", _on_action)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
            if _is_mouse_over():
                context_menu.show_menu(self)
                get_viewport().set_input_as_handled()


func _is_mouse_over() -> bool:
    # Your hit detection logic
    return true


func _on_action() -> void:
    print("Custom action!")
```

---

## License

MIT License - See original [GDContextMenu](https://github.com/DanielSchimworski/GDContextMenu) for details.
