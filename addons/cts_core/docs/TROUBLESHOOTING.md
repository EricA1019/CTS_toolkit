# CTS Core Troubleshooting

Common errors and solutions.

---

## Component Registration Issues

### Error: "Component has no component_type"

**Symptom**:
```
[CoreManager] Component has no component_type - cannot register
```

**Cause**: Component missing `component_type` property or metadata.

**Solution**:
```gdscript
# In your component's _ready():
func _ready() -> void:
    component_type = "MyComponent"  # REQUIRED
    super._ready()
```

---

### Error: "Component already registered"

**Symptom**: Duplicate registration warnings

**Cause**: Component added to scene tree multiple times or _ready() called multiple times

**Solution**:
- Ensure component only added once
- Check for duplicate add_child() calls
- Verify scene structure doesn't have duplicate nodes

---

### Components Not Found with get_components_by_type()

**Symptom**: Empty array returned despite components existing

**Possible Causes**:
1. **Component not registered yet**: Wait one frame after add_child()
```gdscript
add_child(my_component)
await get_tree().process_frame  # Wait for _ready()
var comps = CTS_Core.get_components_by_type("MyComponent")
```

2. **Wrong component_type string**: Case-sensitive match required
```gdscript
component_type = "MyComponent"  # Not "mycomponent" or "my_component"
```

3. **Component freed**: Orphan cleanup removes invalid nodes
```gdscript
if is_instance_valid(my_component):
    var comps = CTS_Core.get_components_by_type("MyComponent")
```

---

## Signature Validation Issues

### Error: "CTS_Core autoload not found"

**Cause**: CTS Core addon not enabled or autoload not registered

**Solution**:
1. Enable addon: Project → Project Settings → Plugins → CTS Core → Enable
2. Verify autoload: Project → Project Settings → Autoload → "CTS_Core" should be listed
3. Restart Godot editor

---

### Error: "Signature mismatch detected"

**Symptom**:
```
[MyAddon] CTS Core signature mismatch!
Expected: CTS_CORE:0.0.0.1:uuid
Got: CTS_CORE:0.0.0.2:uuid
```

**Cause**: CTS Core version changed (breaking change)

**Solution**:
- Update dependent addon to match new CORE_SIGNATURE
- Check CTS Core changelog for migration guide
- Regenerate addons with updated signature

---

## Factory Issues

### Error: "Resource not found"

**Symptom**:
```
[BaseFactory] Error 7: Resource not found
```

**Cause**: Invalid resource path or resource doesn't exist

**Solution**:
```gdscript
# Verify path exists
if ResourceLoader.exists(path):
    var resource = factory.cache_resource(path)
else:
    push_error("Resource missing: ", path)
```

---

### Cache Not Working

**Symptom**: cache_hit signal never emitted

**Possible Causes**:
1. **Caching disabled**:
```gdscript
var config = FactoryConfig.new()
config.cache_enabled = true  # Ensure enabled
factory.set_config(config)
```

2. **Cache expired**: Check timeout settings
```gdscript
config.cache_timeout_ms = 60000  # 60 seconds
```

3. **Cache cleared**: Check for clear_cache() calls

---

### Memory Leak from Factory

**Symptom**: Memory usage grows over time

**Cause**: Cached resources never released

**Solution**:
```gdscript
# Periodically clear cache
func _on_level_changed() -> void:
    factory.clear_cache()

# Or use smaller cache size
config.max_cache_size = 50  # Limit cached items
```

---

## Processor Issues

### Budget Always Exceeded

**Symptom**: budget_exceeded signal emitted every frame

**Possible Causes**:
1. **Too many items**: Reduce max_items_per_frame
```gdscript
config.max_items_per_frame = 5  # Process fewer per frame
```

2. **Slow _process_item()**: Optimize processing logic
```gdscript
func _process_item(item: Variant, delta: float) -> void:
    # Avoid heavy operations like:
    # - get_tree().get_nodes_in_group()
    # - Multiple find_child() calls
    # - Creating/freeing nodes
```

3. **Budget too tight**: Increase frame budget
```gdscript
processor.set_frame_budget(5.0)  # 5ms instead of 2ms
```

---

### Items Not Processing

**Symptom**: processing_started never emitted

**Possible Causes**:
1. **Processor disabled**:
```gdscript
processor.set_enabled(true)
```

2. **Processor paused**:
```gdscript
processor.resume()
```

3. **No items in queue**:
```gdscript
processor.add_item(my_item)
```

4. **Wrong processing mode**:
```gdscript
config.processing_mode = Constants.ProcessingMode.IDLE  # Or PHYSICS
```

---

## Resource Validation Issues

### Validation Always Fails

**Symptom**: validate() returns false with no clear errors

**Cause**: Check validation messages
```gdscript
if not resource.validate():
    print("Validation failed:")
    for error in resource.get_validation_errors():
        print("  ERROR: ", error)
    for warning in resource.get_validation_warnings():
        print("  WARNING: ", warning)
```

Common issues:
- `resource_id` too short (min 3 characters)
- `resource_version` negative (min 0)
- Custom validation in _validate_custom() failing

---

### Serialization Losing Data

**Symptom**: from_dict() doesn't restore all properties

**Cause**: Custom properties not included in to_dict() / from_dict()

**Solution**: Override both methods
```gdscript
func to_dict() -> Dictionary:
    var data = super.to_dict()
    data["my_custom_property"] = my_custom_property
    return data

func from_dict(data: Dictionary) -> void:
    super.from_dict(data)
    my_custom_property = data.get("my_custom_property", default_value)
```

---

## Type Safety Errors

### Error: "Cannot infer type"

**Symptom**: Godot editor shows type inference error

**Cause**: GDScript can't determine array/lambda types

**Solution**: Use explicit types
```gdscript
# Bad
var items = []

# Good
var items: Array[Node] = []

# Bad
var callback = func(n): return n.health > 0

# Good
var callback = func(n: Node) -> bool: return n.health > 0
```

---

### Headless Mode Test Failures

**Symptom**: Tests pass in editor, fail in headless mode

**Cause**: Autoload access without null check

**Solution**: Use safe access
```gdscript
# Bad
var manager = CTS_Core

# Good
var manager = get_node_or_null("/root/CTS_Core")
if manager == null:
    push_error("CTS_Core not found")
    return
```

---

## Performance Issues

### Frame Rate Drops

**Symptom**: FPS drops during gameplay

**Possible Causes**:
1. **Too many registered components**: Check count
```gdscript
print("Registered components: ", CTS_Core.get_component_count())
# If > 500, consider reducing or splitting systems
```

2. **Expensive queries**: Optimize filter callbacks
```gdscript
# Bad - creates temporary arrays
query.filter_callback = func(n: Node) -> bool:
    return n.get_children().size() > 0

# Good - direct property check
query.filter_callback = func(n: Node) -> bool:
    return n.has_meta("active")
```

3. **Cache thrashing**: Increase cache size
```gdscript
config.max_cache_size = 200  # More cache entries
```

---

## Debug Tips

### Enable Debug Logging

```gdscript
# In autoload script
func _ready() -> void:
    # Enable verbose logging
    OS.set_debug_generation_enabled(true)
```

### Monitor Registry Size

```gdscript
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("debug_registry"):
        print("=== CTS Registry ===")
        print("Total components: ", CTS_Core.get_component_count())
        print("Types registered: ", CTS_Core.get_all_registered_types())
        for type in CTS_Core.get_all_registered_types():
            var count = CTS_Core.get_components_by_type(type).size()
            print("  %s: %d" % [type, count])
```

### Check Factory Cache

```gdscript
func _on_debug_cache_pressed() -> void:
    print("Factory cache size: ", factory.get_cache_size())
    print("Cached resources:")
    # Factory doesn't expose cache keys, but you can track loads
```

### Profile Processor Performance

```gdscript
func _on_debug_processor_pressed() -> void:
    var stats = processor.get_processing_stats()
    print("=== Processor Stats ===")
    print("Frames: ", stats.frames_processed)
    print("Items: ", stats.items_processed)
    print("Avg time: %.2fms" % (stats.total_elapsed_ms / stats.frames_processed))
    print("Budget violations: ", stats.budget_violations)
```

---

## Common Patterns to Avoid

### ❌ Don't: Modify registry directly
```gdscript
# NEVER access _registry or _metadata
CTS_Core._registry["MyType"] = []  # WRONG
```

### ❌ Don't: Register components manually before _ready()
```gdscript
var comp = MyComponent.new()
CTS_Core.register_component(comp)  # WRONG - comp not in tree yet
add_child(comp)
```

### ❌ Don't: Query in tight loops
```gdscript
# Bad - queries every frame
func _process(_delta):
    for enemy in CTS_Core.get_components_by_type("Enemy"):
        enemy.update()
```

### ✅ Do: Cache query results
```gdscript
var _cached_enemies: Array[Node] = []

func _ready():
    _refresh_enemy_cache()

func _refresh_enemy_cache():
    _cached_enemies = CTS_Core.get_components_by_type("Enemy")

func _process(_delta):
    for enemy in _cached_enemies:
        enemy.update()
```

---

## Getting Help

If issues persist:
1. Check [API_REFERENCE.md](API_REFERENCE.md) for method signatures
2. Review [EXAMPLES.md](EXAMPLES.md) for usage patterns
3. Verify [ARCHITECTURE.md](ARCHITECTURE.md) for design intent
4. Check test files for expected behavior patterns
5. Enable debug logging and monitor console output

## Common Error Codes

| Code | Name | Meaning | Solution |
|------|------|---------|----------|
| 0 | SUCCESS | Operation succeeded | None |
| 1 | ERR_COMPONENT_INVALID | Invalid component | Check component_type property |
| 2 | ERR_REGISTRY_FULL | Registry at capacity | Increase MAX_REGISTERED_COMPONENTS |
| 4 | ERR_CACHE_MISS | Resource load failed | Check path, verify resource exists |
| 7 | ERR_NOT_FOUND | Resource not found | Verify file path is correct |
