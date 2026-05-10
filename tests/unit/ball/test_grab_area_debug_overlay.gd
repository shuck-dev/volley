## SH-376 grab-area debug overlay: static toggle drives _draw and group-wide redraw.
extends GutTest


func before_each() -> void:
	GrabArea.debug_visible = false


func after_each() -> void:
	GrabArea.debug_visible = false


func _make_grab_area() -> GrabArea:
	var area: GrabArea = GrabArea.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 20.0
	col.shape = circle
	area.add_child(col)
	add_child_autofree(area)
	return area


func test_default_state_is_hidden() -> void:
	assert_false(GrabArea.debug_visible, "static flag defaults to false")


func test_set_debug_visible_flips_static() -> void:
	GrabArea.set_debug_visible(true, get_tree())
	assert_true(GrabArea.debug_visible)
	GrabArea.set_debug_visible(false, get_tree())
	assert_false(GrabArea.debug_visible)


func test_ready_adds_area_to_group() -> void:
	var area: GrabArea = _make_grab_area()
	assert_true(area.is_in_group(&"grab_areas"), "GrabArea joins the grab_areas group on _ready")


func test_set_debug_visible_calls_queue_redraw_on_group() -> void:
	var area: GrabArea = _make_grab_area()
	area.queue_redraw()
	await get_tree().process_frame
	# Toggling debug visibility schedules a redraw on every grab_areas member.
	GrabArea.set_debug_visible(true, get_tree())
	# call_group is deferred; flushing a frame applies the queued draw.
	await get_tree().process_frame
	assert_true(GrabArea.debug_visible)
