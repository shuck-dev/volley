extends Node

signal shop_unlocked_changed(is_unlocked: bool)

const SHOP_UNLOCK_THRESHOLD: int = 50

var _progression: ProgressionData


func _ready() -> void:
	if _progression == null:
		_progression = SaveManager.get_progression_data()

	ItemManager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)

	if _progression.shop_unlocked:
		shop_unlocked_changed.emit.call_deferred(true)


## Returns whether the shop has been unlocked
func is_shop_unlocked() -> bool:
	return _progression.shop_unlocked


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_check_shop_unlock()


func _check_shop_unlock() -> void:
	if _progression.shop_unlocked:
		return
	if _progression.friendship_point_balance >= SHOP_UNLOCK_THRESHOLD:
		_progression.shop_unlocked = true
		SaveManager.save()
		shop_unlocked_changed.emit(true)
