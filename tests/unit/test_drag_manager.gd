extends GutTest

const DragManagerScript: GDScript = preload("res://scripts/core/drag_manager.gd")


class TestShowHide:
	extends GutTest

	var _manager: Node

	func before_each() -> void:
		_manager = DragManagerScript.new()
		add_child_autofree(_manager)

	func test_show_preview_adds_preview_to_layer() -> void:
		var preview: Control = Control.new()
		_manager.show_preview(preview)
		assert_eq(_manager._layer.get_child_count(), 1)

	func test_show_preview_stores_reference_for_position_updates() -> void:
		var preview: Control = Control.new()
		_manager.show_preview(preview)
		assert_eq(_manager._preview, preview)

	func test_hide_preview_clears_current_preview() -> void:
		var preview: Control = Control.new()
		_manager.show_preview(preview)
		_manager.hide_preview()
		assert_null(_manager._preview)

	func test_hide_preview_is_safe_when_no_preview_showing() -> void:
		_manager.hide_preview()
		assert_null(_manager._preview)

	func test_show_preview_replaces_existing_preview() -> void:
		var first: Control = Control.new()
		var second: Control = Control.new()
		_manager.show_preview(first)
		_manager.show_preview(second)
		assert_eq(_manager._preview, second)


class TestCursorTracking:
	extends GutTest

	var _manager: Node

	func before_each() -> void:
		_manager = DragManagerScript.new()
		add_child_autofree(_manager)

	func test_mouse_motion_updates_preview_position() -> void:
		var preview: Control = Control.new()
		_manager.show_preview(preview)
		var event := InputEventMouseMotion.new()
		event.position = Vector2(123, 456)
		_manager._input(event)
		assert_eq(preview.global_position, Vector2(123, 456))

	func test_non_motion_events_do_not_update_position() -> void:
		var preview: Control = Control.new()
		_manager.show_preview(preview)
		var start_position: Vector2 = preview.global_position
		_manager._input(InputEventKey.new())
		assert_eq(preview.global_position, start_position)

	func test_motion_event_without_preview_is_safe() -> void:
		_manager._input(InputEventMouseMotion.new())
		assert_null(_manager._preview)
