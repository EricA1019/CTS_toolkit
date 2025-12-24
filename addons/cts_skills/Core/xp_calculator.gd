extends RefCounted
class_name XPCalculator

## XP curve utilities for skills plugin

enum XPCurveType {
    LINEAR = 0,
    EXPONENTIAL = 1,
    CUSTOM = 2,
}

## Returns XP required to advance from `level` to `level + 1`
static func xp_required_for_level(level: int, curve: Dictionary) -> float:
    var curve_type: int = curve.get("curve_type", XPCurveType.EXPONENTIAL)
    var base_xp: float = curve.get("base_xp", 100.0)
    var multiplier: float = curve.get("multiplier", 1.15)
    var custom_curve: PackedFloat32Array = curve.get("custom_curve", PackedFloat32Array())

    match curve_type:
        XPCurveType.LINEAR:
            return base_xp * float(level + 1)
        XPCurveType.EXPONENTIAL:
            return base_xp * pow(multiplier, level)
        XPCurveType.CUSTOM:
            if level >= 0 and level < custom_curve.size():
                return custom_curve[level]
            # fallback to exponential if out of range
            return base_xp * pow(multiplier, level)
        _:
            return base_xp * pow(multiplier, level)

## Convert total XP to level and remaining XP
## Returns {"level": int, "xp_into_level": float, "xp_to_next": float}
static func level_from_total_xp(total_xp: float, curve: Dictionary) -> Dictionary:
    var level := 0
    var remaining_xp := max(total_xp, 0.0)
    var safety := 0
    const MAX_ITERATIONS := 300  # prevents runaway

    while safety < MAX_ITERATIONS:
        var cost := xp_required_for_level(level, curve)
        if remaining_xp < cost:
            return {
                "level": level,
                "xp_into_level": remaining_xp,
                "xp_to_next": cost,
            }
        remaining_xp -= cost
        level += 1
        safety += 1

    # Fallback if loop exceeded
    return {
        "level": level,
        "xp_into_level": 0.0,
        "xp_to_next": xp_required_for_level(level, curve),
    }
