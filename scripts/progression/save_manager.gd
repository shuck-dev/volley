extends Node

var _progression: ProgressionData

var _autosave_interval: float


func _init(autosave_interval: float = 10.0) -> void:
	_autosave_interval = autosave_interval


func _ready() -> void:
	# Allows direct injection of progression for tests
	if _progression == null:
		_progression = ProgressionData.new()
		_progression.load_from_disk()

	var autosave_timer := Timer.new()
	autosave_timer.wait_time = _autosave_interval
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save)
	add_child(autosave_timer)


## Saves game
func save() -> void:
	_progression.save_to_disk()


## Deletes the save file and resets the in-memory progression. Dev-only helper.
func clear_save() -> void:
	_progression.clear()
	_progression.save_to_disk()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


## Returns the currently stored [ProgressionData]
func get_progression_data() -> ProgressionData:
	return _progression
