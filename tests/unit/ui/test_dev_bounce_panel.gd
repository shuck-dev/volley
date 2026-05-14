## SH-316 smoke test: dev bounce panel and overlay survive instantiation and a simulated bounce.
extends GutTest

const DevBouncePanelScript: GDScript = preload("res://scripts/hud/dev_bounce_panel.gd")
const DevBounceOverlayScript: GDScript = preload("res://scripts/hud/dev_bounce_overlay.gd")


func test_panel_instantiates_without_tracker() -> void:
	# Without a BallTracker in the scene tree the panel should still build labels and not crash.
	var panel: DevBouncePanel = DevBouncePanelScript.new()
	add_child_autofree(panel)
	await get_tree().process_frame
	assert_not_null(panel, "panel should construct")
	assert_true(panel.get_child_count() > 0, "panel should add header and labels")


func test_overlay_instantiates_without_tracker() -> void:
	var overlay: DevBounceOverlay = DevBounceOverlayScript.new()
	add_child_autofree(overlay)
	await get_tree().process_frame
	assert_not_null(overlay, "overlay should construct")
	assert_true(overlay.is_in_group(&"dev_overlays"), "overlay joins dev_overlays group")


func test_panel_receives_bounce_signal() -> void:
	# Forward a bounce_resolved payload manually and confirm the panel formats it without erroring.
	var panel: DevBouncePanel = DevBouncePanelScript.new()
	add_child_autofree(panel)
	await get_tree().process_frame
	panel._on_bounce_resolved(null, 0.5, deg_to_rad(20.0), 1.0, -1.0)
	assert_true(panel._has_last_hit, "last hit flag set after signal")
	assert_almost_eq(panel._last_offset_norm, 0.5, 0.001)
	assert_almost_eq(panel._last_target_angle_deg, 20.0, 0.1)
