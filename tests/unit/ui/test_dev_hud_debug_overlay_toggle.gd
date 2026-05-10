## SH-376 DevHUD checkbox: one toggle gates GrabArea overlay and CursorOverlay drag ring.
extends GutTest

const DevHudScene: PackedScene = preload("res://scenes/dev_hud.tscn")
const CursorOverlayScript: GDScript = preload("res://scripts/hud/cursor_overlay.gd")

var _dev_hud: DevHud
var _grab_area: GrabArea
var _overlay: CursorOverlay


func before_each() -> void:
	GrabArea.debug_visible = false
	_grab_area = GrabArea.new()
	var col: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	col.shape = circle
	_grab_area.add_child(col)
	add_child_autofree(_grab_area)
	_overlay = CursorOverlayScript.new()
	add_child_autofree(_overlay)
	_dev_hud = DevHudScene.instantiate()
	add_child_autofree(_dev_hud)


func after_each() -> void:
	GrabArea.debug_visible = false


func test_default_state_is_off() -> void:
	assert_false(_dev_hud.debug_overlay_toggle.button_pressed, "checkbox defaults to off")
	assert_false(GrabArea.debug_visible, "GrabArea static stays off at startup")
	assert_false(_overlay.dev_visible, "CursorOverlay dev_visible follows checkbox at startup")


func test_toggle_on_propagates_to_grab_area_and_overlay() -> void:
	_dev_hud.debug_overlay_toggle.button_pressed = true
	_dev_hud._on_debug_overlay_toggled(true)
	assert_true(GrabArea.debug_visible, "GrabArea overlay enabled by checkbox")
	assert_true(_overlay.dev_visible, "CursorOverlay dev_visible enabled by checkbox")


func test_toggle_off_propagates_to_grab_area_and_overlay() -> void:
	_dev_hud._on_debug_overlay_toggled(true)
	_dev_hud._on_debug_overlay_toggled(false)
	assert_false(GrabArea.debug_visible)
	assert_false(_overlay.dev_visible)
