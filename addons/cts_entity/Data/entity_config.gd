extends Resource
class_name EntityConfig

## Entity configuration resource for cts_entity plugin
## Defines base entity properties and plugin extension points
##
## Usage:
##   var config = EntityConfig.new()
##   config.entity_id = "bandit"
##   config.is_unique = false  # Auto-increment IDs
##   config.custom_data["stats_path"] = "res://data/stats/bandit_stats.tres"

# =============================================================================
# EXPORTS
# =============================================================================

## Base identifier for this entity type (e.g., "bandit", "detective")
## Will be used as-is if is_unique=true, or as prefix for auto-increment
@export var entity_id: String = ""

## Display name for UI
@export var entity_name: String = ""

## If true, instance uses entity_id directly (story NPCs, player)
## If false, auto-increment suffix added (bandit_001, bandit_002)
@export var is_unique: bool = false

## Description text for tooltips/UI
@export_multiline var description: String = ""

## Tile size for grid-based position tracking
@export var tile_size: int = 16

## Optional custom scene to instantiate (handcrafted entities)
## If null, factory uses base entity_base.tscn template
@export var prefab_scene: PackedScene = null

## Visual, physics, and movement data
## Applied by factory when creating entity
@export var visual_data: EntityResource = null

## Optional block references for typed containers
@export var skills_block: Resource = null
@export var affix_block: Resource = null
@export var inventory_block: Resource = null
@export var equipment_block: Resource = null
@export var stats_block: Resource = null
@export var abilities_block: Resource = null
@export var recipe_book: Resource = null

## Extension data for other plugins
## Example: {"stats_path": "res://...", "abilities_path": "res://..."}
@export var custom_data: Dictionary = {}

# =============================================================================
# VALIDATION
# =============================================================================

## Validate entity configuration
func _validate() -> bool:
	var is_valid := true
	
	# entity_id must be non-empty
	if entity_id.is_empty():
		push_error("[EntityConfig] entity_id cannot be empty")
		is_valid = false
	
	# entity_id must be alphanumeric + underscore only
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z0-9_]+$")
	if not regex.search(entity_id):
		push_error("[EntityConfig] entity_id must be alphanumeric + underscore only: '%s'" % entity_id)
		is_valid = false
	
	# tile_size must be positive
	if tile_size <= 0:
		push_error("[EntityConfig] tile_size must be positive: %d" % tile_size)
		is_valid = false
	
	# entity_name warning if empty (not critical)
	if entity_name.is_empty():
		push_warning("[EntityConfig] entity_name is empty for '%s'" % entity_id)
	
	return is_valid

# =============================================================================
# HELPER METHODS
# =============================================================================

## Get stats resource path from custom_data
func get_stats_path() -> String:
	return custom_data.get("stats_path", "")

## Get abilities resource path from custom_data
func get_abilities_path() -> String:
	return custom_data.get("abilities_path", "")

## Get inventory config path from custom_data
func get_inventory_path() -> String:
	return custom_data.get("inventory_path", "")

## Check if entity has plugin data
func has_plugin_data(plugin_name: String) -> bool:
	return custom_data.has(plugin_name + "_path")

## Get plugin data path
func get_plugin_path(plugin_name: String) -> String:
	return custom_data.get(plugin_name + "_path", "")

## Set plugin data path
func set_plugin_path(plugin_name: String, path: String) -> void:
	custom_data[plugin_name + "_path"] = path
