extends SceneTree
## Пакет визуальных снимков: мир, коллекция, все трофеи и записи открытий.
## godot --path . -s res://tests/visual_review.gd -- --save=user://visual-review.json --mute --review-dir=/tmp/fishing-review
## Демо-данные существуют только в памяти; основной файл сохранения запрещён.

var _directory := "/tmp/fishing-visual-review"


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-dir="):
			_directory = argument.trim_prefix("--review-dir=")
	_run.call_deferred()


func _run() -> void:
	var debug := root.get_node("DebugTools")
	if debug.save_path.is_empty() or ProjectSettings.globalize_path(debug.save_path).simplify_path() == ProjectSettings.globalize_path("user://save.json").simplify_path():
		printerr("Для визуальной проверки нужен отдельный --save")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		printerr("Для скриншотов нужен графический рендер")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_directory)
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var state := root.get_node("GameState")
	var clock := root.get_node("WorldClock")
	var hud: Node = scene.get_node("Hud")
	var controller: Node = scene.get_node("FishingController")
	var player: Node3D = scene.get_node("Player")
	var camera: Node = scene.get_node("CameraRig")
	clock.day_length_sec = 1000000
	player.can_move = false
	for biome in [["Lake", 0], ["MangroveWater", 80], ["FjordWater", 160]]:
		controller.water = scene.get_node(biome[0])
		hud.set_biome(controller.water.biome)
		player.position = Vector3(biome[1], 0.6, -3)
		camera.snap_to_target()
		for hour in [10, 22]:
			clock.hour = hour
			await _capture("world_%s_%d" % [biome[0], hour])
	clock.hour = 10
	controller.water = scene.get_node("Lake")
	hud.set_biome(controller.water.biome)
	for neighbor in [[Vector3(-7, 0.6, 9), 19, "marta_dusk"], [Vector3(-7, 0.6, 9), 22, "marta_night"], [Vector3(4.5, 0.6, -4), 10, "luka"]]:
		player.position = neighbor[0]
		clock.hour = neighbor[1]
		camera.snap_to_target()
		await _capture("neighbor_%s" % neighbor[2])
	clock.hour = 10
	player.position = Vector3(0, 0.6, -3)
	camera.snap_to_target()
	state.collection.clear()
	hud._toggle_collection()
	var collection: Node = hud.get_node("Root/CollectionPanel")
	await _capture("collection_unknown")
	for fish in state.catalog.fish:
		state.collection[String(fish.id)] = {"count": 7, "best_kg": lerpf(fish.min_weight_kg, fish.max_weight_kg, 0.9)}
	var tabs: Node = collection.get_node("VBox").get_child(1)
	var habitats := [&"lake", &"mangrove", &"fjord"]
	for i in habitats.size():
		var habitat: StringName = habitats[i]
		tabs.get_child(i).button_pressed = true
		tabs.get_child(i).pressed.emit()
		await _capture("collection_%s" % habitat)
	for fish in state.catalog.fish:
		hud._inspect_fish(fish)
		await _capture("trophy_%s" % fish.id)
		hud.close_catch_popup()
	state.discovered_landmarks.clear()
	for data in state.LANDMARKS.landmarks:
		state.discovered_landmarks.append(String(data.id))
	tabs.get_child(4).button_pressed = true
	tabs.get_child(4).pressed.emit()
	await _capture("journal")
	for data in state.LANDMARKS.landmarks:
		hud._inspect_landmark_entry(data)
		await _capture("discovery_%s" % data.id)
		hud.get_node("Root/LandmarkPopup").close()
	collection.hide()
	state.inventory.clear()
	state.active_meal_id = ""
	state.meal_charges = 0
	hud.open_kitchen()
	await _capture("kitchen_empty")
	state.inventory.assign([{"fish_id": "roach", "weight_kg": 0.12}, {"fish_id": "perch", "weight_kg": 0.25},
		{"fish_id": "roach", "weight_kg": 0.55}, {"fish_id": "golden_carp", "weight_kg": 5.7}])
	state.inventory_changed.emit()
	await _capture("kitchen_ready")
	# Только демо-состояние, без cook_meal() и записи в файл.
	state.active_meal_id = "fish_soup"
	state.meal_charges = 5
	state.inventory.remove_at(1)
	state.inventory.remove_at(0)
	state.supplies_changed.emit()
	state.inventory_changed.emit()
	await _capture("kitchen_active")
	hud.get_node("Root/CookingPanel").hide()
	await _capture("meal_hud")
	var pause: Node = get_first_node_in_group(&"pause_menu")
	pause.toggle()
	await _capture("pause_navigation")
	pause.toggle()
	scene.queue_free()
	await process_frame
	print("Визуальная проверка завершена: %s" % _directory)
	quit()


func _capture(name: String) -> void:
	# Даём завершиться открытию карточки и обновиться дополнительному viewport.
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(_directory.path_join(name + ".png"))
	if error != OK:
		printerr("Не удалось сохранить %s: %s" % [name, error_string(error)])
		quit(1)
	else:
		print("Снимок: %s" % name)
