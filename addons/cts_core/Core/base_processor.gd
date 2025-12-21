extends Node

## Base Processor
## Processing loop with frame budget enforcement
## Docs: See docs/API_REFERENCE.md#base-processor

# ============================================================
# SIGNALS (See docs/SIGNAL_CONTRACTS.md)
# ============================================================

signal processing_started()
signal processing_completed(items_processed: int)
signal budget_exceeded(elapsed_ms: float)
signal item_added(item: Variant)
signal item_removed(item: Variant)

# ============================================================
# PROPERTIES
# ============================================================

var _processing_enabled: bool = true
var _items_to_process: Array = []
var _config = null  # ProcessorConfig
var _stats = null  # ProcessingStats
var _is_paused: bool = false

# ============================================================
# LIFECYCLE
# ============================================================

func _init(config = null) -> void:  # Takes ProcessorConfig or null
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    
    if config != null:
        _config = config
    else:
        _config = TypeDefs.ProcessorConfig.create_default()
    
    _stats = TypeDefs.ProcessingStats.new()
    
    # Set up deterministic random if configured
    if _config.deterministic:
        seed(_config.random_seed)

func _ready() -> void:
    if _config.auto_start:
        set_process(true)

func _process(delta: float) -> void:
    if _config.processing_mode != 0:  # Not IDLE mode
        return
    
    if _processing_enabled and not _is_paused:
        process_items(delta)

func _physics_process(delta: float) -> void:
    if _config.processing_mode != 1:  # Not PHYSICS mode
        return
    
    if _processing_enabled and not _is_paused:
        process_items(delta)

# ============================================================
# PUBLIC API - Processing
# ============================================================

## Main processing loop - override for custom processing logic
func process_items(delta: float) -> void:
    if _items_to_process.is_empty():
        return
    
    processing_started.emit()
    
    var start_time: int = Time.get_ticks_usec()
    var processed_count: int = 0
    var max_items: int = mini(_items_to_process.size(), _config.max_items_per_frame)
    
    # Process items within budget
    for i in range(max_items):
        if i >= _items_to_process.size():
            break
        
        var item: Variant = _items_to_process[i]
        
        # Override _process_item() in child classes
        _process_item(item, delta)
        processed_count += 1
        
        # Check budget
        var elapsed_us: int = Time.get_ticks_usec() - start_time
        var elapsed_ms: float = elapsed_us / 1000.0
        
        if elapsed_ms >= _config.frame_budget_ms:
            budget_exceeded.emit(elapsed_ms)
            break
    
    # Update stats
    var final_elapsed: float = (Time.get_ticks_usec() - start_time) / 1000.0
    _stats.record_frame(processed_count, final_elapsed, _config.frame_budget_ms, _items_to_process.size())
    
    processing_completed.emit(processed_count)

## Override in child classes for custom item processing
func _process_item(item: Variant, delta: float) -> void:
    # Override in child classes
    pass

# ============================================================
# PUBLIC API - Item Management
# ============================================================

## Add item to processing queue
func add_item(item: Variant) -> void:
    _items_to_process.append(item)
    item_added.emit(item)

## Remove item from processing queue
## Returns true if item was found and removed
func remove_item(item: Variant) -> bool:
    var idx: int = _items_to_process.find(item)
    if idx >= 0:
        _items_to_process.remove_at(idx)
        item_removed.emit(item)
        return true
    return false

## Clear all items from queue
func clear_items() -> void:
    _items_to_process.clear()

## Get number of items in queue
func get_item_count() -> int:
    return _items_to_process.size()

# ============================================================
# PUBLIC API - Configuration
# ============================================================

## Set frame budget in milliseconds
func set_frame_budget(ms: float) -> void:
    _config.frame_budget_ms = ms

## Get processing statistics
func get_processing_stats():  # Returns ProcessingStats
    return _stats

## Enable or disable processing
func set_enabled(enabled: bool) -> void:
    _processing_enabled = enabled

## Check if processing is enabled
func is_enabled() -> bool:
    return _processing_enabled

## Pause processing (Phase 1 stretch goal)
func pause() -> void:
    _is_paused = true

## Resume processing (Phase 1 stretch goal)
func resume() -> void:
    _is_paused = false

## Check if paused
func is_paused() -> bool:
    return _is_paused

## Get current configuration
func get_config():  # Returns ProcessorConfig
    return _config

## Update configuration
func set_config(config) -> void:  # Takes ProcessorConfig
    _config = config