extends SceneTree
## Открытия, дневник, разовая награда и миграция сохранений v5 -> v6.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.discovered_landmarks.clear()
	state.found_messages.clear()
	state.claimed_goals.clear()
	state.collection.clear()
	state.inventory.clear()
	state.visited_biomes.assign(["home_lake"])
	state.owned_gear.assign(["bamboo"])
	state.equipped_gear_id = "bamboo"
	state.boat_upgraded = false
	state.sales = 0
	state.money = 0
	state.active_meal_id = ""
	state.meal_charges = 0
	state.meals_cooked = 0
	_check(state.LANDMARKS.landmarks.size() == 3, "в каталоге три уникальных ориентира")
	var ids: Array[StringName] = []
	var valid := true
	for data in state.LANDMARKS.landmarks:
		valid = valid and data.id not in ids and not data.title.is_empty() and not data.description.is_empty() and state.BIOMES.for_habitat(data.habitat) != null
		ids.append(data.id)
	_check(valid, "данные открытий полны и связаны с существующими биомами")
	_check(not state.discover_landmark(&"not_a_landmark"), "неизвестный id не даёт открытие")
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var player: Node3D = scene.get_node("Player")
	var hud: Node = scene.get_node("Hud")
	player.position = Vector3(7, 0.65, 8.6)
	await create_timer(0.3).timeout
	_check(hud.get_node("Root/LandmarkButton").visible and state.discovered_landmarks.is_empty(), "близость показывает осмотр, но не выдаёт открытие автоматически")
	_tap_interact()
	await process_frame
	var popup: Node = hud.get_node("Root/LandmarkPopup")
	_check(popup.visible and "harbor_light" in state.discovered_landmarks, "осмотр маяка записывает новое место")
	_check(popup._eyebrow.text.contains("НОВОЕ ОТКРЫТИЕ"), "первый осмотр отмечен как новый")
	var before := Vector2(player.position.x, player.position.z)
	Input.action_press(&"move_left")
	await create_timer(0.2).timeout
	Input.action_release(&"move_left")
	_check(Vector2(player.position.x, player.position.z).distance_to(before) < 0.01, "во время чтения персонаж не ходит за окном")
	popup.close()
	await process_frame
	_tap_interact()
	await process_frame
	_check(popup.visible and not popup._eyebrow.text.contains("НОВОЕ ОТКРЫТИЕ") and state.discovered_landmarks.size() == 1, "повторный осмотр открывает дневник без дубликата")
	popup.close()
	state.discover_landmark(&"boatkeepers_hut")
	state.discover_landmark(&"stone_sail")
	_check(state.money == 120 and "harbor_explorer" in state.claimed_goals, "три открытия выдают разовую награду пути")
	state.discover_landmark(&"stone_sail")
	state._load()
	_check(state.money == 120 and state.discovered_landmarks.size() == 3, "открытия и выплата сохраняются без повторной награды")
	var store: SaveStore = state._store
	_check(int(store.load_data().get("version", 0)) == SaveStore.VERSION, "новое сохранение записано в актуальной версии")
	hud._toggle_collection()
	var collection: Node = hud.get_node("Root/CollectionPanel")
	var tabs: Node = collection.get_node("VBox").get_child(1)
	tabs.get_child(4).pressed.emit()
	_check(collection._grid.get_child_count() == 3, "дневник показывает три записи открытий")
	var read: Node = collection._grid.get_child(0).find_child("ReadEntryButton", true, false)
	if read:
		read.pressed.emit()
		_check(popup.visible and not collection.visible, "запись можно перечитать из коллекции")
		popup.close()
		_check(collection.visible and collection._habitat == &"landmarks", "закрытие записи возвращает на вкладку открытий")
	else:
		_check(false, "найдена кнопка чтения записи")
	hud._toggle_collection()
	var legacy := SaveStore.new("user://discoveries-legacy-fixture.json")
	var file := FileAccess.open(legacy.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 5, "money": 123,
		"collection": {"roach": {"count": 2, "best_kg": 0.3}}}))
	file.close()
	state._store = legacy
	state._load()
	_check(state.discovered_landmarks.is_empty() and state.money == 123 and state.collection["roach"]["count"] == 2,
		"v5 загружается с пустыми открытиями, сохраняя кошелёк и рыбу")
	legacy.save_data({"discovered_landmarks": ["harbor_light", "harbor_light", "unknown"]})
	state._load()
	_check(state.discovered_landmarks == ["harbor_light"], "загрузка отбрасывает дубликаты и неизвестные открытия")
	state._store = store
	state._load()
	var sfx := root.get_node("Sfx")
	seed(412)
	var expected_random := randi()
	seed(412)
	sfx._random_pitch()
	_check(randi() == expected_random, "вариации звука не меняют последовательность будущего улова")
	sfx.play(&"plop")
	sfx.set_reel(true, 0.6)
	_check(not sfx._reel.playing, "беззвучный режим не запускает аудиопетлю катушки")
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _tap_interact() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		Input.parse_input_event(event)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
