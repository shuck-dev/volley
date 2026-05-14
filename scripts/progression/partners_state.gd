class_name PartnersState
extends RefCounted

var recruit_offered_partners: Array[StringName] = []
var unlocked_partners: Array[StringName] = []
var active_partner: StringName = &""
var partner_volley_totals: Dictionary[StringName, int] = {}


func clear() -> void:
	recruit_offered_partners = []
	unlocked_partners = []
	active_partner = &""
	partner_volley_totals = {}


func to_save_dict() -> Dictionary:
	return {
		"recruit_offered_partners": recruit_offered_partners,
		"unlocked_partners": unlocked_partners,
		"active_partner": active_partner,
		"partner_volley_totals": partner_volley_totals,
	}


func apply_save_dict(data: Dictionary) -> void:
	recruit_offered_partners = _to_typed_string_name_array(data.get("recruit_offered_partners", []))
	unlocked_partners = _to_typed_string_name_array(data.get("unlocked_partners", []))
	active_partner = StringName(data.get("active_partner", ""))
	partner_volley_totals = _to_typed_string_name_dict(data.get("partner_volley_totals", {}))


static func _to_typed_string_name_array(raw: Array) -> Array[StringName]:
	var typed: Array[StringName] = []

	for value: Variant in raw:
		typed.append(StringName(str(value)))
	return typed


static func _to_typed_string_name_dict(raw: Dictionary) -> Dictionary[StringName, int]:
	var typed: Dictionary[StringName, int] = {}

	for key: Variant in raw:
		typed[StringName(str(key))] = int(raw[key])
	return typed
