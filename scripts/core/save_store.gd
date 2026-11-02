class_name SaveStore
extends RefCounted
## Локальное сохранение в JSON (в вебе user:// хранится в IndexedDB).
## Облачный бэкенд для синхронизации между устройствами реализует
## тот же load_data()/save_data().

const VERSION := 6

var path: String


func _init(p_path := "user://save.json") -> void:
	path = p_path


func load_data() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data
	push_warning("Сохранение повреждено, начинаем заново: %s" % path)
	return {}


func save_data(data: Dictionary) -> void:
	data["version"] = VERSION
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Не удалось сохранить %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))
