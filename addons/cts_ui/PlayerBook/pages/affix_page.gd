class_name AffixPage
extends BookPage

@onready var affix_list: ItemList = $VBoxContainer/AffixList
var _affix_container: Node

func setup(event_bus: Node, data_provider: Node) -> void:
	name = "Affixes"
	
	# Try to find AffixContainer on player
	if data_provider.has_node("AffixContainer"):
		_affix_container = data_provider.get_node("AffixContainer")
		
		var registry = get_node_or_null("/root/AffixSignalRegistry")
		if registry:
			registry.affix_applied.connect(_on_affix_applied)
			registry.affix_removed.connect(_on_affix_removed)
			
		_refresh_list()
	else:
		# Try to find by type if name fails? Or just warn.
		push_warning("AffixPage: No AffixContainer found on data provider.")

func _refresh_list() -> void:
	affix_list.clear()
	if _affix_container and _affix_container.has_method("get_active_affixes"):
		var affixes = _affix_container.get_active_affixes()
		for affix in affixes:
			_add_affix_to_list(affix)

func _on_affix_applied(entity_id: String, affix_instance) -> void:
	# Check if this event is for us
	if _affix_container and _affix_container.owner and _affix_container.owner.name == entity_id:
		_add_affix_to_list(affix_instance)

func _on_affix_removed(entity_id: String, source_id: String) -> void:
	if _affix_container and _affix_container.owner and _affix_container.owner.name == entity_id:
		_refresh_list()

func _add_affix_to_list(affix) -> void:
	var display_name = "Affix"
	if affix.has_method("get_display_name"):
		display_name = affix.get_display_name()
	elif "name" in affix:
		display_name = affix.name
	affix_list.add_item(display_name)
