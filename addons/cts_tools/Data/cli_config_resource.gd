class_name CLIConfigResource
extends Resource

## Configuration for CTS CLI Tools
## Allows per-project customization of available commands and features.

@export_group("Features")
## Enable entity manipulation commands (spawn, despawn, stats)
@export var enable_entity_commands: bool = true

## Enable item manipulation commands (add, remove)
@export var enable_item_commands: bool = true

## Enable custom commands loaded from JSON
@export var enable_custom_commands: bool = true

## Enable persistence of custom commands
@export var persistence_enabled: bool = true

## Enable autocomplete for command arguments
@export var autocomplete_enabled: bool = true

@export_group("PIS (Player Input Simulation)")
## Enable Player Input Simulation commands
@export var enable_pis: bool = true

## Enable screenshot integration prompts
@export var pis_screenshot_integration: bool = true

## Default playback speed multiplier
@export var pis_default_speed: float = 1.0

@export_group("Presets")
## Active command preset name
@export var command_preset: String = "default"

## List of active command categories
@export var command_categories: Array[String] = ["debug", "test", "admin"]

@export_group("Paths")
## Path to save custom commands JSON
@export var custom_commands_path: String = "user://cts_cli_custom_commands.json"
