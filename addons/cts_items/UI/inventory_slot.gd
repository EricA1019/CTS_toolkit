class_name InventorySlot
extends PanelContainer

signal slot_clicked(index: int, button_index: int)

@export var slot_index: int = -1

var _item: ItemInstance

# Child nodes (you need to assign these in the scene)
@export var icon_texture: TextureRect
@export var amount_label: Label
@export var background_panel: StyleBoxFlat # Or TextureRect

func display_item(item: ItemInstance):
	_item = item
	
	if not item:
		if icon_texture: icon_texture.texture = null
		if amount_label: amount_label.text = ""
		_update_rarity_border(ItemEnums.ItemRarity.COMMON) # Default
		return
		
	if icon_texture:
		icon_texture.texture = item.definition.image
		
	if amount_label:
		amount_label.text = str(item.amount) if item.amount > 1 else ""
		
	_update_rarity_border(item.definition.rarity)

func _update_rarity_border(rarity: ItemEnums.ItemRarity):
	# If we have a stylebox, update its border color
	var style = get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.border_color = ItemEnums.get_rarity_color(rarity)
		# Maybe set border width if it's 0
		if style.border_width_left == 0:
			style.set_border_width_all(2)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(slot_index, event.button_index)
