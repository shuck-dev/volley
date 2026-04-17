class_name FileSaveStorage
extends SaveStorage

const TEMP_SUFFIX := ".tmp"
const MAX_BACKUPS := 3

var _path: String


func _init(path: String = "user://save_data.json") -> void:
	_path = path


## Atomic write with rolling backups. The temp file is fully written and flushed
## before the primary is touched, so a failed write leaves the previous save in place.
func write(content: String) -> bool:
	var temp_path: String = _path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK and write_error != ERR_FILE_EOF:
		DirAccess.remove_absolute(temp_path)
		return false

	_rotate_backups()
	if FileAccess.file_exists(_path):
		var backup_error: int = DirAccess.rename_absolute(_path, _backup_path(1))
		if backup_error != OK:
			DirAccess.remove_absolute(temp_path)
			return false
	var rename_error: int = DirAccess.rename_absolute(temp_path, _path)
	if rename_error != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	return true


func read() -> String:
	return _read_path(_path)


## Newest-first backup contents; empty entries omitted.
func read_fallbacks() -> Array[String]:
	var contents: Array[String] = []
	for backup_index in range(1, MAX_BACKUPS + 1):
		var backup_content: String = _read_path(_backup_path(backup_index))
		if backup_content != "":
			contents.append(backup_content)
	return contents


func _read_path(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


## Shifts backups one step older and drops the oldest so slot 1 is free.
func _rotate_backups() -> void:
	var oldest: String = _backup_path(MAX_BACKUPS)
	if FileAccess.file_exists(oldest):
		DirAccess.remove_absolute(oldest)
	for backup_index in range(MAX_BACKUPS - 1, 0, -1):
		var current_path: String = _backup_path(backup_index)
		if FileAccess.file_exists(current_path):
			DirAccess.rename_absolute(current_path, _backup_path(backup_index + 1))


## Inserts ".<index>" before the extension: save_data.json -> save_data.1.json.
func _backup_path(backup_index: int) -> String:
	var base: String = _path.get_basename()
	var extension: String = _path.get_extension()
	if extension == "":
		return "%s.%d" % [base, backup_index]
	return "%s.%d.%s" % [base, backup_index, extension]
