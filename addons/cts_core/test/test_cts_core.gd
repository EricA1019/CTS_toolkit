extends GutTest

## CTS Core Smoke Tests
## Verifies test harness wiring for CTS Core addon

var CoreManager = preload("res://addons/cts_core/Core/core_manager.gd")
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")

var _manager: Node
var _added_manager: bool = false

func before_each() -> void:
    _manager = get_node_or_null("/root/CTS_Core")
    _added_manager = false

    if _manager == null:
        _manager = CoreManager.new()
        _manager.name = "CTS_Core"
        get_tree().get_root().add_child(_manager)
        _added_manager = true

func after_each() -> void:
    if _added_manager and is_instance_valid(_manager):
        _manager.queue_free()
    _manager = null
    _added_manager = false

func test_manager_signature_matches_constant() -> void:
    var signature: String = _manager.get_signature()
    assert_eq(signature, Constants.CORE_SIGNATURE)

func test_manager_reports_registry_stats() -> void:
    var stats: Dictionary = _manager.get_registry_stats()
    assert_true(stats.has("total_components"))
    assert_true(stats.has("signature"))
