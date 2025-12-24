class_name InventoryManager
extends Node

## Manages a collection of items (Inventory)
## Can be used for Player Inventory, Chests, etc.

signal item_added(item: ItemInstance, slot_index: int)
signal item_removed(item: ItemInstance, slot_index: int)
signal item_changed(item: ItemInstance, slot_index: int)
signal inventory_updated

@export var inventory_name: String = "Main"
@export var slot_count: int = 20

## The actual storage: Array of ItemInstance (or null)
var _slots: Array[ItemInstance] = []

func _ready():
	_slots.resize(slot_count)
	_slots.fill(null)

## Add an item to the inventory
## Returns true if fully added, false if inventory full or partial add
func add_item(item: ItemInstance) -> bool:
	if not item:
		return false
		
	# 1. Try to stack with existing items
	if item.definition.is_stackable():
		for i in range(slot_count):
			var slot_item = _slots[i]
			if slot_item and slot_item.definition == item.definition:
				var space = slot_item.definition.max_stack_size - slot_item.amount
				if space > 0:
					var to_add = min(space, item.amount)
					slot_item.amount += to_add
					item.amount -= to_add
					item_changed.emit(slot_item, i)
					if item.amount <= 0:
						inventory_updated.emit()
						return true
						
	# 2. Place in first empty slot
	if item.amount > 0:
		for i in range(slot_count):
			if _slots[i] == null:
				_slots[i] = item # Take ownership
				item_added.emit(item, i)
				inventory_updated.emit()
				return true
				
	inventory_updated.emit()
	return false # Could not add all

## Remove an item (or amount)
func remove_item(item_definition: CtsItemDefinition, amount: int = 1) -> bool:
	if not has_item(item_definition, amount):
		return false
		
	var remaining_to_remove = amount
	
	for i in range(slot_count):
		var slot_item = _slots[i]
		if slot_item and slot_item.definition == item_definition:
			var to_take = min(remaining_to_remove, slot_item.amount)
			slot_item.amount -= to_take
			remaining_to_remove -= to_take
			
			if slot_item.amount <= 0:
				_slots[i] = null
				item_removed.emit(slot_item, i)
			else:
				item_changed.emit(slot_item, i)
				
			if remaining_to_remove <= 0:
				break
				
	inventory_updated.emit()
	return true

## Check if inventory has item
func has_item(item_definition: CtsItemDefinition, amount: int = 1) -> bool:
	var count = 0
	for item in _slots:
		if item and item.definition == item_definition:
			count += item.amount
	return count >= amount

## Get all items as a dictionary { item_id: amount }
## Useful for crafting checks
func get_inventory_summary() -> Dictionary:
	var summary = {}
	for item in _slots:
		if item:
			var id = item.definition.item_id
			if not summary.has(id):
				summary[id] = 0
			summary[id] += item.amount
	return summary

## Get item at specific slot
func get_item_at(index: int) -> ItemInstance:
	if index >= 0 and index < slot_count:
		return _slots[index]
	return null
