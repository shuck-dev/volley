## SH-316 DevHUD checkbox: "Cone follows last hit" flips DevBounceOverlay.follow_last_hit.
extends GutTest

const DevHudScene: PackedScene = preload("res://scenes/dev_hud.tscn")
const DevBounceOverlayScript: GDScript = preload("res://scripts/hud/dev_bounce_overlay.gd")

var _dev_hud: DevHud
var _overlay: DevBounceOverlay


func before_each() -> void:
	_overlay = DevBounceOverlayScript.new()
	# Bypass _ready's debug-build guard by adding to the group manually after the fact.
	add_child_autofree(_overlay)
	_overlay.add_to_group(&"dev_overlays")
	_dev_hud = DevHudScene.instantiate()
	add_child_autofree(_dev_hud)


func test_default_follow_flag_is_off() -> void:
	assert_false(_overlay.follow_last_hit, "follow_last_hit defaults to absolute mode")


func test_toggle_on_sets_follow_flag() -> void:
	_dev_hud._on_cone_follow_toggled(true)
	assert_true(_overlay.follow_last_hit, "checkbox-on flips overlay flag")


func test_toggle_off_clears_follow_flag() -> void:
	_dev_hud._on_cone_follow_toggled(true)
	_dev_hud._on_cone_follow_toggled(false)
	assert_false(_overlay.follow_last_hit, "checkbox-off restores absolute mode")
