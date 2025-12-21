extends GutTest

## BaseProcessor Tests (14 tests)
## Tests frame budget enforcement, processing queue, deterministic behavior

var BaseProcessor = preload("res://addons/cts_core/Core/base_processor.gd")
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")

var _processor: Node

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	var config = TypeDefs.ProcessorConfig.create_default()
	config.auto_start = false  # Manual control for tests
	_processor = BaseProcessor.new(config)
	add_child(_processor)

func after_each() -> void:
	if is_instance_valid(_processor):
		_processor.queue_free()

# ============================================================
# ITEM MANAGEMENT TESTS (4 tests)
# ============================================================

func test_add_item_increases_count() -> void:
	_processor.add_item("test_item")
	
	assert_eq(_processor.get_item_count(), 1)

func test_add_item_emits_signal() -> void:
	watch_signals(_processor)
	
	_processor.add_item("test_item")
	
	assert_signal_emitted(_processor, "item_added")

func test_remove_item_decreases_count() -> void:
	_processor.add_item("test_item")
	
	var removed: bool = _processor.remove_item("test_item")
	
	assert_true(removed)
	assert_eq(_processor.get_item_count(), 0)

func test_remove_item_emits_signal() -> void:
	_processor.add_item("test_item")
	
	watch_signals(_processor)
	_processor.remove_item("test_item")
	
	assert_signal_emitted(_processor, "item_removed")

# ============================================================
# PROCESSING TESTS (4 tests)
# ============================================================

func test_process_items_emits_processing_started() -> void:
	_processor.add_item("item1")
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	assert_signal_emitted(_processor, "processing_started")

func test_process_items_emits_processing_completed() -> void:
	_processor.add_item("item1")
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	assert_signal_emitted(_processor, "processing_completed")

func test_process_items_skips_when_empty() -> void:
	# No items added
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	# Should not emit signals
	assert_signal_not_emitted(_processor, "processing_started")

func test_clear_items_removes_all() -> void:
	_processor.add_item("item1")
	_processor.add_item("item2")
	
	_processor.clear_items()
	
	assert_eq(_processor.get_item_count(), 0)

# ============================================================
# FRAME BUDGET TESTS (3 tests)
# ============================================================

func test_budget_exceeded_emits_when_over_budget() -> void:
	# Add many items to force budget exceed
	for i in range(1000):
		_processor.add_item("item_%d" % i)
	
	# Set very tight budget
	_processor.set_frame_budget(0.001)  # 1 microsecond
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	# Should emit budget_exceeded
	assert_signal_emitted(_processor, "budget_exceeded")

func test_get_processing_stats_returns_stats() -> void:
	_processor.add_item("item1")
	_processor.process_items(0.016)
	
	var stats = _processor.get_processing_stats()
	
	assert_not_null(stats)
	assert_gt(stats.frames_processed, 0)

func test_set_frame_budget_updates_config() -> void:
	_processor.set_frame_budget(5.0)
	
	var config = _processor.get_config()
	assert_eq(config.frame_budget_ms, 5.0)

# ============================================================
# ENABLE/DISABLE TESTS (3 tests)
# ============================================================

func test_processor_starts_enabled() -> void:
	assert_true(_processor.is_enabled())

func test_set_enabled_changes_state() -> void:
	_processor.set_enabled(false)
	
	assert_false(_processor.is_enabled())

func test_disabled_processor_skips_processing() -> void:
	_processor.add_item("item1")
	_processor.set_enabled(false)
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	# Should not process when disabled
	assert_signal_not_emitted(_processor, "processing_started")

# ============================================================
# PAUSE/RESUME TESTS (2 tests)
# ============================================================

func test_pause_prevents_processing() -> void:
	_processor.add_item("item1")
	_processor.pause()
	
	assert_true(_processor.is_paused())
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	# Should not process when paused
	assert_signal_not_emitted(_processor, "processing_started")

func test_resume_allows_processing() -> void:
	_processor.add_item("item1")
	_processor.pause()
	_processor.resume()
	
	assert_false(_processor.is_paused())
	
	watch_signals(_processor)
	_processor.process_items(0.016)
	
	# Should process after resume
	assert_signal_emitted(_processor, "processing_started")

# ============================================================
# CONFIGURATION TESTS (2 tests - covers 14 total)
# ============================================================

func test_get_config_returns_config() -> void:
	var config = _processor.get_config()
	
	assert_not_null(config)

func test_set_config_updates_configuration() -> void:
	var new_config = TypeDefs.ProcessorConfig.new()
	new_config.frame_budget_ms = 10.0
	new_config.max_items_per_frame = 50
	
	_processor.set_config(new_config)
	var retrieved = _processor.get_config()
	
	assert_eq(retrieved.frame_budget_ms, 10.0)
	assert_eq(retrieved.max_items_per_frame, 50)
