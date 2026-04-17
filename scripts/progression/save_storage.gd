class_name SaveStorage
extends RefCounted


func write(_content: String) -> bool:
	return false


func read() -> String:
	return ""


## Returns backup contents, newest first. Empty strings mean no data at that
## slot. Default is no backups; FileSaveStorage overrides for rolling backups.
func read_fallbacks() -> Array[String]:
	return []
