class_name BallNameOverlay
extends Node2D

## Each ball on court shows its display name as a label that follows the ball.

var dev_visible: bool = false
var _tracker: BallReconciler
var _labels: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	z_index = 4095
	top_level = true
	visible = false
	add_to_group(&"dev_overlays")

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


func set_dev_visible(value: bool) -> void:
	dev_visible = value
	visible = value


func _on_ball_added(ball: Ball) -> void:
	if ball == null or _labels.has(ball):
		return

	var label := Label.new()
	label.text = _get_display_name(ball)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	_labels[ball] = label


func _on_ball_removed(ball: Ball) -> void:
	if not _labels.has(ball):
		return

	var label: Label = _labels[ball]
	if is_instance_valid(label):
		label.queue_free()

	_labels.erase(ball)


func _process(_delta: float) -> void:
	if not dev_visible or _labels.is_empty():
		return

	for ball: Ball in _labels.keys():
		if not is_instance_valid(ball):
			continue

		var label: Label = _labels[ball]
		var screen_pos := _project_to_canvas(ball.global_position)
		label.position = screen_pos - label.size * 0.5


func _project_to_canvas(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos


func _get_display_name(ball: Ball) -> String:
	if ball.item_key.is_empty():
		return "ball"

	for item: ItemDefinition in ItemManager.items:
		if item.key == ball.item_key:
			return item.display_name

	return ball.item_key
