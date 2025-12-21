class_name TooltipSettings
extends Resource
## Settings for tooltip behavior.

@export var lock_mode: TooltipLockMode.Mode = TooltipLockMode.Mode.NONE
@export var lock_time: float = 0.5
@export var unlock_time: float = 0.3
@export var wrap_text: bool = true


static func create_default() -> TooltipSettings:
	var settings := TooltipSettings.new()
	settings.lock_mode = TooltipLockMode.Mode.NONE
	settings.lock_time = 0.5
	settings.unlock_time = 0.3
	settings.wrap_text = true
	return settings
