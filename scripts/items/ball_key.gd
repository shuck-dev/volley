class_name BallKey
extends RefCounted


static func is_instance(item_type: String, key: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^%s_\\d+$" % item_type)
	return regex.search(key) != null


static func next_instance(item_type: String, existing_keys: Dictionary) -> String:
	var n := 1
	while existing_keys.has("%s_%d" % [item_type, n]):
		n += 1
	return "%s_%d" % [item_type, n]


static func base_key(instance_key: String) -> String:
	var regex := RegEx.new()
	regex.compile("_\\d+$")
	var result := regex.search(instance_key)
	if result:
		return instance_key.substr(0, result.get_start())
	return instance_key
