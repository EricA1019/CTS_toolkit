# cts_items - Signal Contracts

This file documents the signal contracts for the CTS Items addon (signal-first).

## Lifecycle Signals
- `inventory_container_registered(entity_id: String, container: Node)` — inventory container became available
- `inventory_container_unregistered(entity_id: String)` — inventory container removed
- `equipment_container_registered(entity_id: String, container: Node)`
- `equipment_container_unregistered(entity_id: String)`
- `crafting_container_registered(entity_id: String, container: Node)`
- `crafting_container_unregistered(entity_id: String)`

## Inventory Operation Signals
- `item_add_requested(entity_id: String, item: ItemInstance)` — Request to add an item (auto-merge semantics)
- `item_place_requested(entity_id: String, slot_index: int, item: ItemInstance)` — Place item into explicit slot (UI drag-drop)
- `item_added(entity_id: String, item: ItemInstance, slot_index: int)` — Notification that item was added
- `item_remove_requested(entity_id: String, item_id: String, amount: int)` — Request to remove `amount` of `item_id`
- `item_removed(entity_id: String, item: ItemInstance, slot_index: int)` — Notification that item was removed
- `item_stacked(entity_id: String, dst: ItemInstance, src: ItemInstance)` — Two stacks were merged

## Equipment Operation Signals
- `item_equip_requested(entity_id: String, slot: int, item: ItemInstance)`
- `item_equipped(entity_id: String, slot: int, item: ItemInstance, previous: ItemInstance)`
- `item_unequip_requested(entity_id: String, slot: int)`
- `item_unequipped(entity_id: String, slot: int, item: ItemInstance)`

## Crafting Operation Signals
- `craft_requested(entity_id: String, recipe_id: String)` — Player requested crafting of `recipe_id`
- `craft_started(entity_id: String, recipe: RecipeData)` — Crafting flow started (optional)
- `craft_completed(entity_id: String, recipe: RecipeData, result: ItemInstance)` — Crafting succeeded
- `craft_failed(entity_id: String, recipe_id: String, reason: String)` — Crafting failed and why

