@tool
class_name ContextMenuEntry
extends Resource
## A resource representing a single context menu entry.

enum EntryType {
	ITEM,
	SEPARATOR,
	CHECKBOX,
	SUBMENU
}

@export var item_type: EntryType = EntryType.ITEM
@export var label: String = ""
@export var action_target: NodePath = NodePath("")
@export var action_method: String = ""
@export var disabled: bool = false
@export var is_checked: bool = false
@export var icon: Texture2D = null

@export_category("Submenu")
@export var submenu_entries: Array[ContextMenuEntry] = []
