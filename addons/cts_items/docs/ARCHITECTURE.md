# Architecture

## Overview

The CTS Items addon follows a signal-first, system-driven architecture inspired by the project's Entity pattern. Containers are structural data holders (no business logic) and Systems implement all domain logic. An `ItemsSignalRegistry` autoload centralizes lifecycle and operation signals for discoverability and decoupling.

## Key Components

- ItemsSignalRegistry (autoload): Defines lifecycle and operation signals (e.g., `inventory_container_registered`, `item_add_requested`, `craft_requested`).
- Containers (res://addons/cts_items/Containers/): Data-only nodes that expose `slots` or `equipped` and emit `*_container_registered` on `_ready()`.
- Systems (res://addons/cts_items/Core/): `InventorySystem`, `EquipmentSystem`, `CraftingSystem` — each listens to registry signals and performs business logic.
- Data (res://addons/cts_items/Data/): `CtsItemDefinition`, `ItemInstance`, `RecipeBook`, etc. These remain Resources and unchanged.

## Interaction Patterns

- Systems *read* container state directly for validation (fast, synchronous checks).
- Systems *write* inventory/equipment state by emitting operation requests via the signal registry (e.g., `item_remove_requested`) — `InventorySystem` performs the actual mutation and emits confirmation signals (e.g., `item_removed`).
- This split keeps a single authoritative writer per domain (InventorySystem for inventory data), reduces race conditions, and makes systems easier to test in isolation.

## Migration Notes

- Legacy containers/managers were archived in `addons/cts_items/archive/` for reference.
- New stripped containers maintain inspector-friendly `@export` fields (capacity, recipe_book, equipment_block) and optional explicit `entity_id` overrides.
- Stack logic is placed into `Core/stack_operations.gd` as pure functions to be reused by systems.
