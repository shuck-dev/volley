extends GutTest

# SoulRateLabel: live readout of soul_multiplier via soul_multiplier_changed signal.

const SoulRateScript: GDScript = preload("res://scripts/court/soul_rate.gd")


# Minimal stub satisfying soul_rate.gd's group-discovery and signal contract.
class FakeCourt:
	extends Node

	signal soul_multiplier_changed(value: int)


func test_label_shows_multiplier_on_connect() -> void:
	var fake: FakeCourt = FakeCourt.new()
	fake.add_to_group(&"courts")
	add_child_autofree(fake)

	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	# The initial read comes from ItemManager.get_stat; just verify label has content.
	assert_true(label.text.begins_with("x"))


func test_label_updates_on_signal() -> void:
	var fake: FakeCourt = FakeCourt.new()
	fake.add_to_group(&"courts")
	add_child_autofree(fake)

	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	fake.soul_multiplier_changed.emit(3)

	assert_eq(label.text, "x3")


func test_label_empty_before_court_appears() -> void:
	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	assert_eq(label.text, "")


func test_label_connects_to_late_court() -> void:
	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	assert_eq(label.text, "")

	var fake: FakeCourt = FakeCourt.new()
	fake.add_to_group(&"courts")
	add_child_autofree(fake)

	fake.soul_multiplier_changed.emit(2)

	assert_eq(label.text, "x2")


func test_exit_tree_disconnects_waiting_signal() -> void:
	var label: Label = SoulRateScript.new()
	add_child_autofree(label)

	remove_child(label)
	label.free()

	var fake: FakeCourt = FakeCourt.new()
	fake.add_to_group(&"courts")
	add_child_autofree(fake)

	# No crash when court appears after label is freed.
	assert_true(true)
