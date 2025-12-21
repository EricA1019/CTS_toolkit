# CTS Text UI - Quick Reference

## Installation

1. The addon is located at: `res://addons/cts_textui/`
2. Enable in: **Project Settings → Plugins → CTS Text UI**
3. `TooltipService` autoload will be available globally

## Context Menu Quick Start

```gdscript
# Method 1: Programmatic
var menu := ContextMenu.new()
menu.attach_to(self)
menu.add_item("Copy", _on_copy)
menu.add_item("Paste", _on_paste)
menu.connect_to($Button)  # Shows on right-click

# Method 2: Visual (in editor)
# Add ContextMenuControl node
# Configure entries in inspector
# Set node_to_connect property
```

## Tooltip Quick Start

```gdscript
# Simple tooltip
var tip := TooltipService.show_tooltip(
    Vector2(100, 100),
    TooltipPivot.Position.TOP_LEFT,
    "[b]Title[/b]\nDescription"
)

# Release when done (allows auto-close)
TooltipService.release_tooltip(tip)

# Force close immediately
TooltipService.force_destroy(tip)
```

## Position Modes

### Context Menu

```gdscript
menu.set_position_mode(ContextMenu.PositionMode.CURSOR)       # At mouse
menu.set_position_mode(ContextMenu.PositionMode.NODE_CENTER)  # Node center
menu.set_position_mode(ContextMenu.PositionMode.NODE_BOTTOM)  # Below node
```

### Tooltip Pivots

```gdscript
TooltipPivot.Position.TOP_LEFT      # Tooltip extends right+down from position
TooltipPivot.Position.CENTER        # Tooltip centered on position
TooltipPivot.Position.BOTTOM_RIGHT  # Tooltip extends left+up from position
# ... 9 total positions available
```

## BBCode Examples

```gdscript
# Basic formatting
"[b]Bold[/b] [i]Italic[/i] [u]Underline[/u]"

# Colors
"[color=red]Red text[/color]"
"[color=#FF5500]Custom color[/color]"

# Nested tooltips (requires data provider)
"Hover over [url=item_id]this item[/url] for details"
```

## Data Provider Setup

```gdscript
# Create provider
var provider := TooltipDataProvider.BasicTooltipDataProvider.new()

# Add tooltip data
var sword_tip := TooltipData.new("sword", "[b]Iron Sword[/b]\nDamage: 15", 200)
provider.add_tooltip(sword_tip)

# Register with service
TooltipService.set_tooltip_data_provider(provider)

# Use by ID
TooltipService.show_tooltip_by_id(pos, pivot, "sword")
```

## Lock Modes

```gdscript
var settings := TooltipSettings.new()

# No locking - tooltips close immediately when released
settings.lock_mode = TooltipLockMode.Mode.NONE

# Hover lock - tooltip stays open after hovering for lock_time
settings.lock_mode = TooltipLockMode.Mode.HOVER_LOCK
settings.lock_time = 0.5

# Action lock - tooltip stays until explicitly locked via code
settings.lock_mode = TooltipLockMode.Mode.ACTION_LOCK

TooltipService.set_tooltip_settings(settings)
```

## Common Patterns

### Hover Tooltip

```gdscript
var _current_tooltip: Tooltip = null

func _on_button_mouse_entered():
    _current_tooltip = TooltipService.show_tooltip(
        $Button.global_position,
        TooltipPivot.Position.BOTTOM_CENTER,
        "Button description"
    )

func _on_button_mouse_exited():
    if _current_tooltip:
        TooltipService.release_tooltip(_current_tooltip)
        _current_tooltip = null
```

### Item Inspection

```gdscript
func _on_item_clicked(item_id: String):
    var pos := get_global_mouse_position()
    TooltipService.show_tooltip_by_id(
        pos,
        TooltipPivot.Position.CENTER,
        item_id
    )
```

### Context Menu on Node

```gdscript
func _setup_context_menu():
    var menu := ContextMenu.new()
    menu.attach_to(self)
    menu.set_position_mode(ContextMenu.PositionMode.NODE_CENTER)
    
    menu.add_item("Edit", _on_edit)
    menu.add_item("Delete", _on_delete)
    menu.add_separator()
    menu.add_checkbox_item("Visible", _on_toggle_visible, false, true)
    
    $Node.gui_input.connect(func(event):
        if event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
                menu.show_menu($Node)
    )
```

## Signals

### Tooltip Control

```gdscript
# In custom tooltip control
signal link_clicked(position: Vector2, meta: String)

# Connect in code
tooltip_control.link_clicked.connect(_on_link_clicked)
```

## File Paths

| Component | Path |
|-----------|------|
| Plugin | `res://addons/cts_textui/` |
| Context Menu Code | `res://addons/cts_textui/Code/` |
| Tooltip Core | `res://addons/cts_textui/Core/` |
| Data Classes | `res://addons/cts_textui/Data/` |
| Settings | `res://addons/cts_textui/Settings/` |
| Example | `res://addons/cts_textui/example_usage.gd` |

## Troubleshooting

**Tooltip doesn't show:**

- Check `TooltipService` autoload is enabled
- Verify `tooltips_parent` is set in service scene
- Check tooltip isn't immediately released

**Context menu doesn't appear:**

- Ensure `attach_to()` was called
- Verify control has `gui_input` working
- Check if menu has items added

**Nested tooltips not working:**

- Ensure data provider is set
- Check tooltip IDs match data provider IDs
- Verify lock mode allows nesting (must be locked)

## Further Reading

- [README.md](res://addons/cts_textui/README.md) - Full user guide
- [TECHNICAL.md](res://addons/cts_textui/TECHNICAL.md) - API reference
- [example_usage.gd](res://addons/cts_textui/example_usage.gd) - Working examples
