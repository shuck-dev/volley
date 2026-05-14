extends Node

const _SLICE_SCRIPTS := {
	"economy": preload("res://scripts/progression/economy_state.gd"),
	"items": preload("res://scripts/progression/item_world_state.gd"),
	"records": preload("res://scripts/progression/records_state.gd"),
	"unlocks": preload("res://scripts/progression/unlocks_state.gd"),
	"partners": preload("res://scripts/progression/partners_state.gd"),
}

var economy: EconomyState
var items: ItemWorldState
var records: RecordsState
var unlocks: UnlocksState
var partners: PartnersState

var _slices: Dictionary = {}
var _storage: SaveStorage

var _autosave_interval: float
var _autosave_timer: Timer
var _write_blocked: bool = false

## Callable invoked just before each disk write so live runtime state (ball /
## loose-body positions) is captured into the items slice. Empty when unset.
var _position_provider: Callable = Callable()


func _init(autosave_interval: float = 10.0) -> void:
	_autosave_interval = autosave_interval
	_ensure_slices()


func _ready() -> void:
	if _storage == null:
		_storage = FileSaveStorage.new()

	_ensure_slices()
	load_from_disk()

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = _autosave_interval
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(save)
	add_child(_autosave_timer)


## Test seam: swap the storage backend before _ready() or between operations.
func set_storage(storage: SaveStorage) -> void:
	_storage = storage


# todo: SH-400 stamp schema_version and run the migration chain on load at v1.
## Saves game. No-op while writes are blocked by a pending clear.
func save() -> void:
	if _write_blocked:
		return
	_capture_live_positions()
	_write_to_disk()


## Loads from storage, falling back to rolling backups if primary fails to parse.
## Mutates each slice in place so cached refs across the project stay valid.
func load_from_disk() -> bool:
	if _apply_loaded_content(_storage.read()):
		return true
	var fallbacks: Variant = _storage.read_fallbacks()

	if fallbacks is Array:
		for content: Variant in fallbacks:
			if content is String and _apply_loaded_content(content):
				return true
	return false


func _write_to_disk() -> bool:
	return _storage.write(JSON.stringify(_assemble_save_dict()))


func _apply_loaded_content(content: String) -> bool:
	if content == "":
		return false
	var parsed: Variant = JSON.parse_string(content)

	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	_dispatch_save_dict(data)
	return true


func _assemble_save_dict() -> Dictionary:
	var assembled: Dictionary = {}
	for key: String in _slices:
		assembled[key] = _slices[key].to_save_dict()
	return assembled


func _dispatch_save_dict(data: Dictionary) -> void:
	for key: String in _slices:
		var slice_data: Variant = data.get(key, {})
		if slice_data is Dictionary:
			_slices[key].apply_save_dict(slice_data)
		else:
			_slices[key].apply_save_dict({})


## Registers a callable that returns a Dictionary[String, Vector2] of live
## positions. The reconciler hooks in here so positions survive scene reload.
func set_position_provider(provider: Callable) -> void:
	_position_provider = provider


func _capture_live_positions() -> void:
	if not _position_provider.is_valid():
		return
	var live: Variant = _position_provider.call()
	if not live is Dictionary:
		return
	var typed: Dictionary[String, Vector2] = {}
	for key: Variant in live:
		var value: Variant = live[key]
		if value is Vector2:
			typed[str(key)] = value
	items.ball_positions = typed


## Clears progression and blocks writes so the scene reload that follows cannot
## autosave stale state back to disk. Callers must invoke unblock_writes() (via
## call_deferred after reload_current_scene) to resume normal saving.
func clear_save() -> void:
	_write_blocked = true
	if _autosave_timer != null:
		_autosave_timer.stop()
	for key: String in _slices:
		_slices[key].clear()
	_write_to_disk()


## Resumes normal save behaviour after clear_save().
func unblock_writes() -> void:
	_write_blocked = false
	if _autosave_timer != null:
		_autosave_timer.start()


# save() honours the write-block here: a quit mid-clear would otherwise overwrite
# the freshly cleared save with stale in-memory state.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()


func _ensure_slices() -> void:
	if economy == null:
		economy = _SLICE_SCRIPTS["economy"].new()
	if items == null:
		items = _SLICE_SCRIPTS["items"].new()
	if records == null:
		records = _SLICE_SCRIPTS["records"].new()
	if unlocks == null:
		unlocks = _SLICE_SCRIPTS["unlocks"].new()
	if partners == null:
		partners = _SLICE_SCRIPTS["partners"].new()

	_slices = {
		"economy": economy,
		"items": items,
		"records": records,
		"unlocks": unlocks,
		"partners": partners,
	}
