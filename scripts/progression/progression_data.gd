class_name ProgressionData
extends RefCounted

var friendship_point_balance := 0
var total_friendship_points_earned := 0
var item_levels: Dictionary[String, int]
var personal_volley_best := 0
var shop_unlocked := false
var unlocked_partners: Array[StringName] = []
var active_partner: StringName = &""
var partner_volley_totals: Dictionary[StringName, int] = {}

var _storage: SaveStorage


## Resets progression fields to defaults. Deliberately leaves `_storage` alone:
## this is a data reset, not a storage disconnect; the caller decides whether to save.
func clear() -> void:
	friendship_point_balance = 0
	total_friendship_points_earned = 0
	item_levels = {}
	personal_volley_best = 0
	shop_unlocked = false
	unlocked_partners = []
	active_partner = ""
	partner_volley_totals = {}


## Saves game data to storeage (disk)
func save_to_disk() -> bool:
	return _storage.write(JSON.stringify(to_dict()))


## Loads game data from storage (disk)
func load_from_disk() -> bool:
	var content := _storage.read()

	if content == "":
		return false

	var data: Dictionary = JSON.parse_string(content)

	if data == null:
		return false

	var loaded := from_dict(data)
	friendship_point_balance = loaded.friendship_point_balance
	total_friendship_points_earned = loaded.total_friendship_points_earned
	item_levels = loaded.item_levels
	personal_volley_best = loaded.personal_volley_best
	shop_unlocked = loaded.shop_unlocked
	unlocked_partners = loaded.unlocked_partners
	active_partner = loaded.active_partner
	partner_volley_totals = loaded.partner_volley_totals

	return true


## Parses the game data into a dictionary
func to_dict() -> Dictionary:
	return {
		"friendship_point_balance": friendship_point_balance,
		"total_friendship_points_earned": total_friendship_points_earned,
		"item_levels": item_levels,
		"personal_volley_best": personal_volley_best,
		"shop_unlocked": shop_unlocked,
		"unlocked_partners": unlocked_partners,
		"active_partner": active_partner,
		"partner_volley_totals": partner_volley_totals,
	}


## Parses the game data dictionary into a [ProgressionData]
static func from_dict(data: Dictionary) -> ProgressionData:
	var progression := ProgressionData.new()
	progression.friendship_point_balance = data.get("friendship_point_balance", 0)
	progression.total_friendship_points_earned = data.get("total_friendship_points_earned", 0)
	progression.item_levels = _to_typed_dict(data.get("item_levels", {}))
	progression.personal_volley_best = data.get("personal_volley_best", 0)
	progression.shop_unlocked = data.get("shop_unlocked", false)
	progression.unlocked_partners = _to_typed_string_name_array(data.get("unlocked_partners", []))
	progression.active_partner = StringName(data.get("active_partner", ""))
	progression.partner_volley_totals = _to_typed_string_name_dict(
		data.get("partner_volley_totals", {})
	)

	return progression


## Used for mocking
func _init(storage: SaveStorage = null) -> void:
	_storage = storage if storage != null else FileSaveStorage.new()


static func _to_typed_string_name_array(raw: Array) -> Array[StringName]:
	var typed: Array[StringName] = []
	for value in raw:
		typed.append(StringName(str(value)))
	return typed


static func _to_typed_string_name_dict(raw: Dictionary) -> Dictionary[StringName, int]:
	var typed: Dictionary[StringName, int] = {}
	for key in raw:
		typed[StringName(str(key))] = int(raw[key])
	return typed


## Parsed untyped [Dictionary] into typed [Dictionary]
static func _to_typed_dict(raw: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}
	for key: String in raw:
		typed[key] = int(raw[key])

	return typed
