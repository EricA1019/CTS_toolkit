extends Control

@onready var _label: Label = $VBox/Label

func _ready() -> void:
	# Assumes the Inventory node is at ../Entity/Inventory relative to HUD
	var inventory := get_node_or_null("../../Entity/Inventory")
	if inventory == null:
		_label.text = "Inventory not found"
		return
	
	# Show slot count
	if inventory.has_method("get_inventory_summary"):
		_label.text = "Inventory attached (" + str(inventory.slot_count) + " slots)"
	else:
		_label.text = "Inventory attached"
