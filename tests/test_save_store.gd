extends SceneTree
## Сбои записи проверяются на отдельной временной директории, не на прогрессе игрока.

var _failures := 0
var _directory := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var temporary := DirAccess.create_temp("fishing-save-tests", true)
	_directory = temporary.get_current_dir()
	var store := SaveStore.new(_directory.path_join("normal.json"))
	var payload := {"money": 10, "collection": {"roach": {"count": 2, "best_kg": 0.3}}, "note": "Тихая гавань"}
	_check(store.load_data().is_empty() and store.last_error.is_empty(), "новая игра не считается повреждённым сохранением")
	_check(store.save_data(payload) and not payload.has("version"), "запись не изменяет переданный снимок прогресса")
	_check(store.load_data()["note"] == "Тихая гавань" and int(store.load_data()["version"]) == SaveStore.VERSION,
		"UTF-8 и версия корректно сохраняются")
	store.save_data({"money": 20})
	_check(_read_json(store.path)["money"] == 20 and _read_json(store.path + ".bak")["money"] == 10,
		"предыдущий подтверждённый снимок становится резервным")
	store.save_data({"money": 30})
	_check(_read_json(store.path + ".bak")["money"] == 20 and not FileAccess.file_exists(store.path + ".tmp"),
		"повторная запись обновляет резерв и не оставляет временный файл")
	_write(store.path, "{broken primary")
	_check(store.load_data()["money"] == 20 and store.recovered_from == store.path + ".bak",
		"повреждённый основной файл восстанавливается из предыдущего снимка")
	_check(store.save_data({"money": 21}) and _read_json(store.path + ".bak")["money"] == 20,
		"запись после восстановления не затирает хорошую резервную копию")
	_check(FileAccess.get_file_as_string(store.damaged_archive) == "{broken primary", "повреждённый оригинал сохранён для восстановления вручную")
	var interrupted := SaveStore.new(_directory.path_join("interrupted.json"))
	interrupted.save_data({"money": 40})
	_write(interrupted.path + ".tmp", JSON.stringify({"version": 6, "money": 41}))
	DirAccess.rename_absolute(interrupted.path, interrupted.path + ".bak")
	_check(interrupted.load_data()["money"] == 41 and interrupted.recovered_from == interrupted.path + ".tmp",
		"сбой между двумя переименованиями восстанавливает готовый временный снимок")
	_check(interrupted.save_data({"money": 42}) and interrupted.load_data()["money"] == 42, "после прерванной публикации можно снова сохраняться")
	var stale := SaveStore.new(_directory.path_join("stale.json"))
	stale.save_data({"money": 50})
	_write(stale.path + ".tmp", JSON.stringify({"money": 51}))
	_check(stale.load_data()["money"] == 50 and stale.recovered_from.is_empty(), "готовый основной файл приоритетнее незавершённой записи")
	DirAccess.rename_absolute(stale.path, stale.path + ".bak")
	_write(stale.path + ".tmp", "{partial")
	_check(stale.load_data()["money"] == 50 and stale.recovered_from == stale.path + ".bak", "обрезанный временный файл не мешает резервному восстановлению")
	var blocked := SaveStore.new(_directory.path_join("blocked.json"))
	blocked.save_data({"money": 60})
	DirAccess.make_dir_absolute(blocked.path + ".bak")
	_check(not blocked.save_data({"money": 61}) and not blocked.last_error.is_empty(), "ошибка резервирования возвращается вызывающему коду")
	_check(_read_json(blocked.path)["money"] == 60 and _read_json(blocked.path + ".tmp")["money"] == 61,
		"при ошибке резервирования старый основной и новый временный снимки целы")
	var missing := SaveStore.new(_directory.path_join("missing/save.json"))
	_check(not missing.save_data({"money": 70}) and not missing.last_error.is_empty(), "ошибка открытия временного файла не считается успехом")
	var damaged := SaveStore.new(_directory.path_join("damaged.json"))
	_write(damaged.path, "first damage")
	_write(damaged.path + ".bak", "[]")
	_check(damaged.load_data().is_empty() and not damaged.last_error.is_empty(), "полное повреждение явно отмечено ошибкой")
	damaged.save_data({"money": 80})
	_write(damaged.path, "second damage")
	damaged.save_data({"money": 81})
	_check(FileAccess.get_file_as_string(damaged.path + ".corrupt") == "first damage"
		and FileAccess.get_file_as_string(damaged.path + ".corrupt.1") == "second damage", "повторные повреждения не затирают архивы друг друга")
	var legacy := SaveStore.new(_directory.path_join("legacy.json"))
	_write(legacy.path, JSON.stringify({"version": 5, "money": 90}))
	_check(legacy.load_data()["version"] == 5, "старый JSON читается без перезаписи при загрузке")
	legacy.save_data(legacy.load_data())
	_check(int(legacy.load_data()["version"]) == SaveStore.VERSION and _read_json(legacy.path + ".bak")["version"] == 5,
		"обновление сохраняет старую версию в резерве")
	var future := SaveStore.new(_directory.path_join("future.json"))
	var future_text := JSON.stringify({"version": SaveStore.VERSION + 1, "money": 999, "future_progress": ["valuable"]})
	_write(future.path, future_text)
	_check(not future.save_data({"money": 1}) and FileAccess.get_file_as_string(future.path) == future_text,
		"старая версия игры не затирает файл с более новой схемой")
	_check(not future.last_error.is_empty() and not FileAccess.file_exists(future.path + ".tmp"), "защита новой схемы срабатывает до начала записи")
	_check(future.load_data()["money"] == 999 and not future.last_error.is_empty(), "новая схема читается с предупреждением о запрете записи")
	var empty := SaveStore.new("")
	_check(not empty.save_data({"money": 1}) and empty.load_data().is_empty(), "пустой путь не создаёт случайный файл в проекте")
	var state := root.get_node("GameState")
	var original: SaveStore = state._store
	var failures: Array[String] = []
	var observer := func(message: String) -> void: failures.append(message)
	state.save_failed.connect(observer)
	state._store = blocked
	state._save()
	_check(failures.size() == 1 and not failures[0].is_empty(), "GameState сообщает интерфейсу о неудавшемся сохранении")
	state.save_failed.disconnect(observer)
	_write(store.path, "{damage again")
	state._store = store
	state._load()
	_check(not state.save_recovery_notice.is_empty() and state.money == 20, "восстановление формирует понятное уведомление игроку")
	state._store = original
	state._load()
	DirAccess.remove_absolute(blocked.path + ".bak")
	for filename in temporary.get_files():
		DirAccess.remove_absolute(_directory.path_join(filename))
	temporary = null
	DirAccess.remove_absolute(_directory)
	quit(1 if _failures else 0)


func _write(file_path: String, content: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(content)
	file.close()


func _read_json(file_path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(file_path))


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
