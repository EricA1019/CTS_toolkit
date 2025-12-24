extends Resource
class_name AffixInstance

const AffixData = preload("res://addons/cts_affix/Data/affix_data.gd")

@export var affix_data: AffixData = null
@export var rolled_value: float = 0.0
@export var source_id: String = ""

func ensure_source_id() -> void:
	if source_id.is_empty():
		var base_id := "generic"
		if affix_data and not String(affix_data.affix_id).is_empty():
			base_id = affix_data.affix_id
		var uuid := _generate_uuid()
		source_id = "affix_%s_%s" % [base_id, uuid]

func _generate_uuid() -> String:
	## Simple UUID-like generation using random values
	randomize()
	var template := "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	var uuid := ""
	
	for i in range(template.length()):
		var c := template[i]
		if c == "x":
			uuid += "%x" % (randi() % 16)
		elif c == "y":
			uuid += "%x" % ((randi() % 4) + 8)
		else:
			uuid += c
	
	return uuid

func to_modifier_data() -> Dictionary:
	if affix_data == null:
		return {}
	return {
		"skill_type": affix_data.skill_type,
		"modifier_type": affix_data.modifier_type,
		"value": rolled_value,
		"source_id": source_id,
	}

func duplicate_instance() -> AffixInstance:
	var inst := AffixInstance.new()
	inst.affix_data = affix_data
	inst.rolled_value = rolled_value
	inst.source_id = source_id
	return inst
