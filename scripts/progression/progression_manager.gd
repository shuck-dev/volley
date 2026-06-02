extends Node

# todo: split this autoload by domain (PartnersManager, EconomyManager); the four slices here do not share a concern.

signal shop_unlocked_changed(is_unlocked: bool)
signal partner_recruit_available(partner: PartnerDefinition)
signal partner_recruited(partner_key: StringName)

# preload workaround for autoload class_name ordering (godotengine/godot#75582)
@warning_ignore("shadowed_global_identifier")
const PartnerDefinition = preload("res://scripts/partners/partner_definition.gd")
const DEFAULT_CONFIG: ProgressionConfig = preload("res://resources/progression_config.tres")

var partners_roster: Array[PartnerDefinition] = [
	preload("res://resources/partners/martha.tres"),
]

var economy: EconomyState
var records: RecordsState
var unlocks: UnlocksState
var partners: PartnersState

var _config: ProgressionConfig
var _item_manager: Node
var _save_manager: Node


func _ready() -> void:
	if _save_manager == null:
		_save_manager = SaveManager

	if economy == null:
		economy = _save_manager.economy

	if records == null:
		records = _save_manager.records

	if unlocks == null:
		unlocks = _save_manager.unlocks

	if partners == null:
		partners = _save_manager.partners

	if _config == null:
		_config = DEFAULT_CONFIG

	if _item_manager == null:
		_item_manager = ItemManager

	_item_manager.soul_balance_changed.connect(_on_soul_balance_changed)

	if unlocks.shop_unlocked:
		shop_unlocked_changed.emit.call_deferred(true)

	for partner in partners_roster:
		if partner.key in partners.unlocked_partners:
			continue
		if partner.key in partners.recruit_offered_partners:
			partner_recruit_available.emit.call_deferred(partner)


func get_config() -> ProgressionConfig:
	return _config


## Returns whether the shop has been unlocked
func is_shop_unlocked() -> bool:
	return unlocks.shop_unlocked


func unlock_shop() -> void:
	if unlocks.shop_unlocked:
		return
	unlocks.shop_unlocked = true
	_save_manager.save()
	shop_unlocked_changed.emit(true)


func get_partner(partner_key: StringName) -> PartnerDefinition:
	for partner in partners_roster:
		if partner.key == partner_key:
			return partner
	return null


func is_partner_unlocked(partner_key: StringName) -> bool:
	return partner_key in partners.unlocked_partners


func can_recruit_partner(partner_key: StringName) -> bool:
	var partner: PartnerDefinition = get_partner(partner_key)
	if partner == null:
		return false
	return (
		not is_partner_unlocked(partner_key)
		and economy.total_soul_earned >= partner.unlock_threshold
		and economy.soul_balance >= partner.unlock_cost
	)


func recruit_partner(partner_key: StringName) -> bool:
	if not can_recruit_partner(partner_key):
		return false
	var partner: PartnerDefinition = get_partner(partner_key)
	_item_manager.subtract_soul(partner.unlock_cost)
	partners.unlocked_partners.append(partner_key)
	partners.active_partner = partner_key
	_save_manager.save()
	partner_recruited.emit(partner_key)
	return true


func _on_soul_balance_changed(_balance: int) -> void:
	_check_shop_unlock()
	_check_partner_unlocks()


func _check_shop_unlock() -> void:
	if unlocks.shop_unlocked:
		return
	if economy.total_soul_earned >= _config.shop_unlock_threshold:
		unlocks.shop_unlocked = true
		_save_manager.save()
		shop_unlocked_changed.emit(true)


func _check_partner_unlocks() -> void:
	var newly_offered := false
	for partner in partners_roster:
		if partner.key in partners.unlocked_partners:
			continue
		if partner.key in partners.recruit_offered_partners:
			continue
		if economy.total_soul_earned >= partner.unlock_threshold:
			partners.recruit_offered_partners.append(partner.key)
			newly_offered = true
			partner_recruit_available.emit(partner)
	if newly_offered:
		_save_manager.save()
