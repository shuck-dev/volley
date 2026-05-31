extends GutTest

# SoulRateLabel: standing readout that shows soul_per_tier_base from TierRewardHandler.

const SoulRateScript: GDScript = preload("res://scripts/court/soul_rate.gd")
const TierRewardHandlerScript: GDScript = preload("res://scripts/court/tier_reward_handler.gd")


func _make_label_with_handler(base: int) -> Label:
	var handler: Node = TierRewardHandlerScript.new()
	handler.soul_per_tier_base = base
	add_child_autofree(handler)

	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	return label


func test_label_shows_default_rate() -> void:
	var label: Label = _make_label_with_handler(2)

	assert_eq(label.text, "x2 soul/tier")


func test_label_shows_custom_rate_five() -> void:
	var label: Label = _make_label_with_handler(5)

	assert_eq(label.text, "x5 soul/tier")


func test_label_shows_rate_one() -> void:
	var label: Label = _make_label_with_handler(1)

	assert_eq(label.text, "x1 soul/tier")


func test_label_waits_for_late_handler() -> void:
	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	assert_eq(label.text, "")

	var handler: Node = TierRewardHandlerScript.new()
	handler.soul_per_tier_base = 3
	add_child_autofree(handler)

	assert_eq(label.text, "x3 soul/tier")


func test_exit_tree_disconnects_waiting_signal() -> void:
	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	remove_child(label)

	var handler: Node = TierRewardHandlerScript.new()
	handler.soul_per_tier_base = 4
	add_child_autofree(handler)

	assert_eq(label.text, "")

	label.free()
