# CTS Tools Signal Contracts

## Overview

This document defines the signals used by the `cts_tools` addon (CLI, PIS, etc). These signals allow other systems to react to tool operations, enabling decoupled UI updates, logging, and analytics.

## CLI Manager Signals

Location: `addons/cts_tools/Core/cli_manager.gd`

| Signal | Parameters | Description |
|--------|------------|-------------|
| `command_registered` | `cmd_name: String, category: String` | Emitted when a new command is successfully registered with LimboConsole. |
| `command_executed` | `cmd_name: String, args: Array, result: Variant` | Emitted after a command is executed. Useful for logging or analytics. |
| `preset_loaded` | `preset_name: String, command_count: int` | Emitted when a command preset (JSON) is loaded. |
| `config_changed` | `config: CLIConfigResource` | Emitted when the configuration resource is updated or reloaded. |

## PIS (Player Input Simulation) Signals

Location: `addons/cts_tools/Core/PIS/pis_recorder.gd`

| Signal | Parameters | Description |
|--------|------------|-------------|
| `recording_started` | `void` | PIS recording began |
| `recording_stopped` | `event_count: int` | PIS recording stopped with N events captured |
| `playback_started` | `path: String, speed: float` | Playback began from file at specified speed |
| `playback_finished` | `void` | Playback completed |
| `input_simulated` | `event_type: String, action: String` | Input event was simulated |
| `screenshot_requested` | `frame_info: Dictionary` | User should manually capture screenshot (prompt for Godot MCP) |

## Usage Examples

### Listening for Command Execution

```gdscript
func _ready() -> void:
    var cli_manager = get_node("/root/CTS_Tools")
    if cli_manager:
        cli_manager.command_executed.connect(_on_command_executed)

func _on_command_executed(cmd_name: String, args: Array, result: Variant) -> void:
    print("Command executed: %s with args %s" % [cmd_name, args])
```

### Reacting to Preset Loads

```gdscript
func _on_preset_loaded(preset_name: String, count: int) -> void:
    print("Loaded preset '%s' with %d commands" % [preset_name, count])
```
