extends Resource
class_name SkillEnums

## Type-safe enums for skills plugin

enum SkillType {
    # Combat Skills
    RIFLES = 0,
    PISTOLS = 1,
    SHOTGUNS = 2,
    MELEE_BLUNT = 3,
    MELEE_BLADED = 4,
    EXPLOSIVES = 5,
    UNARMED = 6,

    # Crafting Skills
    SCAVENGING = 10,
    WEAPON_MAINTENANCE = 11,
    ARMOR_CRAFTING = 12,
    COOKING = 13,
    CHEMISTRY = 14,
    ELECTRONICS = 15,
    ENGINEERING = 16,

    # Social Skills
    INTIMIDATION = 20,
    BARTERING = 21,
    DECEPTION = 22,
    LEADERSHIP = 23,
    PERSUASION = 24,

    # Survival Skills
    SNEAKING = 30,
    LOCKPICKING = 31,
    TRAPPING = 32,
    TRACKING = 33,
    SURVIVAL_INSTINCT = 34,

    # Defensive Skills
    DODGE = 40,
    ARMOR_PROFICIENCY = 41,
    PAIN_TOLERANCE = 42,

    __MAX = 100, # custom skills start here
}

enum ModifierType {
    ADD = 0,
    MULTIPLY = 1,
    OVERRIDE = 2,
}

enum SkillCategory {
    COMBAT = 0,
    CRAFTING = 1,
    SOCIAL = 2,
    SURVIVAL = 3,
    DEFENSIVE = 4,
}
