class_name InventoryBlock
extends Resource

## Configuration resource for inventory containers

## Maximum number of inventory slots
@export_range(1, 100) var capacity: int = 20

## Starting items to populate inventory with
@export var starting_items: Array[ItemInstance] = []
