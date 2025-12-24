# cts_affix Signal Contracts

All affix signals are centralized in `AffixSignalRegistry` (autoload). This document is authoritative for payload shapes and emission order.

## Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `affix_applied` | `entity_id: String, affix_instance: AffixInstance` | Fired after an affix is applied to an entity and its modifier is pushed into `CTS_Skills`. |
| `affix_removed` | `entity_id: String, source_id: String, affix_instance: AffixInstance, reason: String` | Fired after an affix (by source_id) is removed from an entity and its modifier is pulled from `CTS_Skills`. |
| `affix_rolled` | `pool_id: String, affix_data: AffixData, rolled_value: float, affix_instance: AffixInstance` | Fired when an affix is instantiated from a definition (either direct roll or pool roll). |
| `pool_rolled` | `pool_id: String, rarity: int` | Fired when a pool selects a rarity tier during `roll_from_pool()`. |

## Types

- `AffixData`: definition resource (`affix_id`, `display_name`, `skill_type`, `modifier_type`, `value_min`, `value_max`, `rarity`, `slot`).
- `AffixInstance`: rolled resource (`affix_data`, `rolled_value`, `source_id`).

## Emission Order

- `affix_rolled` emits before any application to entities.
- `pool_rolled` emits before `affix_rolled` when rolling via pools.
- `affix_applied` emits after `CTS_Skills.apply_modifier()` succeeds.
- `affix_removed` emits after `CTS_Skills.remove_modifier()` succeeds.