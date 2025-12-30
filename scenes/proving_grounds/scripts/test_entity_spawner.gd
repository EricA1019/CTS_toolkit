@icon("res://addons/cts_core/assets/node_2D/icon_character.png")
class_name ProvingGroundsEntityFactory
extends Node

## ProvingGroundsEntityFactory
##
## Responsible for creating and configuring entities for the Proving Grounds.
## Supports STATIC (fixed), PROCGEN (random), and MIXED modes.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity: Node)

# ------------------------------------------------------------------------------
# Enums
# ------------------------------------------------------------------------------
enum SpawnMode {
	STATIC,     # Always same sprite/name (good for regression tests)
	PROCGEN,    # Random sprites/affixes (good for stress tests)
	MIXED       # Base static, random stats
}

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AFFIX_DATA_PATH = "res://scenes/proving_grounds/data/affixes.json"
const SURVIVOR_SPRITES = [
	"res://addons/cts_entity/assets/survivor.png",
	"res://addons/cts_entity/assets/survivor2.png",
	"res://addons/cts_entity/assets/survivor3.png"
]

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_group("Configuration")
@export var spawn_mode: SpawnMode = SpawnMode.PROCGEN
@export var base_entity_scene: PackedScene

@export_group("Static Overrides")
@export var static_name: String = "TestDummy"
@export var static_sprite: Texture2D

# ------------------------------------------------------------------------------
# Internal State
# ------------------------------------------------------------------------------
var _affixes: Array = []

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready() -> void:
	_load_affixes()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
## Calculates the ideal spawn position based on a marker node
func get_spawn_position(marker: Node2D) -> Vector2:
	if not marker:
		return Vector2.ZERO
		
	# Start at marker's position
	var pos = marker.global_position
	
	# Add slight random offset to prevent perfect stacking (z-fighting/visual clutter)
	# In the future, this could check for valid navmesh positions or slot availability
	var offset = Vector2(randf_range(-16, 16), randf_range(-16, 16))
	
	return pos + offset

func create_entity(_type: String = "base_entity") -> Node:
	print("[EntityFactory] Creating entity. Mode: ", SpawnMode.keys()[spawn_mode])
	var instance: Node
	
	if base_entity_scene:
		instance = base_entity_scene.instantiate()
	else:
		push_warning("[EntityFactory] Base entity scene not assigned! Using basic Node2D.")
		instance = Node2D.new()
	
	# Configure based on mode
	match spawn_mode:
		SpawnMode.STATIC:
			_configure_static(instance)
		SpawnMode.PROCGEN:
			_configure_procgen(instance)
		SpawnMode.MIXED:
			_configure_static(instance)
			_apply_random_affixes(instance)
	
	entity_created.emit(instance)
	return instance

# ------------------------------------------------------------------------------
# Configuration Methods
# ------------------------------------------------------------------------------
func _configure_static(instance: Node) -> void:
	instance.name = static_name + "_" + str(randi() % 1000) # Keep slightly unique for Godot
	
	var sprite = instance.get_node_or_null("Visuals/Sprite2D")
	if sprite and static_sprite:
		sprite.texture = static_sprite
		
	var label = instance.get_node_or_null("Visuals/AffixLabel")
	if label:
		label.text = "Static"

func _configure_procgen(instance: Node) -> void:
	instance.name = "Survivor_" + str(randi())
	
	# Random Sprite
	var sprite = instance.get_node_or_null("Visuals/Sprite2D")
	if sprite:
		var texture_path = SURVIVOR_SPRITES.pick_random()
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
	
	# Random Affixes
	_apply_random_affixes(instance)

	# Attach demo SkillsContainer using local test_skills.tres if not present
	var skills_comp := instance.get_node_or_null("SkillsContainer")
	if skills_comp == null:
		skills_comp = preload("res://addons/cts_skills/Containers/skills_container.gd").new()
		skills_comp.name = "SkillsContainer"
		instance.add_child(skills_comp)
	# Assign demo skill block resource
	if ResourceLoader.exists("res://scenes/proving_grounds/resources/test_skills.tres"):
		skills_comp.skills_block = load("res://scenes/proving_grounds/resources/test_skills.tres")
	else:
		push_warning("Test skills resource not found; skipping skills_block assignment.")

func _apply_random_affixes(instance: Node) -> void:
	var label = instance.get_node_or_null("Visuals/AffixLabel")
	if label and not _affixes.is_empty():
		var affix = _affixes.pick_random()
		label.text = affix.get("name", "Unknown")
		# In future: Apply actual stats here

# ------------------------------------------------------------------------------
# Data Loading
# ------------------------------------------------------------------------------
func _load_affixes() -> void:
	if not FileAccess.file_exists(AFFIX_DATA_PATH):
		push_warning("[EntityFactory] Affix data file not found.")
		return
		
	var file = FileAccess.open(AFFIX_DATA_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		var data = json.data
		if data.has("affixes"):
			_affixes = data["affixes"]
