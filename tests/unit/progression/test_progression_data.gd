extends GutTest

# Round-trip tests for the five progression slices: EconomyState, ItemWorldState,
# RecordsState, UnlocksState, PartnersState. Each slice owns its own to_save_dict /
# apply_save_dict; SaveManager just coordinates.


# --- EconomyState ---
func test_economy_default_values() -> void:
	var economy := EconomyState.new()
	assert_eq(economy.friendship_point_balance, 0)
	assert_eq(economy.total_friendship_points_earned, 0)


func test_economy_round_trip() -> void:
	var economy := EconomyState.new()
	economy.friendship_point_balance = 500
	economy.total_friendship_points_earned = 1234
	var restored := EconomyState.new()
	restored.apply_save_dict(economy.to_save_dict())
	assert_eq(restored.friendship_point_balance, 500)
	assert_eq(restored.total_friendship_points_earned, 1234)


func test_economy_missing_keys_use_defaults() -> void:
	var restored := EconomyState.new()
	restored.apply_save_dict({})
	assert_eq(restored.friendship_point_balance, 0)
	assert_eq(restored.total_friendship_points_earned, 0)


func test_economy_clear() -> void:
	var economy := EconomyState.new()
	economy.friendship_point_balance = 500
	economy.total_friendship_points_earned = 999
	economy.clear()
	assert_eq(economy.friendship_point_balance, 0)
	assert_eq(economy.total_friendship_points_earned, 0)


# --- ItemWorldState ---
func test_items_default_values() -> void:
	var items := ItemWorldState.new()
	assert_eq(items.item_levels, {} as Dictionary[String, int])
	assert_eq(items.item_placements, {} as Dictionary[String, int])


func test_items_round_trip() -> void:
	var items := ItemWorldState.new()
	items.item_levels["paddle_size"] = 2
	items.item_placements["paddle_size"] = 1
	var restored := ItemWorldState.new()
	restored.apply_save_dict(items.to_save_dict())
	assert_eq(restored.item_levels, {"paddle_size": 2})
	assert_eq(restored.item_placements, {"paddle_size": 1})


# --- RecordsState ---
func test_records_round_trip() -> void:
	var records := RecordsState.new()
	records.personal_volley_best = 42
	var restored := RecordsState.new()
	restored.apply_save_dict(records.to_save_dict())
	assert_eq(restored.personal_volley_best, 42)


# --- UnlocksState ---
func test_unlocks_round_trip() -> void:
	var unlocks := UnlocksState.new()
	unlocks.shop_unlocked = true
	var restored := UnlocksState.new()
	restored.apply_save_dict(unlocks.to_save_dict())
	assert_true(restored.shop_unlocked)


# --- PartnersState ---
func test_partners_default_empty() -> void:
	var partners := PartnersState.new()
	assert_eq(partners.unlocked_partners, [] as Array[StringName])
	assert_eq(partners.active_partner, &"")
	assert_eq(partners.partner_volley_totals, {} as Dictionary[StringName, int])


func test_partners_round_trip() -> void:
	var partners := PartnersState.new()
	partners.unlocked_partners = [&"martha"] as Array[StringName]
	partners.active_partner = &"martha"
	partners.partner_volley_totals = {&"martha": 150} as Dictionary[StringName, int]
	partners.recruit_offered_partners = [&"martha"] as Array[StringName]

	var restored := PartnersState.new()
	restored.apply_save_dict(partners.to_save_dict())
	assert_eq(restored.unlocked_partners, [&"martha"] as Array[StringName])
	assert_eq(restored.active_partner, &"martha")
	assert_eq(restored.partner_volley_totals, {&"martha": 150} as Dictionary[StringName, int])
	assert_eq(restored.recruit_offered_partners, [&"martha"] as Array[StringName])


func test_partners_missing_keys_use_defaults() -> void:
	var restored := PartnersState.new()
	restored.apply_save_dict({})
	assert_eq(restored.unlocked_partners, [] as Array[StringName])
	assert_eq(restored.active_partner, &"")
	assert_eq(restored.partner_volley_totals, {} as Dictionary[StringName, int])


func test_partners_clear() -> void:
	var partners := PartnersState.new()
	partners.unlocked_partners = [&"martha"] as Array[StringName]
	partners.active_partner = &"martha"
	partners.partner_volley_totals = {&"martha": 150} as Dictionary[StringName, int]
	partners.clear()
	assert_eq(partners.unlocked_partners, [] as Array[StringName])
	assert_eq(partners.active_partner, &"")
	assert_eq(partners.partner_volley_totals, {} as Dictionary[StringName, int])


func test_partners_cleared_dict_round_trip_keeps_fields_empty() -> void:
	var partners := PartnersState.new()
	partners.unlocked_partners = [&"martha"] as Array[StringName]
	partners.clear()

	var cleared_json := JSON.stringify(partners.to_save_dict())
	var parsed: Variant = JSON.parse_string(cleared_json)
	var loaded := PartnersState.new()
	loaded.apply_save_dict(parsed)
	assert_eq(loaded.unlocked_partners, [] as Array[StringName])
	assert_eq(loaded.active_partner, &"")
