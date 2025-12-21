extends Node

## CTS Core Constants
## Global enums, magic numbers, and configuration values
## Docs: See docs/API_REFERENCE.md#core-constants

# ============================================================
# VERSION & SIGNATURE
# ============================================================

## Authoritative signature for version validation
## Format: PREFIX:VERSION:UUID
## Other addons MUST check this signature on enable
const CORE_SIGNATURE: String = "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"

const VERSION_MAJOR: int = 0
const VERSION_MINOR: int = 0
const VERSION_PATCH: int = 0
const VERSION_BUILD: int = 1

# ============================================================
# COMPONENT SYSTEM
# ============================================================

## Component lifecycle states
enum ComponentState {
    UNINITIALIZED,  ## Component created but not initialized
    INITIALIZING,   ## initialize() in progress
    READY,          ## Fully initialized and operational
    ERROR,          ## Initialization or runtime error
    CLEANING_UP     ## cleanup() in progress
}

## Component processing modes
enum ProcessingMode {
    IDLE,     ## Process in _process(delta)
    PHYSICS,  ## Process in _physics_process(delta)
    MANUAL    ## Process only when explicitly called
}

## Maximum registered components before registry_full signal
const MAX_REGISTERED_COMPONENTS: int = 1000

## Maximum length for component_type string
const COMPONENT_TYPE_MAX_LENGTH: int = 64

## Component initialization timeout (milliseconds)
const COMPONENT_INIT_TIMEOUT_MS: float = 100.0

## Component cleanup timeout (milliseconds)
const COMPONENT_CLEANUP_TIMEOUT_MS: float = 50.0

# ============================================================
# FACTORY SYSTEM
# ============================================================

## Factory pooling strategies
enum FactoryPooling {
    DISABLED,    ## No pooling, always instantiate new
    ENABLED,     ## Basic pooling for frequently used objects
    AGGRESSIVE   ## Maximum pooling, reuse everything possible
}

## Maximum cached resources in factory
const CACHE_MAX_SIZE: int = 100

## Cache entry timeout (milliseconds) - unused entries evicted
const CACHE_TIMEOUT_MS: float = 60000.0  # 60 seconds

# ============================================================
# PROCESSOR SYSTEM
# ============================================================

## Frame budget per system (milliseconds)
## CTS standard: 2ms per system for 60 FPS target
const FRAME_BUDGET_MS: float = 2.0

## Maximum items processed per frame (safety limit)
const MAX_ITEMS_PER_FRAME: int = 100

# ============================================================
# RESOURCE VALIDATION
# ============================================================

## Validation severity levels
enum ValidationSeverity {
    ERROR,    ## Blocks resource usage
    WARNING,  ## Non-fatal issue
    INFO      ## Informational message
}

## Minimum resource version supported
const RESOURCE_VERSION_MIN: int = 1

## Minimum resource ID length
const RESOURCE_ID_MIN_LENGTH: int = 1

# ============================================================
# ERROR HANDLING
# ============================================================

## Error codes for consistent error handling across addons
enum ErrorCode {
    OK = 0,                      ## No error
    ERR_COMPONENT_INVALID = 1,   ## Component validation failed
    ERR_SIGNATURE_MISMATCH = 2,  ## Version signature doesn't match
    ERR_REGISTRY_FULL = 3,       ## Max components registered
    ERR_CACHE_MISS = 4,          ## Resource not in cache
    ERR_VALIDATION_FAILED = 5,   ## Resource validation failed
    ERR_TIMEOUT = 6,             ## Operation timed out
    ERR_NOT_FOUND = 7,           ## Component/resource not found
    ERR_ALREADY_EXISTS = 8,      ## Duplicate registration
    ERR_INVALID_STATE = 9,       ## Invalid state for operation
    ERR_BUDGET_EXCEEDED = 10     ## Frame budget exceeded
}

## Debug logging levels
enum DebugLevel {
    ERROR,   ## Fatal errors only
    WARN,    ## Warnings and errors
    INFO,    ## General information
    DEBUG,   ## Detailed debug info
    TRACE    ## Extremely verbose
}

## Current debug level (can be changed at runtime)
var current_debug_level: DebugLevel = DebugLevel.WARN

# ============================================================
# SIGNAL EMISSION PRIORITIES
# ============================================================

## Signal emission frequency classifications
enum SignalFrequency {
    CONSTANT,  ## Every frame (e.g., processing updates)
    FREQUENT,  ## Multiple times per second (e.g., component_ready)
    RARE       ## Infrequent (e.g., manager_initialized)
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

## Get error message for error code
static func get_error_message(code: ErrorCode) -> String:
    match code:
        ErrorCode.OK:
            return "No error"
        ErrorCode.ERR_COMPONENT_INVALID:
            return "Component validation failed"
        ErrorCode.ERR_SIGNATURE_MISMATCH:
            return "Signature mismatch - version incompatibility"
        ErrorCode.ERR_REGISTRY_FULL:
            return "Registry full - max components reached"
        ErrorCode.ERR_CACHE_MISS:
            return "Resource not found in cache"
        ErrorCode.ERR_VALIDATION_FAILED:
            return "Resource validation failed"
        ErrorCode.ERR_TIMEOUT:
            return "Operation timed out"
        ErrorCode.ERR_NOT_FOUND:
            return "Component or resource not found"
        ErrorCode.ERR_ALREADY_EXISTS:
            return "Component already registered"
        ErrorCode.ERR_INVALID_STATE:
            return "Invalid state for operation"
        ErrorCode.ERR_BUDGET_EXCEEDED:
            return "Frame budget exceeded"
        _:
            return "Unknown error code: %d" % code

## Check if error code represents success
static func is_success(code: ErrorCode) -> bool:
    return code == ErrorCode.OK

## Check if error code represents failure
static func is_error(code: ErrorCode) -> bool:
    return code != ErrorCode.OK