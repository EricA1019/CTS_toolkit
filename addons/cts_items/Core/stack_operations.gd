class_name StackOperations
extends Object

# Utility: merge source into target when same definition and stackable
# Returns true if any amount was transferred
static func merge(target, source) -> bool:
	if target == null or source == null:
		return false
	if not target.has_method("get") and not target.has("amount"):
		# assume it's an ItemInstance-like object
		pass
	if target.definition != source.definition:
		return false
	if not target.definition.is_stackable():
		return false
	var space: int = target.definition.max_stack_size - int(target.amount)
	if space <= 0:
		return false
	var to_move := min(space, int(source.amount))
	target.amount += to_move
	source.amount -= to_move
	return to_move > 0

# Place an item into explicit slot index on a slots array (nullable entries)
# Returns true if placed
static func place_at_slot(slots: Array, index: int, item) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var slot = slots[index]
	if slot == null:
		slots[index] = item
		return true
	# If same definition and stackable, merge into slot
	if slot.definition == item.definition and slot.definition.is_stackable():
		return merge(slot, item)
	return false

# Add item into slots using merge-into-existing then first empty slot
# Returns the slot index where item ended up, or -1 on failure
static func add_item_to_slots(slots: Array, item) -> int:
	if not item:
		return -1
	# Try merge first
	for i in range(slots.size()):
		var slot = slots[i]
		if slot and slot.definition == item.definition and slot.definition.is_stackable():
			if merge(slot, item):
				if item.amount <= 0:
					return i
	# Place into first empty
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = item
			return i
	return -1
