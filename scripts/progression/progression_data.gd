class_name ProgressionData
extends RefCounted

var friendship_point_balance := 0
var upgrade_levels: Dictionary[String, int]
var personal_volley_best := 0

var _storage: SaveStorage


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
	upgrade_levels = loaded.upgrade_levels
	personal_volley_best = loaded.personal_volley_best

	return true


## Parses the game data into a dictionary
func to_dict() -> Dictionary:
	return {
		"friendship_point_balance": friendship_point_balance,
		"upgrade_levels": upgrade_levels,
		"personal_volley_best": personal_volley_best
	}


## Parses the game data dictionary into a [ProgressionData]
static func from_dict(data: Dictionary) -> ProgressionData:
	var progression := ProgressionData.new()
	progression.friendship_point_balance = data.get("friendship_point_balance", 0)
	progression.upgrade_levels = _to_typed_dict(data.get("upgrade_levels", {}))
	progression.personal_volley_best = data.get("personal_volley_best", 0)

	return progression


## Used for mocking
func _init(storage: SaveStorage = null) -> void:
	_storage = storage if storage != null else FileSaveStorage.new()


## Parsed untyped [Dictionary] into typed [Dictionary]
static func _to_typed_dict(raw: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}
	for key: String in raw:
		typed[key] = int(raw[key])

	return typed
