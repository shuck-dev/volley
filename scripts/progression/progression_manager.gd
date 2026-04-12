extends Node

signal shop_unlocked_changed(is_unlocked: bool)
signal partner_recruit_available(partner: PartnerDefinition)
signal partner_recruited(partner_key: StringName)

const DEFAULT_CONFIG: ProgressionConfig = preload("res://resources/progression_config.tres")

var partners: Array[PartnerDefinition] = [
	preload("res://resources/partners/martha.tres"),
]

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

	for partner in partners:
		if partner.key in _progression.unlocked_partners:
			continue
		if _progression.total_friendship_points_earned >= partner.unlock_threshold:
			partner_recruit_available.emit.call_deferred(partner)


func get_config() -> ProgressionConfig:
	return _config


## Returns whether the shop has been unlocked
func is_shop_unlocked() -> bool:
	return _progression.shop_unlocked


func get_partner(partner_key: StringName) -> PartnerDefinition:
	for partner in partners:
		if partner.key == partner_key:
			return partner
	return null


func is_partner_unlocked(partner_key: StringName) -> bool:
	return partner_key in _progression.unlocked_partners


func can_recruit_partner(partner_key: StringName) -> bool:
	var partner := get_partner(partner_key)
	if partner == null:
		return false
	return (
		not is_partner_unlocked(partner_key)
		and _progression.total_friendship_points_earned >= partner.unlock_threshold
		and _progression.friendship_point_balance >= partner.unlock_cost
	)


func recruit_partner(partner_key: StringName) -> bool:
	if not can_recruit_partner(partner_key):
		return false
	var partner := get_partner(partner_key)
	_item_manager.subtract_friendship_points(partner.unlock_cost)
	_progression.unlocked_partners.append(partner_key)
	_progression.active_partner = partner_key
	_save_manager.save()
	partner_recruited.emit(partner_key)
	return true


func _on_friendship_point_balance_changed(_balance: int) -> void:
	_check_shop_unlock()
	_check_partner_unlocks()


func _check_shop_unlock() -> void:
	if _progression.shop_unlocked:
		return
	if _progression.total_friendship_points_earned >= _config.shop_unlock_threshold:
		_progression.shop_unlocked = true
		_save_manager.save()
		shop_unlocked_changed.emit(true)


func _check_partner_unlocks() -> void:
	for partner in partners:
		if partner.key in _progression.unlocked_partners:
			continue
		if _progression.total_friendship_points_earned >= partner.unlock_threshold:
			partner_recruit_available.emit(partner)
