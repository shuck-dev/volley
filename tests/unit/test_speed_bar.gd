extends GutTest

# Verifies speed bar fill and marker calculations.
# Bar shows progress from min_speed (empty) to max_speed (full).

var _bar: Control


func before_each() -> void:
	_bar = load("res://scripts/hud/speed_bar.gd").new()
	_bar.size = Vector2(200, 10)
	add_child_autofree(_bar)


# --- fill ratio (min = left edge, max = right edge) ---
func test_fill_empty_at_min_speed() -> void:
	_bar.update_speed(400.0, 400.0, 700.0, 700.0)
	assert_almost_eq(_fill_ratio(), 0.0, 0.01)


func test_fill_full_at_max_speed() -> void:
	_bar.update_speed(700.0, 400.0, 700.0, 700.0)
	assert_almost_eq(_fill_ratio(), 1.0, 0.01)


func test_fill_half_at_midpoint() -> void:
	_bar.update_speed(550.0, 400.0, 700.0, 700.0)
	assert_almost_eq(_fill_ratio(), 0.5, 0.01)


# --- permanent max marker ---
func test_no_marker_without_ceiling_raise() -> void:
	_bar.update_speed(400.0, 400.0, 700.0, 700.0)
	assert_false(_bar._max_speed > _bar._permanent_max_speed)


func test_marker_appears_during_ceiling_raise() -> void:
	_bar.update_speed(700.0, 400.0, 750.0, 700.0)
	assert_true(_bar._max_speed > _bar._permanent_max_speed)


func test_marker_disappears_after_miss() -> void:
	_bar.update_speed(700.0, 400.0, 750.0, 700.0)
	_bar.update_speed(400.0, 400.0, 700.0, 700.0)
	assert_false(_bar._max_speed > _bar._permanent_max_speed)


# --- upgrades do not affect marker ---
func test_permanent_max_tracks_upgrades() -> void:
	_bar.update_speed(430.0, 430.0, 730.0, 730.0)
	assert_almost_eq(_bar._permanent_max_speed, 730.0, 0.01)
	assert_almost_eq(_permanent_ratio(), 1.0, 0.01, "Marker should stay at right edge")


func test_upgrades_do_not_show_marker() -> void:
	_bar.update_speed(460.0, 460.0, 760.0, 760.0)
	assert_false(_bar._max_speed > _bar._permanent_max_speed)


# --- overflow fill ---
func test_overflow_fill_when_speed_past_permanent_max() -> void:
	_bar.update_speed(725.0, 400.0, 750.0, 700.0)
	assert_true(_bar._current_speed > _bar._permanent_max_speed)


func test_no_overflow_fill_when_speed_below_permanent_max() -> void:
	_bar.update_speed(650.0, 400.0, 750.0, 700.0)
	assert_false(_bar._current_speed > _bar._permanent_max_speed)


# --- helpers ---
func _fill_ratio() -> float:
	var speed_range: float = _bar._max_speed - _bar._min_speed
	if speed_range <= 0.0:
		return 0.0
	return clampf((_bar._current_speed - _bar._min_speed) / speed_range, 0.0, 1.0)


func _permanent_ratio() -> float:
	var speed_range: float = _bar._max_speed - _bar._min_speed
	if speed_range <= 0.0:
		return 0.0
	return clampf((_bar._permanent_max_speed - _bar._min_speed) / speed_range, 0.0, 1.0)
