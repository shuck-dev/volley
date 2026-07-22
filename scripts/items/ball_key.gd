class_name BallKey
extends RefCounted


static func is_instance(base_key: String, key: String) -> bool:
	if not key.begins_with(base_key + "_"):
		return false
	var suffix := key.substr(base_key.length() + 1)
	return suffix.is_valid_int()


static func next_instance(base_key: String, existing_keys: Dictionary) -> String:
	var n := 1
	while existing_keys.has("%s_%d" % [base_key, n]):
		n += 1
	return "%s_%d" % [base_key, n]


static func base_key(instance_key: String) -> String:
	var last_underscore := instance_key.rfind("_")
	if last_underscore == -1:
		return instance_key
	var suffix := instance_key.substr(last_underscore + 1)
	if suffix.is_valid_int():
		return instance_key.substr(0, last_underscore)
	return instance_key
