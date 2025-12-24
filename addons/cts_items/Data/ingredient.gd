class_name Ingredient
extends Resource

## The item required or yielded
@export var item: CtsItemDefinition
## The quantity
@export_range(1, 9999) var amount: int = 1
