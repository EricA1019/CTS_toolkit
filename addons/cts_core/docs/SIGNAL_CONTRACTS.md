# CTS Core Signal Contracts

> **Version**: 0.0.0.1  
> **Purpose**: Signal-first architecture - all signals documented before implementation  
> **Convention**: Typed parameters, documented emission timing, test paths

---

## Table of Contents

1. [CoreManager Signals](#coremanager-signals)
2. [BaseComponent Signals](#basecomponent-signals)
3. [BaseFactory Signals](#basefactory-signals)
4. [BaseProcessor Signals](#baseprocessor-signals)
5. [BaseResource Signals](#baseresource-signals)
6. [Signal Conventions](#signal-conventions)

---

## CoreManager Signals

### manager_initialized

**When**: After CTS_Core autoload `_ready()` completes  
**Payload**: None  
**Emitters**: `CoreManager._ready()`  
**Listeners**: (Future) Analytics, debug tools, dependent addon initialization hooks  
**Frequency**: RARE (once per session)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_core_manager.gd::test_manager_initialized_signal_emitted`

**Usage**:
```gdscript
CTS_Core.manager_initialized.connect(_on_core_ready)

func _on_core_ready() -> void:
    print(\"CTS_Core is ready\")
```

---

### signature_mismatch_detected

**When**: When dependent addon signature doesn't match expected  
**Payload**:
- `expected: String` - Expected signature from addon
- `actual: String` - Actual signature from CTS_Core
**Emitters**: `CoreManager.validate_signature()`  
**Listeners**: Error logging, user notification systems  
**Frequency**: RARE (only on version mismatches)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_core_manager.gd::test_signature_mismatch_emitted`

**Usage**:
```gdscript
CTS_Core.signature_mismatch_detected.connect(_on_signature_mismatch)

func _on_signature_mismatch(expected: String, actual: String) -> void:
    push_error(\"Version mismatch: expected %s, got %s\" % [expected, actual])
```

---

### component_registered

**When**: After component successfully added to registry, before `component_ready` signal  
**Payload**:
- `component_type: String` - Component type identifier
- `component: Node` - Reference to registered component
**Emitters**: `CoreManager.register_component()`  
**Listeners**: Debug UI, analytics, component dependency systems  
**Frequency**: FREQUENT (multiple times during startup/scene load)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_core_manager.gd::test_component_registered_signal_emitted`

**Usage**:
```gdscript
CTS_Core.component_registered.connect(_on_component_registered)

func _on_component_registered(type: String, comp: Node) -> void:
    print(\"Component registered: %s\" % type)
```

---

### component_unregistered

**When**: After component removed from registry  
**Payload**:
- `component_type: String` - Component type that was removed
**Emitters**: `CoreManager.unregister_component()`  
**Listeners**: Dependency cleanup, analytics  
**Frequency**: FREQUENT (on component/scene free)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_core_manager.gd::test_component_unregistered_signal_emitted`

**Usage**:
```gdscript
CTS_Core.component_unregistered.connect(_on_component_unregistered)

func _on_component_unregistered(type: String) -> void:
    print(\"Component unregistered: %s\" % type)
```

---

### registry_full

**When**: When `MAX_REGISTERED_COMPONENTS` limit reached  
**Payload**: None  
**Emitters**: `CoreManager.register_component()`  
**Listeners**: Warning systems, auto-cleanup triggers  
**Frequency**: RARE (only if component limit hit)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_core_manager.gd::test_registry_full_signal_emitted`

**Usage**:
```gdscript
CTS_Core.registry_full.connect(_on_registry_full)

func _on_registry_full() -> void:
    push_warning(\"Component registry full - max %d components\" % CoreConstants.MAX_REGISTERED_COMPONENTS)
```

---

## BaseComponent Signals

### component_ready

**When**: After `initialize()` completes successfully  
**Payload**:
- `component_type: String` - Type of component that is ready
**Emitters**: `BaseComponent.initialize()`  
**Listeners**: Parent entities, systems waiting for component initialization  
**Frequency**: FREQUENT (per component initialization)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_component.gd::test_component_ready_signal_emitted`

**Usage**:
```gdscript
component.component_ready.connect(_on_component_ready)

func _on_component_ready(type: String) -> void:
    print(\"%s component is ready\" % type)
```

---

### component_initialized

**When**: During `initialize()`, before state transitions to READY  
**Payload**:
- `component_type: String` - Type of component being initialized
**Emitters**: `BaseComponent.initialize()`  
**Listeners**: Lifecycle hooks, dependency initialization  
**Frequency**: FREQUENT (per component)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_component.gd::test_component_initialized_signal_emitted`

**Usage**:
```gdscript
component.component_initialized.connect(_on_initializing)

func _on_initializing(type: String) -> void:
    print(\"%s initializing...\" % type)
```

---

### component_error

**When**: On initialization failure or runtime error  
**Payload**:
- `error_code: int` - CoreConstants.ErrorCode value
- `message: String` - Error description
**Emitters**: `BaseComponent` validation/runtime methods  
**Listeners**: Error handlers, debug UI  
**Frequency**: RARE (only on errors)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_component.gd::test_component_error_signal_emitted`

**Usage**:
```gdscript
component.component_error.connect(_on_component_error)

func _on_component_error(code: int, msg: String) -> void:
    push_error(\"Component error [%d]: %s\" % [code, msg])
```

---

### component_cleanup_started

**When**: Before `cleanup()` begins  
**Payload**:
- `component_type: String` - Type of component being cleaned up
**Emitters**: `BaseComponent.cleanup()`  
**Listeners**: Dependency cleanup triggers  
**Frequency**: FREQUENT (on component free)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_component.gd::test_component_cleanup_started_signal_emitted`

**Usage**:
```gdscript
component.component_cleanup_started.connect(_on_cleanup)

func _on_cleanup(type: String) -> void:
    print(\"%s cleaning up...\" % type)
```

---

## BaseFactory Signals

### resource_created

**When**: After resource successfully created via `create_resource()`  
**Payload**:
- `resource_type: String` - Type of resource created
- `resource: Resource` - Reference to created resource
**Emitters**: `BaseFactory.create_resource()`  
**Listeners**: Analytics, resource tracking systems  
**Frequency**: FREQUENT (per resource creation)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_resource_created_signal_emitted`

**Usage**:
```gdscript
factory.resource_created.connect(_on_resource_created)

func _on_resource_created(type: String, res: Resource) -> void:
    print(\"Created resource: %s\" % type)
```

---

### node_instantiated

**When**: After scene successfully instantiated via `create_node()`  
**Payload**:
- `scene_path: String` - Path to scene file
- `node: Node` - Reference to instantiated node
**Emitters**: `BaseFactory.create_node()`  
**Listeners**: Node tracking, pooling systems  
**Frequency**: FREQUENT (per node instantiation)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_node_instantiated_signal_emitted`

**Usage**:
```gdscript
factory.node_instantiated.connect(_on_node_created)

func _on_node_created(path: String, node: Node) -> void:
    print(\"Instantiated: %s\" % path)
```

---

### cache_hit

**When**: Resource found in cache, no disk load needed  
**Payload**:
- `path: String` - Resource path that was cached
**Emitters**: `BaseFactory.cache_resource()`  
**Listeners**: Performance profiling, cache analytics  
**Frequency**: FREQUENT (per cache access)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_cache_hit_signal_emitted`

**Usage**:
```gdscript
factory.cache_hit.connect(_on_cache_hit)

func _on_cache_hit(path: String) -> void:
    # Performance optimization working
    pass
```

---

### cache_miss

**When**: Resource not in cache, loading from disk  
**Payload**:
- `path: String` - Resource path being loaded
**Emitters**: `BaseFactory.cache_resource()`  
**Listeners**: Performance profiling, loading UI  
**Frequency**: FREQUENT (on first access)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_cache_miss_signal_emitted`

**Usage**:
```gdscript
factory.cache_miss.connect(_on_cache_miss)

func _on_cache_miss(path: String) -> void:
    print(\"Loading from disk: %s\" % path)
```

---

### cache_cleared

**When**: Factory cache flushed via `clear_cache()`  
**Payload**: None  
**Emitters**: `BaseFactory.clear_cache()`  
**Listeners**: Memory management, analytics  
**Frequency**: RARE (manual cache clear)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_cache_cleared_signal_emitted`

**Usage**:
```gdscript
factory.cache_cleared.connect(_on_cache_cleared)

func _on_cache_cleared() -> void:
    print(\"Factory cache cleared\")
```

---

### factory_error

**When**: Resource/node creation fails  
**Payload**:
- `error_code: int` - CoreConstants.ErrorCode value
- `context: Dictionary` - Error details (path, type, etc.)
**Emitters**: `BaseFactory` creation methods  
**Listeners**: Error handlers, user notifications  
**Frequency**: RARE (only on errors)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_factory.gd::test_factory_error_signal_emitted`

**Usage**:
```gdscript
factory.factory_error.connect(_on_factory_error)

func _on_factory_error(code: int, context: Dictionary) -> void:
    push_error(\"Factory error [%d]: %s\" % [code, context.get(\"message\", \"\")])
```

---

## BaseProcessor Signals

### processing_started

**When**: Before `process_items()` loop begins  
**Payload**: None  
**Emitters**: `BaseProcessor.process_items()`  
**Listeners**: Performance profiling, debug UI  
**Frequency**: CONSTANT (every frame if processing)  
**Performance Impact**: MEDIUM  
**Test**: `test/unit/test_base_processor.gd::test_processing_started_signal_emitted`

**Usage**:
```gdscript
processor.processing_started.connect(_on_processing_start)

func _on_processing_start() -> void:
    # Frame processing beginning
    pass
```

---

### processing_completed

**When**: After `process_items()` loop finishes  
**Payload**:
- `items_processed: int` - Number of items processed this frame
**Emitters**: `BaseProcessor.process_items()`  
**Listeners**: Performance monitoring, analytics  
**Frequency**: CONSTANT (every frame if processing)  
**Performance Impact**: MEDIUM  
**Test**: `test/unit/test_base_processor.gd::test_processing_completed_signal_emitted`

**Usage**:
```gdscript
processor.processing_completed.connect(_on_processing_done)

func _on_processing_done(count: int) -> void:
    print(\"Processed %d items\" % count)
```

---

### budget_exceeded

**When**: Frame budget exceeded during processing  
**Payload**:
- `elapsed_ms: float` - Actual time elapsed (> budget)
**Emitters**: `BaseProcessor.process_items()`  
**Listeners**: Performance warnings, optimization triggers  
**Frequency**: RARE (only when budget violated)  
**Performance Impact**: LOW  
**Test**: `test/unit/test_base_processor.gd::test_budget_exceeded_signal_emitted`

**Usage**:
```gdscript
processor.budget_exceeded.connect(_on_budget_exceeded)

func _on_budget_exceeded(elapsed: float) -> void:
    push_warning(\"Budget exceeded: %.2fms\" % elapsed)
```

---

### item_added

**When**: Item added to processing queue via `add_item()`  
**Payload**:
- `item: Variant` - Item that was added
**Emitters**: `BaseProcessor.add_item()`  
**Listeners**: Debug UI, queue monitoring  
**Frequency**: FREQUENT (per item add)  
**Performance Impact**: MEDIUM  
**Test**: `test/unit/test_base_processor.gd::test_item_added_signal_emitted`

**Usage**:
```gdscript
processor.item_added.connect(_on_item_added)

func _on_item_added(item: Variant) -> void:
    print(\"Item added to queue\")
```

---

### item_removed

**When**: Item removed from processing queue via `remove_item()`  
**Payload**:
- `item: Variant` - Item that was removed
**Emitters**: `BaseProcessor.remove_item()`  
**Listeners**: Debug UI, queue monitoring  
**Frequency**: FREQUENT (per item remove)  
**Performance Impact**: MEDIUM  
**Test**: `test/unit/test_base_processor.gd::test_item_removed_signal_emitted`

**Usage**:
```gdscript
processor.item_removed.connect(_on_item_removed)

func _on_item_removed(item: Variant) -> void:
    print(\"Item removed from queue\")
```

---

## BaseResource Signals

**BaseResource has NO signals** - Resources cannot emit signals directly (not in scene tree).

To observe resource validation results, use return values from `validate()` or poll `get_validation_result()`.

For signal-based validation, wrap resources in a Node-based validator that emits signals after calling resource methods.

---

## Signal Conventions

### Parameter Naming
- **entity_id**: Who is affected (string identifier)
- **value**: Numeric change (positive = gain, negative = loss)
- **source_id**: What caused the change (string identifier)
- **component_type**: Component type string from `component_type` property
- **error_code**: CoreConstants.ErrorCode enum value
- **message**: Human-readable string description

### Emission Timing
- **BEFORE state change**: `component_cleanup_started`, `processing_started`
- **AFTER state change**: `component_registered`, `component_ready`, `cache_cleared`
- **DURING operation**: `component_initialized`, `processing_completed`

### Frequency Classifications
- **CONSTANT**: Every frame (e.g., `processing_started`)
- **FREQUENT**: Multiple times per second (e.g., `component_ready`)
- **RARE**: Infrequent (e.g., `manager_initialized`, errors)

### Performance Impact
- **LOW**: <0.1ms overhead per emission
- **MEDIUM**: 0.1-1ms overhead (batch signals, frequent emissions)
- **HIGH**: >1ms overhead (avoid in hot paths)

### Testing Pattern
All signals MUST have test coverage verifying:
1. Signal exists on class
2. Signal emitted when expected
3. Signal payload has correct types
4. Signal emission timing (before/after state change)

---

**Total Signals**: 20  
**Document Version**: 1.0  
**Last Updated**: 2025-12-20  
**Status**: Complete