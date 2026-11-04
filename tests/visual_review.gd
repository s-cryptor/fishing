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
	# Проверка не должна зависеть от фокуса нативного окна во время серии снимков.
	debug.automated = true
	DirAccess.make_dir_recursive_absolute(_directory)
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var state := root.get_node("GameState")
	state.found_messages.clear()
	state.journey_changed.emit()
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
		clock.hour = 16
		camera.turn_view(PI * 0.65)
		camera.zoom_view(-3.0)
		camera._process(10.0)
		await _capture("world_%s_orbit" % biome[0])
		camera.reset_view()
		camera._process(10.0)
	clock.hour = 10
	controller.water = scene.get_node("Lake")
	hud.set_biome(controller.water.biome)
	for neighbor in [[Vector3(-7, 0.6, 9), 19, "marta_dusk"], [Vector3(-7, 0.6, 9), 22, "marta_night"], [Vector3(4.5, 0.6, -4), 10, "luka"]]:
		player.position = neighbor[0]
		clock.hour = neighbor[1]
		camera.snap_to_target()
		await _capture("neighbor_%s" % neighbor[2])
	# Предпросмотр без выпуска заброса: не расходует еду и не пишет демо-прогресс.
	var old_gear: String = state.equipped_gear_id
	state.equipped_gear_id = "abyss"
	state.gear_changed.emit()
	player.position = Vector3(0, 0.6, -9)
	player.face_direction(Vector3.FORWARD, 1.0)
	controller.set_process(false)
	controller._start_charge()
	controller._charge_time = 1.0
	controller._update_preview()
	hud.show_charge(1.0)
	player.fishing_pose(true, 1.0, 0.0, false)
	for view in [[PI * 0.5, "side"], [-PI * 0.25, "diagonal"]]:
		camera.reset_view()
		camera.turn_view(view[0])
		camera.zoom_view(-6.0)
		camera._process(10.0)
		await _capture("cast_orbit_%s" % view[1])
	controller._to_idle()
	controller._preview.hide()
	controller._cast_guide.hide()
	hud.hide_charge()
	controller.set_process(true)
	state.equipped_gear_id = old_gear
	state.gear_changed.emit()
	camera.reset_view()
	camera._process(10.0)
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
	tabs.get_child(5).button_pressed = true
	tabs.get_child(5).pressed.emit()
	collection.show()
	await _capture("letters_unknown")
	collection.hide()
	var captain: Node = scene.get_node("BoatSailing")
	var old_boat: bool = state.boat_upgraded
	state.boat_upgraded = true
	state.supplies_changed.emit()
	var routes := {&"lake": ["Lake", "HomeDock"], &"mangrove": ["MangroveWater", "MangroveDock"], &"fjord": ["FjordWater", "FjordDock"]}
	for data in state.MESSAGES.messages:
		var route: Array = routes[data.habitat]
		controller.water = scene.get_node(route[0])
		hud.set_biome(controller.water.biome)
		var dock: Node3D = scene.get_node(route[1])
		player.global_position = dock.to_global(Vector3(0, 0.15, 0.8))
		captain.launch(dock)
		var offset: Vector3 = data.position - controller.water.global_position + Vector3.RIGHT * 2.0
		captain.session.position = Vector2(offset.x, offset.z)
		await physics_frame
		await physics_frame
		camera.reset_view()
		camera.zoom_view(-3.0)
		camera.snap_to_target()
		camera._process(10.0)
		await _capture("bottle_%s" % data.id)
		hud.show_message(data, true)
		await _capture("letter_%s" % data.id)
		hud.get_node("Root/LandmarkPopup").close()
		captain._land(dock)
		await physics_frame
	for data in state.MESSAGES.messages:
		state.found_messages.append(String(data.id))
	state.journey_changed.emit()
	collection._rebuild()
	collection.show()
	await _capture("letters_complete")
	hud._inspect_message_entry(state.MESSAGES.messages[2])
	await create_timer(0.1).timeout
	hud.get_node("Root/LandmarkPopup")._scroll.scroll_vertical = 100000
	await _capture("letters_final_page")
	hud.get_node("Root/LandmarkPopup").close()
	collection.hide()
	controller.water = scene.get_node("Lake")
	hud.set_biome(controller.water.biome)
	var home_dock: Node3D = scene.get_node("HomeDock")
	player.global_position = home_dock.to_global(Vector3(0, 0.15, 0.8))
	captain.launch(home_dock)
	captain.session.position = Vector2(-7, -22)
	await physics_frame
	await physics_frame
	camera.reset_view()
	camera.turn_view(-PI * 0.25)
	camera.zoom_view(-6.0)
	camera.snap_to_target()
	camera._process(10.0)
	await _capture("boat_home_pennant")
	captain._land(home_dock)
	state.boat_upgraded = old_boat
	state.supplies_changed.emit()
	player.position = Vector3(0, 0.6, -3)
	camera.reset_view()
	camera.snap_to_target()
	camera._process(10.0)
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
	state.inventory.assign([{"fish_id": "golden_carp", "weight_kg": 5.7}, {"fish_id": "roach", "weight_kg": 0.55},
		{"fish_id": "roach", "weight_kg": 0.12}, {"fish_id": "perch", "weight_kg": 0.25}])
	state.inventory_changed.emit()
	hud._on_sell_pressed()
	await _capture("basket_ready")
	var basket: Node = hud.get_node("Root/BasketPanel")
	basket.select_except_soup()
	await _capture("basket_keep_soup")
	basket.select_all()
	await _capture("basket_all_selected")
	for i in 30:
		state.inventory.append({"fish_id": "roach", "weight_kg": 0.2})
	state.inventory_changed.emit()
	basket._turn_page(1)
	await _capture("basket_second_page")
	state.inventory.clear()
	state.inventory_changed.emit()
	await _capture("basket_empty")
	basket.hide()
	await _touch_review(scene)
	var pause: Node = get_first_node_in_group(&"pause_menu")
	pause.toggle()
	await _capture("pause_navigation")
	pause.toggle()
	scene.queue_free()
	await process_frame
	print("Визуальная проверка завершена: %s" % _directory)
	quit()


func _touch_review(scene: Node3D) -> void:
	# Синтетические состояния интерфейса: без tick(), расхода припасов и записи в сейв.
	var hud: Node = scene.get_node("Hud")
	var controller: Node = scene.get_node("FishingController")
	var player: Node3D = scene.get_node("Player")
	var camera: Node = scene.get_node("CameraRig")
	var bobber: Node3D = scene.get_node("Bobber")
	var debug := root.get_node("DebugTools")
	var old_touch: bool = hud._touch_available
	var old_debug_touch: bool = debug.touch_ui
	var old_action: String = hud._action_name
	hud._touch_available = true
	hud._action_name = "кнопку"
	debug.touch_ui = true
	player.position = Vector3(0, 0.6, -9)
	player.face_direction(Vector3.FORWARD, 1.0)
	controller.set_process(false)
	controller._start_charge()
	controller._charge_time = 0.65
	controller._update_preview()
	hud.show_charge(0.65)
	player.fishing_pose(true, 0.65, 0.0, false)
	camera._process(10.0)
	await _capture("touch_charge")
	hud.hide_charge()
	controller._preview.hide()
	controller._cast_guide.hide()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var state := root.get_node("GameState")
	var session := FishingSession.new(state.catalog.get_fish(&"pike"), 2.0, 16.0, state.gear, rng, 4.0)
	controller.session = session
	controller.phase = controller.get_script().get_script_constant_map()["Phase"]["SESSION"]
	session.state = FishingSession.State.FIGHTING
	bobber.anchor = Vector3(0, 0, -25)
	bobber.position = bobber.anchor
	bobber.mode = Bobber.Mode.FIGHT
	bobber.show()
	controller.line.attach(player.rod_tip, bobber)
	camera.focus = bobber
	camera._process(10.0)
	hud.show_fight()
	hud.set_hint("Держи кнопку — тяни · на рывке отпускай")
	for mode in ["control", "warning", "release"]:
		session.tension = 0.9 if mode == "release" else 0.58
		session.control = 1.0 if mode == "control" else 0.0
		session._thrash_timer = 0.2 if mode == "warning" else 1.0
		session.is_thrashing = mode == "release"
		bobber.warning = mode == "warning"
		bobber.thrashing = session.is_thrashing
		controller.line.tension = session.tension
		hud.update_fight(session)
		player.fishing_pose(true, 0.0, session.tension, mode == "control")
		await _capture("touch_fight_%s" % mode)
	session.state = FishingSession.State.BITING
	session._timer = session.bite_window() * 0.7
	bobber.mode = Bobber.Mode.BITE
	bobber.warning = false
	bobber.thrashing = false
	hud.hide_fight()
	hud.set_hint("Клюёт! Нажми «ПОДСЕЧЬ!»")
	await _capture("touch_bite")
	controller.session = null
	controller.line.detach()
	bobber.retract()
	controller._to_idle()
	controller.set_process(true)
	hud._touch_available = old_touch
	hud._action_name = old_action
	debug.touch_ui = old_debug_touch
	hud.show_idle_hint()


func _capture(name: String) -> void:
	# Даём завершиться открытию карточки и обновиться дополнительному viewport.
	await create_timer(0.3).timeout
	# macOS может не прислать frame_post_draw перекрытому окну: рисуем кадр явно.
	RenderingServer.force_draw(false)
	var error := root.get_texture().get_image().save_png(_directory.path_join(name + ".png"))
	if error != OK:
		printerr("Не удалось сохранить %s: %s" % [name, error_string(error)])
		quit(1)
	else:
		print("Снимок: %s" % name)
