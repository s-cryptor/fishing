extends SceneTree
## Экспорт — только чтение. Будущий оригинал сохраняется дословно, даже из резерва.

var _failures := 0
var _fixtures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var old_store: SaveStore = state._store
	state._store = _fixture("current")
	state.money = 123
	state.collection = {"roach": {"count": 3, "best_kg": 0.42}}
	state.inventory.assign([{"fish_id": "roach", "weight_kg": 0.42}])
	state.fishing_target_id = "golden_carp"
	state.fishing_target_trophy = false
	state.found_messages.assign(["lake_letter"])
	state.progress_read_only = false
	state._save()
	var disk_before := FileAccess.get_file_as_string(state._store.path)
	var backup_before := FileAccess.file_exists(state._store.path + ".bak")
	var copy: String = state.export_save_text()
	var parsed: Dictionary = JSON.parse_string(copy)
	_check(parsed.get("version") == SaveStore.VERSION and parsed.get("money") == 123, "JSON содержит текущую версию и деньги")
	_check(parsed["inventory"].size() == 1 and parsed["collection"]["roach"]["count"] == 3
		and parsed["fishing_target"]["fish_id"] == "golden_carp" and parsed["found_messages"] == ["lake_letter"],
		"в экспорт попадают улов, коллекция, личная цель и письма")
	_check(FileAccess.get_file_as_string(state._store.path) == disk_before
		and FileAccess.file_exists(state._store.path + ".bak") == backup_before, "экспорт не пишет основной файл и резерв")
	state.money = 987
	_check(JSON.parse_string(state.export_save_text())["money"] == 987
		and FileAccess.get_file_as_string(state._store.path) == disk_before, "копия включает несохранённое состояние памяти без записи на диск")
	var claimed_before := JSON.stringify(state.claimed_goals)
	state.export_save_text()
	_check(state.money == 987 and JSON.stringify(state.claimed_goals) == claimed_before, "экспорт не выдаёт выплаты и не меняет прогресс")
	var restored := _fixture("roundtrip")
	_check(restored.save_data(parsed), "экспортируемый JSON принимается обычным хранилищем")
	state._store = restored
	state._load()
	_check(state.money == 123 and state.collection.has("roach") and state.fishing_target_id == "golden_carp",
		"копия совместима с существующей загрузкой прогресса")
	# Большое число намеренно не прогоняем через stringify: проверяем сохранность байтов.
	var future_text := "{\n\t\"version\": %d, \"future\": 9007199254740993, \"inventory\": \"новая схема\"\n}" % (SaveStore.VERSION + 1)
	for suffix in ["", ".tmp", ".bak"]:
		var store := _fixture("future")
		if suffix != "":
			store.save_data({"money": 12})
		_write(store.path + suffix, future_text)
		state._store = store
		state._load()
		store.last_error = "Не стирать сообщение"
		store.recovered_from = "Не стирать источник"
		_check(state.export_save_text() == future_text, "будущая схема экспортируется без потери полей и точности: %s" % suffix)
		_check(FileAccess.get_file_as_string(store.path + suffix) == future_text
			and store.last_error == "Не стирать сообщение" and store.recovered_from == "Не стирать источник",
			"чтение будущей копии не меняет файл и диагностическое состояние: %s" % suffix)
	state._store = _fixture("missing")
	state.progress_read_only = true
	_check(state.export_save_text().is_empty(), "исчезнувший защищённый оригинал не заменяется стартовым прогрессом")
	state.progress_read_only = false
	state.money = 456
	_check(JSON.parse_string(state.export_save_text())["money"] == 456, "новая игра без файла тоже может экспортировать состояние")
	_check(SaveStore.new("").future_save_text().is_empty(), "пустой путь не ищет резерв в рабочем каталоге")
	state._store = old_store
	state._load()
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var pause: Node = get_first_node_in_group(&"pause_menu")
	pause.toggle()
	await process_frame
	await process_frame
	var button: Button = pause._backup_button
	_check(button.visible and button.process_mode == Node.PROCESS_MODE_INHERIT and button.focus_mode == Control.FOCUS_ALL,
		"экспорт доступен с клавиатуры и работает в дереве паузы")
	var panel: Control = button.get_parent().get_parent()
	_check(panel.get_global_rect().position.y >= 0 and panel.get_global_rect().end.y <= panel.get_viewport_rect().end.y,
		"пауза с экспортом помещается в высоту экрана")
	var before := FileAccess.get_file_as_string(state._store.path)
	button.pressed.emit()
	_check(button.text == "Буфер обмена недоступен" and FileAccess.get_file_as_string(state._store.path) == before,
		"headless не обращается к буферу пользователя, экспорт не пишет сейв")
	pause.toggle()
	pause.toggle()
	_check(button.text == pause._export_caption(), "повторное открытие восстанавливает подпись экспорта")
	pause.toggle()
	scene.queue_free()
	await process_frame
	for path in _fixtures:
		for suffix in ["", ".tmp", ".bak"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	quit(1 if _failures else 0)


func _fixture(label: String) -> SaveStore:
	var path := "user://export-check-%d-%s.json" % [Time.get_ticks_usec(), label]
	_fixtures.append(path)
	return SaveStore.new(path)


func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
