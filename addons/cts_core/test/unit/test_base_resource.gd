extends GutTest

## BaseResource Tests (12 tests)
## Tests validation, serialization, duplication

var BaseResource = preload("res://addons/cts_core/Core/base_resource.gd")
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")

# ============================================================
# VALIDATION TESTS (5 tests)
# ============================================================

func test_validate_returns_false_for_empty_resource_id() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &""
	
	var result: bool = resource.validate()
	
	assert_false(result)

func test_validate_returns_false_for_short_resource_id() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"ab"  # Too short
	
	var result: bool = resource.validate()
	
	assert_false(result)

func test_validate_returns_false_for_negative_version() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"valid_id"
	resource.resource_version = -1
	
	var result: bool = resource.validate()
	
	assert_false(result)

func test_validate_returns_true_for_valid_resource() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"valid_resource"
	resource.resource_version = 1
	
	var result: bool = resource.validate()
	
	assert_true(result)

func test_get_validation_errors_returns_errors() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &""  # Invalid
	
	resource.validate()
	var errors: Array[String] = resource.get_validation_errors()
	
	assert_gt(errors.size(), 0)

# ============================================================
# VALIDATION RESULT TESTS (3 tests)
# ============================================================

func test_get_validation_result_returns_result() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"valid_id"
	resource.resource_version = 1
	
	resource.validate()
	var result = resource.get_validation_result()  # Returns ValidationResult
	
	assert_not_null(result)
	assert_true(result.is_valid)

func test_is_valid_returns_correct_state() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"valid_id"
	resource.resource_version = 1
	
	assert_true(resource.is_valid())

func test_get_validation_warnings_returns_warnings() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"valid_id"
	resource.resource_version = 1
	
	resource.validate()
	var warnings: Array[String] = resource.get_validation_warnings()
	
	# Should be empty for basic validation
	assert_eq(warnings.size(), 0)

# ============================================================
# SERIALIZATION TESTS (2 tests)
# ============================================================

func test_to_dict_returns_dictionary() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"test_resource"
	resource.resource_version = 42
	
	var dict: Dictionary = resource.to_dict()
	
	assert_eq(dict["resource_id"], &"test_resource")
	assert_eq(dict["resource_version"], 42)

func test_from_dict_loads_data() -> void:
	var resource = BaseResource.new()
	var data: Dictionary = {
		"resource_id": &"loaded_resource",
		"resource_version": 99
	}
	
	resource.from_dict(data)
	
	assert_eq(resource.resource_id, &"loaded_resource")
	assert_eq(resource.resource_version, 99)

# ============================================================
# OPERATIONS TESTS (2 tests)
# ============================================================

func test_duplicate_resource_creates_copy() -> void:
	var original = BaseResource.new()
	original.resource_id = &"original"
	original.resource_version = 1
	
	var duplicate: Resource = original.duplicate_resource()
	
	assert_not_null(duplicate)
	assert_ne(duplicate, original)
	# BaseResource duplicate should create new Resource
	assert_true(duplicate is Resource)

func test_equals_compares_resources() -> void:
	var resource1 = BaseResource.new()
	resource1.resource_id = &"same_id"
	resource1.resource_version = 1
	
	var resource2 = BaseResource.new()
	resource2.resource_id = &"same_id"
	resource2.resource_version = 1
	
	var resource3 = BaseResource.new()
	resource3.resource_id = &"different_id"
	resource3.resource_version = 1
	
	assert_true(resource1.equals(resource2))
	assert_false(resource1.equals(resource3))
