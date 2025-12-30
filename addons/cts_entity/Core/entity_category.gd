class_name EntityCategory
extends RefCounted

## Entity Category Enum
## Defines broad categories for entities to allow type-safe filtering and spawning.

enum Category {
	NONE = 0,
	PLAYER = 1,
	NPC = 2,
	ENEMY = 3,
	ITEM = 4,
	PROP = 5,
	TRIGGER = 6
}

static func get_name(category: Category) -> String:
	match category:
		Category.PLAYER: return "Player"
		Category.NPC: return "NPC"
		Category.ENEMY: return "Enemy"
		Category.ITEM: return "Item"
		Category.PROP: return "Prop"
		Category.TRIGGER: return "Trigger"
		_: return "None"
