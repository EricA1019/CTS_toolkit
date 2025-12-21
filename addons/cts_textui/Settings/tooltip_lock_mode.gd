class_name TooltipLockMode
## Determines how tooltips can be locked/pinned.

enum Mode {
	## Tooltips cannot be locked
	NONE = 0,
	## Tooltips lock when hovered for a duration
	HOVER_LOCK = 1,
	## Tooltips lock when clicked
	ACTION_LOCK = 2,
	## Both hover and action lock
	BOTH = 3
}
