extends VBoxContainer

## Stats owned per-ball instance; shown once per live ball rather than as a single global row.
const BALL_STAT_KEYS: Array[StringName] = [
	&"ball_speed_min",
	&"ball_speed_max_range",
	&"ball_speed_increment",
	&"ball_speed_offset",
	&"ball_magnetism",
	&"tier_floor_lift",
]

var _labels: Dictionary = {}
var _ball_labels: Dictionary = {}
var _drag := DraggableBehavior.new()
# Debug-only: flattened view of every stat's base value for diff readouts.
# Cached once because `_refresh` hits this per stat per frame.
var _cached_base_values: Dictionary = {}
var _cached_ball_base_values: Dictionary = {}

var _tracker: BallReconciler


func _base_values() -> Dictionary:
	if _cached_base_values.is_empty():
		_cached_base_values = GameRules.BASE_CONFIG.to_dict()
		_cached_base_values.merge(GameRules.PADDLE_CONFIG.to_dict())
		for stat_key: StringName in BALL_STAT_KEYS:
			_cached_base_values.erase(stat_key)
	return _cached_base_values


func _ready() -> void:
	_apply_background()

	if not OS.is_debug_build():
		queue_free()
		return

	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_live_labels()
	_add_version_label()
	_refresh()

	_tracker = get_tree().get_first_node_in_group(&"ball_trackers") as BallReconciler

	if _tracker != null:
		_attach_to_tracker()
	else:
		get_tree().node_added.connect(_on_node_added_waiting_for_tracker)


func _exit_tree() -> void:
	if is_inside_tree() and get_tree().node_added.is_connected(_on_node_added_waiting_for_tracker):
		get_tree().node_added.disconnect(_on_node_added_waiting_for_tracker)


func _on_node_added_waiting_for_tracker(node: Node) -> void:
	var tracker := node as BallReconciler

	if tracker == null:
		return
	get_tree().node_added.disconnect(_on_node_added_waiting_for_tracker)
	_tracker = tracker
	_attach_to_tracker()


func _attach_to_tracker() -> void:
	_tracker.ball_added.connect(_on_ball_added)
	_tracker.ball_removed.connect(_on_ball_removed)
	for ball in _tracker.get_balls():
		_on_ball_added(ball)


func _gui_input(event: InputEvent) -> void:
	if _drag.try_start(self, event):
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag.update(self, event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh()


func _draw() -> void:
	pass


func _apply_background() -> void:
	add_theme_constant_override("separation", 2)


func _build_live_labels() -> void:
	_add_header()
	for stat_key: StringName in _base_values():
		var label := _make_stat_label()
		add_child(label)
		_labels[stat_key] = label


func _add_version_label() -> void:
	var label := _make_stat_label()
	label.text = _read_version()
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(label)


func _read_version() -> String:
	if FileAccess.file_exists("res://version.txt"):
		var file := FileAccess.open("res://version.txt", FileAccess.READ)
		if file != null:
			return file.get_as_text().strip_edges()
	if OS.has_feature("editor"):
		var output: Array = []
		if (
			OS.execute("git", ["describe", "--always", "--dirty"], output) == OK
			and output.size() > 0
		):
			return output[0].strip_edges()
	return "unknown"


func _add_header() -> void:
	return


func _make_stat_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label


func _on_ball_added(ball: Ball) -> void:
	if ball == null or _ball_labels.has(ball):
		return

	var labels: Dictionary = {}
	for stat_key: StringName in BALL_STAT_KEYS:
		var label := _make_stat_label()
		add_child(label)
		labels[stat_key] = label
	_ball_labels[ball] = labels


func _on_ball_removed(ball: Ball) -> void:
	if not _ball_labels.has(ball):
		return

	var labels: Dictionary = _ball_labels[ball]
	for stat_key: StringName in labels:
		var label: Label = labels[stat_key]
		if is_instance_valid(label):
			label.queue_free()
	_ball_labels.erase(ball)


func _refresh() -> void:
	for stat_key: StringName in _labels:
		_refresh_stat_label(_labels[stat_key], stat_key, _base_values()[stat_key])

	for ball: Ball in _ball_labels:
		if not is_instance_valid(ball):
			continue
		var labels: Dictionary = _ball_labels[ball]
		for stat_key: StringName in labels:
			_refresh_ball_stat_label(labels[stat_key], stat_key, ball)


func _refresh_stat_label(label: Label, stat_key: StringName, base_value: float) -> void:
	var current_value: float = Stats.resolve(base_value, stat_key)
	_apply_stat_text(
		label, stat_key, base_value, current_value, ItemManager.get_percentage_offset(stat_key)
	)


func _refresh_ball_stat_label(label: Label, stat_key: StringName, ball: Ball) -> void:
	var base_value: float = _ball_stat_base_value(stat_key)
	var current_value: float = Stats.resolve(base_value, stat_key, null, ball.item_key)
	var percentage_offset: float = ItemManager.get_percentage_offset(stat_key, ball.item_key)
	var label_prefix: String = "%s[%s]" % [stat_key, ball.item_key]
	_apply_stat_text(label, label_prefix, base_value, current_value, percentage_offset)


func _ball_stat_base_value(stat_key: StringName) -> float:
	if _cached_ball_base_values.is_empty():
		_cached_ball_base_values = GameRules.BASE_CONFIG.to_dict()
	return _cached_ball_base_values.get(stat_key, 0.0)


func _apply_stat_text(
	label: Label,
	label_key: String,
	base_value: float,
	current_value: float,
	percentage_offset: float
) -> void:
	if is_equal_approx(current_value, base_value):
		label.text = "%s: %.1f" % [label_key, current_value]
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		return

	var diff: float = current_value - base_value
	var sign_prefix: String = "+" if diff > 0 else ""
	label.text = _format_modified_stat(
		label_key, current_value, sign_prefix, diff, percentage_offset
	)
	var color := Color(1.0, 0.5, 0.5) if diff < 0 else Color(0.6, 1.0, 0.6)
	label.add_theme_color_override("font_color", color)


func _format_modified_stat(
	label_key: String,
	current_value: float,
	sign_prefix: String,
	diff: float,
	percentage_offset: float,
) -> String:
	var text := "%s: %.1f (%s%.1f)" % [label_key, current_value, sign_prefix, diff]
	if not is_zero_approx(percentage_offset):
		var pct_prefix: String = "+" if percentage_offset > 0 else ""
		text += " [%s%.0f%%]" % [pct_prefix, percentage_offset * 100]
	return text
