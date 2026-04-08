extends Node

signal shop_unlocked_changed(is_unlocked: bool)

const DEFAULT_CONFIG: ProgressionConfig = preload("res://resources/progression_config.tres")

var _progression: ProgressionData
var _config: ProgressionConfig
var _item_manager: Node
var _save_manager: Node


func _ready() -> void:
	if _progression == null:
		_progression = SaveManager.get_progression_data()
	if _config == null:
		_config = DEFAULT_CONFIG
	if _item_manager == null:
		_item_manager = ItemManager
	if _save_manager == null:
		_save_manager = SaveManager

	_item_manager.friendship_point_balance_changed.connect(_on_friendship_point_balance_changed)

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
	if _progression.total_friendship_points_earned >= _config.shop_unlock_threshold:
		_progression.shop_unlocked = true
		_save_manager.save()
		shop_unlocked_changed.emit(true)
