extends Node

signal clearance_unlocked_changed(is_unlocked: bool)

const CLEARANCE_UNLOCK_THRESHOLD: int = 50

var _progression: ProgressionData


func _ready() -> void:
	if _progression == null:
		_progression = SaveManager.get_progression_data()

	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)

	if _progression.clearance_unlocked:
		clearance_unlocked_changed.emit.call_deferred(true)


## Returns whether the clearance has been unlocked
func is_clearance_unlocked() -> bool:
	return _progression.clearance_unlocked


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_check_clearance_unlock()


func _check_clearance_unlock() -> void:
	if _progression.clearance_unlocked:
		return
	if _progression.friendship_point_balance >= CLEARANCE_UNLOCK_THRESHOLD:
		_progression.clearance_unlocked = true
		SaveManager.save()
		clearance_unlocked_changed.emit(true)
