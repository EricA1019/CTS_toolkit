# CTS Text UI Plugin

Unified text-based UI system for Godot, combining context menus and nested tooltips.

## Features

### Context Menus
- Easy-to-use context menu system
- Support for submenus, checkboxes, separators
- Flexible positioning modes (cursor, node center, node bottom)
- Connect to any Control node with right-click

### Nested Tooltips
- Rich text tooltips with BBCode support
- Nested tooltip support (tooltips within tooltips)
- Lock/unlock behaviors (hover-based or action-based)
- Customizable appearance and timing
- Data provider system for managing tooltip content

## Usage

### Context Menus

```gdscript
# Create a context menu
var menu := ContextMenu.new()
menu.attach_to(self)

# Add items
menu.add_item("Option 1", func(): print("Option 1 clicked"))
menu.add_separator()
menu.add_checkbox_item("Toggle", func(): print("Toggled"))

# Connect to a control (shows on right-click)
menu.connect_to($SomeControl)

# Show manually
menu.show_menu($SomeControl)
```

### Tooltips

```gdscript
# Show a simple tooltip
var tooltip := TooltipService.show_tooltip(
	Vector2(100, 100),
	TooltipPivot.Position.TOP_LEFT,
	"[b]Hello[/b] World!"
)

# Show tooltip from data provider
TooltipService.show_tooltip_by_id(
	Vector2(200, 200),
	TooltipPivot.Position.CENTER,
	"item_sword"
)

# Release tooltip when done
TooltipService.release_tooltip(tooltip)
```

## Migration from Previous Addons

This plugin replaces:
- `cts_context_menu` - Now deprecated
- `nested_tooltips` - C# version, now converted to GDScript

## Version History

- **2.0.0** - Initial unified release
  - Merged context menu and tooltip systems
  - Converted C# tooltips to GDScript
  - Simplified API

## License

Based on original work by Daniel Schimion (context menus) and Christoph Duzy, Marcin Kuhnert (tooltips).
