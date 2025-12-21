# CTS Text UI - Technical Documentation

## Architecture

### Core Components

#### Context Menu System (`Code/`)
- `context_menu.gd` - Main context menu class with PopupMenu wrapper
- `context_menu_control.gd` - Editor-friendly Control node for visual setup
- `context_menu_entry.gd` - Resource for menu item configuration

#### Tooltip System (`Core/`)
- `tooltip_service.gd` - Main service (autoload singleton)
- `tooltip.gd` - Readonly tooltip data class
- `tooltip_control.gd` - Default tooltip visual implementation
- `tooltip_control_interface.gd` - Base class for custom tooltip visuals

#### Data Management (`Data/`)
- `tooltip_data.gd` - Tooltip content data
- `tooltip_data_provider.gd` - Interface and basic implementation for tooltip lookup

#### Configuration (`Settings/`)
- `tooltip_settings.gd` - Behavior configuration
- `tooltip_lock_mode.gd` - Locking behavior enums
- `tooltip_pivot.gd` - Position anchoring enums

## API Reference

### TooltipService (Autoload)

```gdscript
# Show tooltip with text
func show_tooltip(position: Vector2, pivot: TooltipPivot.Position, text: String, width: int = -1) -> Tooltip

# Show tooltip from data provider
func show_tooltip_by_id(position: Vector2, pivot: TooltipPivot.Position, tooltip_id: String, width: int = -1) -> Tooltip

# Lock tooltip manually (requires ACTION_LOCK mode)
func action_lock_tooltip(tooltip: Tooltip) -> void

# Release tooltip (allows it to close)
func release_tooltip(tooltip: Tooltip) -> void

# Force destroy tooltip immediately
func force_destroy(tooltip: Tooltip) -> void

# Clear all tooltips
func clear_tooltips() -> void

# Configuration
func set_tooltip_data_provider(provider: TooltipDataProvider) -> void
func set_tooltip_prefab_path(path: String) -> void
func set_tooltip_settings(settings: TooltipSettings) -> void
```

### ContextMenu

```gdscript
# Create and attach
var menu := ContextMenu.new()
menu.attach_to(parent_node)

# Add items
func add_item(label: String, callback: Callable, disabled: bool = false, icon: Texture2D = null) -> void
func add_checkbox_item(label: String, callback: Callable, disabled: bool = false, checked: bool = false, icon: Texture2D = null) -> void
func add_separator() -> void
func add_submenu(label: String) -> ContextMenu

# Connect to control for right-click
func connect_to(control: Control) -> void

# Show manually
func show_menu(parent: CanvasItem) -> void

# Update items
func set_item_disabled(id: Variant, disabled: bool) -> void
func set_item_checked(id: Variant, checked: bool) -> void
func update_item_label(id: Variant, new_label: String) -> void
```

## Nested Tooltips

Tooltips can contain clickable links that spawn nested tooltips:

1. Set up a data provider with multiple tooltip definitions
2. Use BBCode meta tags in tooltip text: `[url=tooltip_id]Hover Me[/url]`
3. When user hovers over link, nested tooltip appears
4. Nested tooltips support multiple levels

## Customization

### Custom Tooltip Visuals

Extend `TooltipControlInterface`:

```gdscript
extends TooltipControlInterface

# Implement your custom appearance
# Override _set/_get for properties
```

Then set the prefab path:
```gdscript
TooltipService.set_tooltip_prefab_path("res://my_custom_tooltip.tscn")
```

### Tooltip Behavior

Configure via `TooltipSettings`:

```gdscript
var settings := TooltipSettings.new()
settings.lock_mode = TooltipLockMode.Mode.HOVER_LOCK
settings.lock_time = 1.0  # Time to lock (seconds)
settings.unlock_time = 0.5  # Time to unlock (seconds)
settings.wrap_text = true

TooltipService.set_tooltip_settings(settings)
```

## Performance Notes

- Tooltips process each frame when active
- Use `release_tooltip()` to allow cleanup when source is done
- Lock modes affect when tooltips persist vs auto-close
- Multiple nested tooltips are handled hierarchically

## Integration with CTS Methodology

Following CTS 2.0 principles:
- **File size**: All files under 500 lines
- **Signal-based**: Tooltips emit `link_clicked` signal
- **Resource-based**: Data separated from behavior
- **Modular**: Context menus and tooltips can be used independently

## Migration Notes

### From C# nested_tooltips

Key changes:
- Class names: PascalCase → snake_case functions
- Namespaces: `NestedTooltips.*` → Global classes
- Properties: C# properties → Godot properties with getters/setters
- Events: C# events → Godot signals

### From cts_context_menu

No API changes, just update import paths to `cts_textui`.
