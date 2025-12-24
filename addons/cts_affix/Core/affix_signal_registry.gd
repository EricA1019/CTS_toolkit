extends Node
class_name AffixSignalRegistry

## Centralized affix signals (autoload)
signal affix_applied(entity_id: String, affix_instance)
signal affix_removed(entity_id: String, source_id: String, affix_instance, reason: String)
signal affix_rolled(pool_id: String, affix_data, rolled_value: float, affix_instance)
signal pool_rolled(pool_id: String, rarity: int)
