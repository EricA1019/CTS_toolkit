extends Node2D

## Example: Showcase Entity with Multiple Plugins
## Demonstrates integrating cts_skills, cts_entity, and other plugins

const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const SkillBlock = preload("res://addons/cts_skills/Data/skill_block.gd")

@onready var _skills_component: SkillsComponent = null

func _ready() -> void:
	# Create EntityConfig for showcase entity
	var config = EntityConfig.new()
	config.entity_id = "showcase_hero"
	config.is_unique = true  # Only one showcase hero
	config.custom_data = {
		"description": "Showcase entity demonstrating plugin integration",
		"initial_skills": {
			SkillEnums.SkillType.UNARMED: 5,
			SkillEnums.SkillType.SNEAKING: 3,
			SkillEnums.SkillType.SCAVENGING: 1
		}
	}
	
	# Spawn showcase entity
	var hero = CTS_Entity.create_entity(config, self)
	
	if hero:
		hero.position = Vector2(400, 300)
		print("[Showcase] Hero spawned with ID: ", hero._instance_id)
		
		# Add SkillsComponent to entity
		_setup_skills(hero)
		
		# Demo skill gain after 1 second
		await get_tree().create_timer(1.0).timeout
		_demo_skill_gain()
	else:
		push_error("[Showcase] Failed to spawn showcase hero")


func _setup_skills(entity: Node) -> void:
	"""Add and configure SkillsComponent on the entity"""
	# Create skill block with initial configuration
	var skill_block = SkillBlock.new()
	skill_block.starting_levels = {
		SkillEnums.SkillType.UNARMED: 5,
		SkillEnums.SkillType.SNEAKING: 3,
		SkillEnums.SkillType.SCAVENGING: 1,
		SkillEnums.SkillType.LOCKPICKING: 0,
	}
	
	skill_block.starting_xp = {
		SkillEnums.SkillType.UNARMED: 50.0,
		SkillEnums.SkillType.SNEAKING: 25.0,
	}
	
	# Configure XP curves
	skill_block.default_curve_type = SkillBlock.XPCurveType.EXPONENTIAL
	skill_block.default_base_xp = 100.0
	skill_block.default_multiplier = 1.15
	
	# Add skills component
	_skills_component = SkillsComponent.new()
	_skills_component.skill_block = skill_block
	_skills_component.name = "SkillsComponent"
	entity.add_child(_skills_component)
	
	# Connect to registry signals (signals emit through CTS_Skills singleton)
	var registry = Engine.get_singleton("CTS_Skills")
	if registry:
		registry.skill_leveled_up.connect(_on_skill_leveled_up)
		registry.xp_gained.connect(_on_xp_gained)
	else:
		push_warning("[Showcase] CTS_Skills registry not found - signals won't work")
	
	print("[Showcase] Skills initialized:")
	print("  - Unarmed Combat: Level ", _skills_component.get_level(SkillEnums.SkillType.UNARMED))
	print("  - Sneaking: Level ", _skills_component.get_level(SkillEnums.SkillType.SNEAKING))
	print("  - Scavenging: Level ", _skills_component.get_level(SkillEnums.SkillType.SCAVENGING))
	print("  - Lockpicking: Level ", _skills_component.get_level(SkillEnums.SkillType.LOCKPICKING))


func _demo_skill_gain() -> void:
	"""Demonstrate skill XP gain and leveling"""
	if not _skills_component:
		return
	
	print("\n[Showcase] Gaining Unarmed Combat XP...")
	_skills_component.gain_xp(SkillEnums.SkillType.UNARMED, 150.0, "training")
	
	await get_tree().create_timer(1.0).timeout
	
	print("\n[Showcase] Gaining Sneaking XP...")
	_skills_component.gain_xp(SkillEnums.SkillType.SNEAKING, 200.0, "stealth_practice")
	
	await get_tree().create_timer(1.0).timeout
	
	print("\n[Showcase] Gaining Scavenging XP...")
	_skills_component.gain_xp(SkillEnums.SkillType.SCAVENGING, 300.0, "looting")
	
	await get_tree().create_timer(1.0).timeout
	
	print("\n[Showcase] Final skill levels:")
	print("  - Unarmed Combat: Level ", _skills_component.get_level(SkillEnums.SkillType.UNARMED))
	print("  - Sneaking: Level ", _skills_component.get_level(SkillEnums.SkillType.SNEAKING))
	print("  - Scavenging: Level ", _skills_component.get_level(SkillEnums.SkillType.SCAVENGING))


func _on_skill_leveled_up(entity_id: String, skill_type: int, old_level: int, new_level: int) -> void:
	var skill_name = SkillEnums.SkillType.keys()[skill_type]
	print("[Showcase] ⚡ LEVEL UP! %s: %d → %d (Entity: %s)" % [skill_name, old_level, new_level, entity_id])


func _on_xp_gained(entity_id: String, skill_type: int, xp_amount: float, source: String) -> void:
	var skill_name = SkillEnums.SkillType.keys()[skill_type]
	var current_level = _skills_component.get_level(skill_type)
	var progress = _skills_component.get_xp_progress(skill_type)
	print("[Showcase] +%.1f XP to %s (Level %d, Progress: %.1f%%, Source: %s)" % [
		xp_amount,
		skill_name,
		current_level,
		progress * 100.0,
		source
	])


func _input(event: InputEvent) -> void:
	"""Demo keyboard controls"""
	if not event is InputEventKey or not event.pressed:
		return
	
	if not _skills_component:
		return
	
	# Press 1-4 to gain XP in different skills
	match event.keycode:
		KEY_1:
			print("\n[User Input] Gaining Unarmed Combat XP")
			_skills_component.gain_xp(SkillEnums.SkillType.UNARMED, 50.0, "user_input")
		KEY_2:
			print("\n[User Input] Gaining Sneaking XP")
			_skills_component.gain_xp(SkillEnums.SkillType.SNEAKING, 50.0, "user_input")
		KEY_3:
			print("\n[User Input] Gaining Scavenging XP")
			_skills_component.gain_xp(SkillEnums.SkillType.SCAVENGING, 50.0, "user_input")
		KEY_4:
			print("\n[User Input] Gaining Lockpicking XP")
			_skills_component.gain_xp(SkillEnums.SkillType.LOCKPICKING, 50.0, "user_input")
		KEY_SPACE:
			print("\n[User Input] Current skill levels:")
			print("  - Unarmed Combat: Level ", _skills_component.get_level(SkillEnums.SkillType.UNARMED))
			print("  - Sneaking: Level ", _skills_component.get_level(SkillEnums.SkillType.SNEAKING))
			print("  - Scavenging: Level ", _skills_component.get_level(SkillEnums.SkillType.SCAVENGING))
			print("  - Lockpicking: Level ", _skills_component.get_level(SkillEnums.SkillType.LOCKPICKING))
