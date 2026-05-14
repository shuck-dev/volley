extends Node

var _progression: ProgressionData
var _storage: SaveStorage

var _autosave_interval: float
var _autosave_timer: Timer
var _write_blocked: bool = false
## Callable invoked just before each disk write so live runtime state (ball /
## loose-body positions) is captured into ProgressionData. Empty when unset.
var _position_provider: Callable = Callable()


func _init(autosave_interval: float = 10.0) -> void:
	_autosave_interval = autosave_interval


func _ready() -> void:
	if _storage == null:
		_storage = FileSaveStorage.new()
	# Allows direct injection of progression for tests
	if _progression == null:
		_progression = ProgressionData.new()
		load_from_disk()

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = _autosave_interval
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(save)
	add_child(_autosave_timer)


## Test seam: swap the storage backend before _ready() or between operations.
func set_storage(storage: SaveStorage) -> void:
	_storage = storage


## Saves game. No-op while writes are blocked by a pending clear.
func save() -> void:
	if _write_blocked:
		return
	_capture_live_positions()
	_write_to_disk()


## Loads from storage, falling back to rolling backups if primary fails to parse.
## Mutates the held _progression in place so cached refs across the project
## (court, progression_manager, item_manager, ball_reconciler) stay valid.
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
	return _storage.write(JSON.stringify(_progression.to_dict()))


func _apply_loaded_content(content: String) -> bool:
	if content == "":
		return false
	var parsed: Variant = JSON.parse_string(content)

	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	var loaded := ProgressionData.from_dict(data)
	_progression.friendship_point_balance = loaded.friendship_point_balance
	_progression.total_friendship_points_earned = loaded.total_friendship_points_earned
	_progression.item_levels = loaded.item_levels
	_progression.item_placements = loaded.item_placements
	_progression.item_positions = loaded.item_positions
	_progression.rack_slot_index_by_key = loaded.rack_slot_index_by_key
	_progression.loose_in_venue = loaded.loose_in_venue
	_progression.personal_volley_best = loaded.personal_volley_best
	_progression.shop_unlocked = loaded.shop_unlocked
	_progression.recruit_offered_partners = loaded.recruit_offered_partners
	_progression.unlocked_partners = loaded.unlocked_partners
	_progression.active_partner = loaded.active_partner
	_progression.partner_volley_totals = loaded.partner_volley_totals
	return true


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
	_progression.item_positions = typed


## Clears progression and blocks writes so the scene reload that follows cannot
## autosave stale state back to disk. Callers must invoke unblock_writes() (via
## call_deferred after reload_current_scene) to resume normal saving.
func clear_save() -> void:
	_write_blocked = true
	if _autosave_timer != null:
		_autosave_timer.stop()
	_progression.clear()
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


## Returns the currently stored [ProgressionData]
func get_progression_data() -> ProgressionData:
	return _progression
