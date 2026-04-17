extends Node

var _progression: ProgressionData

var _autosave_interval: float
var _autosave_timer: Timer
var _write_blocked: bool = false


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
	_progression.save_to_disk()


## Clears progression and blocks writes until unblock_writes(); caller restores after scene reload.
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


## Returns the currently stored [ProgressionData]
func get_progression_data() -> ProgressionData:
	return _progression
