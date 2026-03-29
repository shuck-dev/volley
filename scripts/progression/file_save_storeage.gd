class_name FileSaveStorage
extends SaveStorage

var _path: String


func _init(path: String = "user://save_data.json") -> void:
	_path = path


func write(content: String) -> bool:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	return true


func read() -> String:
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
