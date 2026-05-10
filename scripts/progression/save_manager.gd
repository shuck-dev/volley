extends Node

var _progression: ProgressionData

var _autosave_interval: float
var _autosave_timer: Timer
var _write_blocked: bool = false
## Callable invoked just before each disk write so live runtime state (ball /
## loose-body positions) is captured into ProgressionData. Empty when unset.
var _position_provider: Callable = Callable()


func _init(autosave_interval: float = 10.0) -> void:
	_autosave_interval = autosave_interval


func _ready() -> void:
	# Allows direct injection of progression for tests
	if _progression == null:
		_progression = ProgressionData.new()
		_progression.load_from_disk()

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = _autosave_interval
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(save)
	add_child(_autosave_timer)


## Saves game. No-op while writes are blocked by a pending clear.
func save() -> void:
	if _write_blocked:
		return
	_capture_live_positions()
	_progression.save_to_disk()


## Registers a callable that returns a Dictionary[String, Vector2] of live
## positions. The reconciler hooks in here so positions survive scene reload.
func set_position_provider(provider: Callable) -> void:
	_position_provider = provider


func _capture_live_positions() -> void:
	if not _position_provider.is_valid():
		return
	var live: Variant = _position_provider.call()
	if not live is Dictionary:
		return
	var typed: Dictionary[String, Vector2] = {}
	for key: Variant in live:
		var value: Variant = live[key]
		if value is Vector2:
			typed[str(key)] = value
	_progression.item_positions = typed


## Clears progression and blocks writes so the scene reload that follows cannot
## autosave stale state back to disk. Callers must invoke unblock_writes() (via
## call_deferred after reload_current_scene) to resume normal saving.
func clear_save() -> void:
	_write_blocked = true
	if _autosave_timer != null:
		_autosave_timer.stop()
	_progression.clear()
	_progression.save_to_disk()


## Resumes normal save behaviour after clear_save().
func unblock_writes() -> void:
	_write_blocked = false
	if _autosave_timer != null:
		_autosave_timer.start()


# save() honours the write-block here: a quit mid-clear would otherwise overwrite
# the freshly cleared save with stale in-memory state.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


## Returns the currently stored [ProgressionData]
func get_progression_data() -> ProgressionData:
	return _progression
