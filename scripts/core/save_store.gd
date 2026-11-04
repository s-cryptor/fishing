class_name SaveStore
extends RefCounted
## Локальное сохранение в JSON (в вебе user:// хранится в IndexedDB).
## Облачный бэкенд для синхронизации между устройствами реализует
## тот же load_data()/save_data().

const VERSION := 10

var path: String
var last_error := ""
var recovered_from := ""
var damaged_archive := ""


func _init(p_path := "user://save.json") -> void:
	path = p_path


func load_data() -> Dictionary:
	last_error = ""
	recovered_from = ""
	if path.is_empty():
		last_error = "Не задан путь сохранения"
		return {}
	var found := false
	# tmp восстанавливает сбой между перемещением основного файла и публикацией нового.
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		found = true
		var data: Variant = _read_dictionary(candidate)
		if data is Dictionary:
			if candidate != path:
				recovered_from = candidate
			if _version(data) > VERSION:
				last_error = "Для записи этого сохранения нужна более новая версия игры"
			return data
	if found:
		last_error = "Не удалось прочитать основной файл и резервные сохранения"
	return {}


func save_data(data: Dictionary) -> bool:
	last_error = ""
	damaged_archive = ""
	if path.is_empty():
		return _fail("Не задан путь сохранения")
	# Старое окно игры не должно затирать прогресс с более новой схемой.
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var existing: Variant = _read_dictionary(candidate)
			if existing is Dictionary and _version(existing) > VERSION:
				return _fail("Для записи этого сохранения нужна более новая версия игры")
	var snapshot := data.duplicate(true)
	snapshot["version"] = VERSION
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Не удалось открыть временное сохранение: %s" % error_string(FileAccess.get_open_error()))
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return _fail("Не удалось записать временное сохранение: %s" % error_string(write_error))
	# До этого момента основной файл вообще не трогали.
	if FileAccess.file_exists(path):
		var destination := path + ".bak"
		if not _read_dictionary(path) is Dictionary:
			# Повреждённый оригинал сохраняем для диагностики, не затирая хорошую копию.
			destination = _unused_archive_path()
		var backup_error := _rename(path, destination)
		if backup_error != OK:
			return _fail("Не удалось сохранить предыдущую копию: %s" % error_string(backup_error))
		if destination != path + ".bak":
			damaged_archive = destination
	var publish_error := _rename(temporary, path)
	if publish_error != OK:
		# Даже при этом сбое доступны новая tmp и предыдущая bak.
		return _fail("Не удалось завершить сохранение: %s" % error_string(publish_error))
	# Переименования также должны попасть в IndexedDB. Веб-синхронизация асинхронна.
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge := Engine.get_singleton("JavaScriptBridge")
		if bridge.has_method("force_fs_sync"):
			bridge.call("force_fs_sync")
	return true


func _read_dictionary(file_path: String) -> Variant:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return null
	return parser.data


func _unused_archive_path() -> String:
	var result := path + ".corrupt"
	var index := 0
	while FileAccess.file_exists(result) or DirAccess.dir_exists_absolute(_absolute(result)):
		index += 1
		result = path + ".corrupt.%d" % index
	return result


func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(_absolute(from), _absolute(to))


func _absolute(file_path: String) -> String:
	var absolute := ProjectSettings.globalize_path(file_path)
	if not absolute.is_absolute_path():
		absolute = ProjectSettings.globalize_path("res://").path_join(absolute)
	return absolute.simplify_path()


func _fail(message: String) -> bool:
	last_error = message
	return false


func _version(data: Dictionary) -> int:
	var value: Variant = data.get("version", 0)
	return int(value) if value is int or value is float else 0
