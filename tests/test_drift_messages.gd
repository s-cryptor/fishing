extends SceneTree
## Письма собираются с лодки, сохраняются разово и открывают только косметику.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.found_messages.clear()
	state.discovered_landmarks.clear()
	state.claimed_goals.clear()
	for goal in state.JOURNEY.goals:
		if goal["id"] not in ["first_letter", "letters_home"]:
			state.claimed_goals.append(goal["id"])
	state.money = 0
	state.owned_gear.assign(["bamboo"])
	state.equipped_gear_id = "bamboo"
	state.boat_upgraded = false
	_check(state.MESSAGES.messages.size() == 3, "история состоит из трёх ресурсов писем")
	var ids: Array[StringName] = []
	var complete := true
	for data in state.MESSAGES.messages:
		complete = complete and data.id not in ids and not data.title.is_empty() and not data.body.is_empty()
		complete = complete and not data.clue.is_empty() and state.BIOMES.for_habitat(data.habitat) != null
		ids.append(data.id)
	_check(complete, "все письма имеют уникальные id, текст, подсказки и биом")
	_check(not state.discover_message(&"missing") and state.money == 0, "неизвестное письмо не выдаёт награду")
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var player: Node3D = scene.get_node("Player")
	var captain: Node = scene.get_node("BoatSailing")
	var controller: Node = scene.get_node("FishingController")
	var hud: Node = scene.get_node("Hud")
	await create_timer(0.3).timeout
	_check(get_nodes_in_group(&"drift_message").size() == 3, "в мире три отдельные бутылки")
	var lake: Node3D
	for point in get_nodes_in_group(&"drift_message"):
		var data: DriftMessageData = point.data
		var water: Node3D = scene.get_node({&"lake": "Lake", &"mangrove": "MangroveWater", &"fjord": "FjordWater"}[data.habitat])
		var local: Vector3 = point.global_position - water.global_position
		var navigation := BoatSession.new(Vector2(0, -20), 6.0, water.shore_radius)
		_check(water.is_water(point.global_position) and navigation.is_safe(Vector2(local.x, local.z)),
			"бутылка доступна в безопасной области прогулки: %s" % data.id)
		if data.habitat == &"lake":
			lake = point
	player.position = lake.position + Vector3.UP
	lake._process(0.01)
	lake._collect()
	_check(not lake._nearby and state.found_messages.is_empty(), "с суши и без лодки письмо не подбирается")
	var dock: Node3D = scene.get_node("HomeDock")
	player.global_position = dock.to_global(Vector3(0, 0.15, 0.8))
	captain.launch(dock)
	await physics_frame
	captain.session.position = Vector2(lake.position.x, lake.position.z)
	await physics_frame
	await physics_frame
	lake._process(0.01)
	hud._process(0.01)
	_check(lake._nearby and state.found_messages.is_empty() and hud.get_node("Root/LandmarkButton").visible,
		"подплытие показывает действие, но не собирает письмо автоматически")
	_check(hud.get_node("Root/SailStatus").text.contains("↑ Север"), "на лодке виден север при обычном ракурсе")
	controller.camera_rig.turn_view(PI * 0.5)
	controller.camera_rig._process(10.0)
	captain._physics_process(0.0)
	_check(hud.get_node("Root/SailStatus").text.contains("→ Север"), "компас учитывает поворот камеры")
	controller.camera_rig.reset_view()
	var popup: Node = hud.get_node("Root/LandmarkPopup")
	hud._on_sell_pressed()
	lake._collect()
	_check(state.found_messages.is_empty(), "открытый садок блокирует подбор письма")
	hud._on_sell_pressed()
	lake._collect()
	_check(state.found_messages == ["lake_letter"] and state.money == 30 and popup.visible,
		"отдельное действие сохраняет письмо и разовую награду")
	_check(not lake.visible and not lake.is_processing() and not lake._nearby, "собранная бутылка исчезает и перестаёт обновляться")
	_check(not popup._body.text.contains("Все письма сохранены"), "первое письмо не обещает невыданный флажок")
	_check(state.journey_progress("landmarks") == 0, "письмо не подменяет цель трёх береговых ориентиров")
	_check(not state.discover_message(&"lake_letter") and state.money == 30, "повторное письмо не создаёт деньги")
	popup.close()
	state.discover_message(&"fjord_letter")
	_check(state.money == 30, "письма можно собирать не по порядку без промежуточного фарма")
	state.discover_message(&"mangrove_letter")
	_check(state.money == 120 and "letters_home" in state.claimed_goals, "полная история выдаёт единственную финальную награду")
	var flags := get_nodes_in_group(&"boat_pennant")
	var visible_flags := 0
	for flag in flags:
		if flag.visible:
			visible_flags += 1
	_check(not flags.is_empty() and visible_flags == flags.size(), "флажок появляется и у причалов, и на управляемой лодке")
	_check(not state.boat_upgraded and is_equal_approx(state.fishing_gear(&"lake").luck, state.gear.luck),
		"косметическая награда не обходит улучшение лодки и баланс снасти")
	state._load()
	_check(state.found_messages.size() == 3 and state.money == 120, "письма и разовые выплаты переживают загрузку")
	hud._toggle_collection()
	var collection: Node = hud.get_node("Root/CollectionPanel")
	var tabs: Node = collection.get_node("VBox").get_child(1)
	tabs.get_child(5).button_pressed = true
	tabs.get_child(5).pressed.emit()
	_check(collection._habitat == &"messages" and collection._grid.get_child_count() == 3, "у писем отдельная вкладка журнала")
	collection._grid.get_child(0).find_child("ReadEntryButton", true, false).pressed.emit()
	_check(popup.visible and not collection.visible and popup._body.text.contains("Все письма сохранены"),
		"найденные письма можно перечитать с отметкой флажка")
	await process_frame
	await process_frame
	var tab_event := InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.pressed = true
	root.push_input(tab_event)
	_check(root.gui_get_focus_owner() == popup._scroll, "клавиатура переводит фокус в прокрутку длинного письма")
	tab_event = tab_event.duplicate()
	tab_event.pressed = false
	root.push_input(tab_event)
	# Размер шрифта зависит от платформы: гарантируем необходимость прокрутки.
	popup._body.text += "\nСтрока проверки чтения.".repeat(40)
	await process_frame
	await process_frame
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	root.push_input(down)
	down = down.duplicate()
	down.pressed = false
	root.push_input(down)
	await process_frame
	_check(popup._scroll.scroll_vertical > 0, "стрелки прокручивают длинное письмо без мыши")
	popup.close()
	_check(collection.visible and collection._habitat == &"messages", "закрытие письма возвращает в ту же вкладку")
	collection.hide()
	var original: SaveStore = state._store
	var legacy := SaveStore.new("user://letters-legacy-fixture.json")
	var file := FileAccess.open(legacy.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 7, "money": 77, "active_meal_id": "fish_soup", "meal_charges": 4,
		"discovered_landmarks": ["harbor_light"]}))
	file.close()
	state._store = legacy
	state._load()
	_check(state.money == 77 and state.found_messages.is_empty() and state.meal_charges == 4
		and state.discovered_landmarks == ["harbor_light"], "v7 сохраняет еду и открытия, не добавляя письма")
	legacy.save_data({"found_messages": ["lake_letter", "lake_letter", "missing"]})
	state._load()
	_check(state.found_messages == ["lake_letter"], "загрузка отбрасывает неизвестные и повторные письма")
	state._store = original
	state._load()
	captain._land(dock)
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
