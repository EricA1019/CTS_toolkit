class_name ProcgenEntitySpawner
extends Node

## ProcgenEntitySpawner
##
## A complex spawner that creates entities with randomized properties.
## - Randomizes visual sprite from a list.
## - Applies random affixes from a JSON data file.
## - Adds visual labels for affixes.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity: Node)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_AFFIX_PATH = "res://addons/cts_entity/Data/affixes.json"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var base_entity_scene: PackedScene
@export_file("*.json") var affix_data_path: String = DEFAULT_AFFIX_PATH
@export var survivor_sprites: Array[Texture2D] = []

# ------------------------------------------------------------------------------
# Internal State
# ------------------------------------------------------------------------------
var _affixes: Array = []

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready() -> void:
	_load_affixes()
	
	# Load default sprites if none assigned (fallback for ease of use)
	if survivor_sprites.is_empty():
		_load_default_sprites()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func create_entity(type: String = "base_entity") -> Node:
	var instance: Node
	
	if base_entity_scene:
		instance = base_entity_scene.instantiate()
	else:
		push_warning("[ProcgenEntitySpawner] Base entity scene not assigned! Using basic Node2D.")
		instance = Node2D.new()
	
	# Set basic name
	instance.name = type.capitalize() + "_" + str(randi())
	
	# Setup Visuals
	_setup_visuals(instance)
	
	# Apply Affixes
	_apply_random_affixes(instance)
	
	entity_created.emit(instance)
	return instance

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _load_affixes() -> void:
	if not FileAccess.file_exists(affix_data_path):
		push_error("[ProcgenEntitySpawner] Affix data file not found: " + affix_data_path)
		return
		
	var file = FileAccess.open(affix_data_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		if data.has("affixes"):
			_affixes = data["affixes"]
			print("[ProcgenEntitySpawner] Loaded ", _affixes.size(), " affixes.")
		else:
			push_error("[ProcgenEntitySpawner] Affix data missing 'affixes' key.")
	else:
		push_error("[ProcgenEntitySpawner] Failed to parse affix data: " + json.get_error_message())

func _load_default_sprites() -> void:
	# Fallback to known paths in the addon
	var paths = [
		"res://addons/cts_entity/assets/survivor.png",
		"res://addons/cts_entity/assets/survivor2.png",
		"res://addons/cts_entity/assets/survivor3.png"
	]
	for path in paths:
		if ResourceLoader.exists(path):
			survivor_sprites.append(load(path))

func _setup_visuals(entity: Node) -> void:
	# Hide existing ColorRect if present (default in BaseEntity)
	var color_rect = entity.get_node_or_null("ColorRect")
	if color_rect:
		color_rect.visible = false
		
	# Add Survivor Sprite
	var tex: Texture2D
	if not survivor_sprites.is_empty():
		tex = survivor_sprites.pick_random()
	
	if tex:
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.name = "VisualSprite"
		sprite.scale = Vector2(4, 4) # Scale up for visibility
		entity.add_child(sprite)
	else:
		push_warning("[ProcgenEntitySpawner] No sprites available to assign.")

func _apply_random_affixes(entity: Node) -> void:
	if _affixes.is_empty():
		return
		
	var affix = _affixes.pick_random()
	var affix_name = affix["name"]
	
	# Update Entity Name
	entity.name = affix_name + " " + entity.name
	
	# Add Visual Label for Affix
	var label = Label.new()
	label.text = affix_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -60) # Position above sprite
	label.custom_minimum_size = Vector2(100, 0)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_font_size_override("font_size", 14)
	label.name = "AffixLabel"
	
	entity.add_child(label)
	
	# Store affix data on entity metadata for future logic
	entity.set_meta("affix", affix)
