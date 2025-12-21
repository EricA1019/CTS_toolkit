extends CharacterBody2D

## Detective character controller - movement, animation, interaction, and entity data integration
## Now integrates with EntitiesResource for stats, abilities, and traits
## Emits EventBus signals for movement and interaction tracking

# =============================================================================
# PRELOADS
# =============================================================================

const VFXComponentClass = preload("res://src/components/visual_effect_feedback_component.gd")

# =============================================================================
# CONSTANTS
# =============================================================================

## Tile size for position tracking (matches tilemap)
const TILE_SIZE: int = 16

# =============================================================================
# EXPORTS
# =============================================================================

# Entity data (assigned in inspector or via .tres file)
@export var entity_data: EntitiesResource = null

# Movement variables (can override entity_data.base_stats.speed if needed)
@export var speed: float = 200.0

# =============================================================================
# STATE
# =============================================================================

## Unique instance identifier for EventBus signals
var _instance_id: String = "detective_001"

## Last tile position for movement tracking
var _last_tile_pos: Vector2i = Vector2i.ZERO

## EntityState reference - single source of truth for runtime stats
var _entity_state: EntityState = null

# Runtime stat properties (delegate to EntityState)
var current_hp: int:
	get: return _entity_state.current_hp if _entity_state else 100
	set(value):
		if _entity_state:
			_entity_state.current_hp = value

var current_stamina: int:
	get: return _entity_state.current_stamina if _entity_state else 2
	set(value):
		if _entity_state:
			_entity_state.current_stamina = value

var current_sanity: int:
	get: return _entity_state.current_sanity if _entity_state else 100
	set(value):
		if _entity_state:
			_entity_state.current_sanity = value

# State variables
var is_interacting: bool = false
var is_using_potion: bool = false
var is_shooting: bool = false
var is_using_tool: bool = false
var interactable_objects: Array = []
var current_interactable = null

# Animation state
enum AnimationState { DEFAULT, POTION, SHOOTING, TOOL }
var current_animation_state: AnimationState = AnimationState.DEFAULT
var last_direction: Vector2 = Vector2.DOWN

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera2D

# Camera zoom settings
const ZOOM_MIN: float = 1.0      # Current level = max zoom out
const ZOOM_MAX: float = 4.0      # Max zoom in (4x closer)
const ZOOM_STEP: float = 0.25    # Zoom increment per scroll
const ZOOM_SMOOTH: float = 10.0  # Smoothing speed
var _target_zoom: float = 1.0    # Target zoom level

func _ready():
	# Check if spawned by EntityFactory (has meta) vs scene-instanced
	var factory_id: String = str(get_meta("instance_id", ""))
	if not factory_id.is_empty():
		# Factory-spawned: use factory-assigned ID and state
		_instance_id = factory_id
		_entity_state = EntityState.get_or_create(_instance_id)
		# Sync speed from entity_data if available
		if entity_data and entity_data.base_stats:
			speed = entity_data.base_stats.speed
		print("[Detective] Factory-spawned with ID: %s" % _instance_id)
	else:
		# Scene-instanced fallback - use "detective" (no suffix) for console compatibility
		_instance_id = "detective"
		set_meta("instance_id", _instance_id)
		# Initialize EntityState first (single source of truth)
		_initialize_entity_state()
		# Initialize entity data (loads template, syncs to EntityState)
		_initialize_entity_data()
	
	# Setup visual feedback component
	_setup_visual_feedback()
	
	# Initialize tile position tracking
	_last_tile_pos = Vector2i(global_position / TILE_SIZE)
	
	# Connect signals for interaction
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
		interaction_area.area_entered.connect(_on_area_entered)
		interaction_area.area_exited.connect(_on_area_exited)
	
	# Connect animation finished signal
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Emit initial status to UI (for both factory and scene-instanced)
	_emit_initial_status()


## Initialize EntityState as single source of truth for runtime stats
func _initialize_entity_state() -> void:
	_entity_state = EntityState.get_or_create(_instance_id)
	_entity_state.template_path = "res://src/entities/entity/detective/data/detective.tres"
	print("[Detective] EntityState created for %s" % _instance_id)

## Initialize runtime stats from entity_data
func _initialize_entity_data() -> void:
	if not entity_data:
		push_warning("[Detective] No entity_data assigned, using default values")
		return
	
	# Apply trait bonuses to base stats
	entity_data.apply_trait_bonuses()
	
	# Sync EntityState from template base_stats
	if entity_data.base_stats and _entity_state:
		_entity_state.current_hp = entity_data.base_stats.hp
		_entity_state.current_stamina = entity_data.base_stats.stamina
		_entity_state.current_sanity = entity_data.base_stats.sanity
		speed = entity_data.base_stats.speed
		
		print("[Detective] Initialized %s - HP: %d, Stamina: %d, Sanity: %d" % [
			entity_data.entity_name,
			current_hp,
			current_stamina,
			current_sanity
		])
		
		# Log abilities
		var abilities: Array[AbilitiesResource] = entity_data.get_all_abilities()
		print("[Detective] Has %d abilities loaded" % abilities.size())
		
		# Emit initial status to UI
		_emit_initial_status()
	else:
		push_error("[Detective] entity_data.base_stats is null!")


## Emit initial status to UI via EventBus
func _emit_initial_status() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		# Emit active entity changed to trigger UI refresh
		event_bus.active_entity_changed.emit(_instance_id)

func _on_body_entered(body: Node2D):
	if body.is_in_group("interactable"):
		interactable_objects.append(body)
		current_interactable = body

func _on_body_exited(body: Node2D):
	if body.is_in_group("interactable"):
		interactable_objects.erase(body)
		if current_interactable == body:
			current_interactable = null


func _unhandled_input(event: InputEvent) -> void:
	# Handle scroll wheel zoom
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Zoom in (increase zoom value)
				_target_zoom = clampf(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom out (decrease zoom value)
				_target_zoom = clampf(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

func _physics_process(delta: float):
	# Smooth camera zoom
	if camera:
		var current_zoom: float = camera.zoom.x
		if not is_equal_approx(current_zoom, _target_zoom):
			var new_zoom: float = lerp(current_zoom, _target_zoom, delta * ZOOM_SMOOTH)
			camera.zoom = Vector2(new_zoom, new_zoom)
	
	# Skip movement while performing actions
	if is_interacting or is_using_potion or is_shooting or is_using_tool:
		return
	
	# Get input vector
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Set velocity
	velocity = input_vector * speed
	
	# Update last direction if moving
	if input_vector != Vector2.ZERO:
		last_direction = input_vector
	
	update_animation(AnimationState.DEFAULT)
	
	# Move the character
	move_and_slide()
	
	# Track tile position changes and emit entity_moved
	var new_tile_pos: Vector2i = Vector2i(global_position / TILE_SIZE)
	if new_tile_pos != _last_tile_pos:
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus:
			event_bus.entity_moved.emit(_instance_id, _last_tile_pos, new_tile_pos)
		_last_tile_pos = new_tile_pos
	
	# Handle interactions
	if Input.is_action_just_pressed("ui_accept") and current_interactable:
		interact_with_object(current_interactable)

func interact_with_object(obj):
	# Determine interaction type based on object group
	var interaction_type: String = "examine"
	if obj.is_in_group("clue"):
		interaction_type = "examine"
		print("Interacting with a clue!")
	elif obj.is_in_group("npc"):
		interaction_type = "use"
		print("Interacting with an NPC!")
	else:
		interaction_type = "examine"
		print("Interacting with an unknown object.")
	
	# Emit tile_interacted via EventBus
	var tile_pos: Vector2i = Vector2i(obj.global_position / TILE_SIZE)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.tile_interacted.emit(_instance_id, tile_pos, interaction_type)
	
	# Reset interaction state
	is_interacting = false

func _on_area_entered(area: Node2D):
	if area.is_in_group("interactable"):
		interactable_objects.append(area)
		current_interactable = area

func _on_area_exited(area: Node2D):
	if area.is_in_group("interactable"):
		interactable_objects.erase(area)
		if current_interactable == area:
			current_interactable = null

func _on_animation_finished():
	# Reset state after animations finish
	match current_animation_state:
		AnimationState.POTION:
			is_using_potion = false
			update_animation(AnimationState.DEFAULT)
		AnimationState.SHOOTING:
			is_shooting = false
			update_animation(AnimationState.DEFAULT)
		AnimationState.TOOL:
			is_using_tool = false
			update_animation(AnimationState.DEFAULT)

# Animation state management
func update_animation(state: AnimationState):
	if current_animation_state == state:
		return
	
	current_animation_state = state
	
	match state:
		AnimationState.DEFAULT:
			play_default_animation()
		AnimationState.POTION:
			play_potion_animation()
		AnimationState.SHOOTING:
			play_shooting_animation()
		AnimationState.TOOL:
			play_tool_animation()

# Animation functions for different states
func play_default_animation():
	if not animated_sprite:
		return
	
	# Play directional default animations (used for both idle and movement)
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			animated_sprite.play("default")
		else:
			animated_sprite.play("default")
	else:
		if last_direction.y > 0:
			animated_sprite.play("default")
		else:
			animated_sprite.play("default")

func play_potion_animation():
	if not animated_sprite:
		return
	
	# Play potion animation based on current direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			animated_sprite.play("potion")
		else:
			animated_sprite.play("potion")
	else:
		if last_direction.y > 0:
			animated_sprite.play("potion")
		else:
			animated_sprite.play("potion")

func play_shooting_animation():
	if not animated_sprite:
		return
	
	# Play shooting animation based on current direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			animated_sprite.play("shooting")
		else:
			animated_sprite.play("shooting")
	else:
		if last_direction.y > 0:
			animated_sprite.play("shooting")
		else:
			animated_sprite.play("shooting")

func play_tool_animation():
	if not animated_sprite:
		return
	
	# Play tool animation based on current direction
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			animated_sprite.play("tool")
		else:
			animated_sprite.play("tool")
	else:
		if last_direction.y > 0:
			animated_sprite.play("tool")
		else:
			animated_sprite.play("tool")

# Public functions to trigger different actions
func use_potion():
	if is_using_potion or is_shooting or is_using_tool:
		return
	
	is_using_potion = true
	update_animation(AnimationState.POTION)

func shoot():
	if is_using_potion or is_shooting or is_using_tool:
		return
	
	is_shooting = true
	update_animation(AnimationState.SHOOTING)

func use_tool():
	if is_using_potion or is_shooting or is_using_tool:
		return
	
	is_using_tool = true
	update_animation(AnimationState.TOOL)


# =============================================================================
# VISUAL FEEDBACK
# =============================================================================

## Setup visual effect feedback component for damage/heal/status effects
func _setup_visual_feedback() -> void:
	var vfx := VFXComponentClass.new()
	vfx.name = "VisualEffectFeedback"
	add_child(vfx)
	print("[Detective] Visual feedback component added")


# =============================================================================
# COMBAT API - Delegate to CombatManager
# =============================================================================

## Take damage via CombatManager (emits EventBus signals)
## @param amount: Damage amount to take
## @param source_id: Entity that caused the damage
## @param damage_type: Type of damage ("physical", "ballistic", "holy", "infernal")
func take_damage(amount: int, source_id: String, damage_type: String = "physical") -> void:
	var combat_mgr := get_node_or_null("/root/CombatManager")
	if combat_mgr:
		combat_mgr.apply_damage(_instance_id, amount, damage_type, source_id)
	else:
		push_warning("[Detective] CombatManager not found, applying damage directly")
		current_hp = maxi(0, current_hp - amount)
	
	# Trigger visual feedback effect
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("visual_effect_requested"):
		event_bus.visual_effect_requested.emit(_instance_id, "damage", -1, -1.0)


## Use an ability via CombatManager (emits EventBus signals)
## @param ability: AbilitiesResource to use
## @param target_id: Target entity instance ID
## @return: Result dictionary from CombatManager
func use_ability(ability: AbilitiesResource, target_id: String) -> Dictionary:
	if not ability:
		push_warning("[Detective] Cannot use null ability")
		return {"success": false, "error": "null_ability"}
	
	var combat_mgr := get_node_or_null("/root/CombatManager")
	if combat_mgr:
		return combat_mgr.execute_action(_instance_id, ability, target_id)
	
	push_warning("[Detective] CombatManager not found")
	return {"success": false, "error": "no_combat_manager"}


## Get EntityState reference (for external systems)
func get_entity_state() -> EntityState:
	return _entity_state
