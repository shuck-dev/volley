## SH-376 cursor overlay dev-visible gate: hides the drag ring even when state is non-default.
extends GutTest

const CursorStateScript: GDScript = preload("res://scripts/items/cursor_state.gd")
const CursorOverlayScript: GDScript = preload("res://scripts/hud/cursor_overlay.gd")

var _overlay: CursorOverlay


func before_each() -> void:
	_overlay = CursorOverlayScript.new()
	add_child_autofree(_overlay)


func test_set_dev_visible_false_hides_overlay_during_drag() -> void:
	_overlay.set_state(CursorStateScript.State.DRAGGING, Vector2.ZERO)
	assert_true(_overlay.visible, "drag state shows overlay when dev_visible defaults true")
	_overlay.set_dev_visible(false)
	assert_false(_overlay.visible, "dev_visible=false hides even mid-drag")


func test_set_dev_visible_true_then_drag_state_shows_overlay() -> void:
	_overlay.set_dev_visible(false)
	_overlay.set_state(CursorStateScript.State.DRAGGING, Vector2.ZERO)
	assert_false(_overlay.visible, "dev_visible=false keeps overlay hidden in DRAGGING")
	_overlay.set_dev_visible(true)
	assert_true(_overlay.visible, "re-enabling dev_visible restores DRAGGING visibility")


func test_set_dev_visible_true_keeps_default_state_hidden() -> void:
	_overlay.set_dev_visible(true)
	assert_false(_overlay.visible, "DEFAULT state stays hidden regardless of dev_visible")


func test_ready_joins_dev_overlays_group() -> void:
	assert_true(_overlay.is_in_group(&"dev_overlays"))
