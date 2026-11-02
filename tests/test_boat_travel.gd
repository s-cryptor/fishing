extends SceneTree
## Интеграционная проверка причалов, блокировки перехода и активного биома.
## Запускать с отдельным сохранением: -- --save=user://boat-test.json --mute

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var player: Node3D = scene.get_node("Player")
	var controller: Node = scene.get_node("FishingController")
	var hud: Node = scene.get_node("Hud")
	var state := root.get_node("GameState")
	var pause_menu := scene.get_node("PauseMenu")
	var clock := root.get_node("WorldClock")
	pause_menu.toggle()
	var hour_before: float = clock.hour
	await create_timer(0.2).timeout
	_check(paused and clock.hour == hour_before, "пауза останавливает игровые часы")
	pause_menu.toggle()
	_check(not paused, "из паузы можно вернуться в игру")
	state.bait_charges = 3
	state.bait_enabled = true
	player.position = Vector3(0, 0.6, 0)
	controller._start_charge()
	hud._toggle_collection()
	_check(not hud.get_node("Root/CollectionPanel").visible, "коллекция не закрывает заброс")
	controller._release_cast()
	_check(state.bait_charges == 3, "заброс на сушу не тратит приманку")
	player.position = Vector3(-5, 0.6, -9)
	await create_timer(0.2).timeout
	controller.phase = 1 # CHARGING
	hud.travel_requested.emit()
	await process_frame
	_check(controller.water.habitat_id() == &"lake", "во время заброса лодка недоступна")
	controller.phase = 0 # IDLE
	hud.travel_requested.emit()
	_check(hud.is_modal_open() and not player.can_move, "в пути ввод заблокирован")
	await create_timer(1.2).timeout
	_check(controller.water.habitat_id() == &"mangrove" and player.position.x > 70,
			"лодка перевозит в мангры и переключает водоём")
	var session := FishingSession.create(state.catalog, controller.water.habitat_id(), state.gear, 10.0, 42)
	_check(session != null and &"mangrove" in session.fish.habitats, "после перехода клюёт мангровая рыба")
	hud.travel_requested.emit()
	await create_timer(1.2).timeout
	_check(controller.water.habitat_id() == &"lake" and player.position.x < 0 and player.can_move,
			"обратный путь возвращает домой и разблокирует ходьбу")
	state.boat_upgraded = false
	controller.water = scene.get_node("MangroveWater")
	player.position = Vector3(89, 0.6, 0)
	await create_timer(0.2).timeout
	hud.travel_requested.emit()
	await create_timer(0.1).timeout
	_check(controller.water.habitat_id() == &"mangrove" and player.position.x < 100,
			"фьорд закрыт до улучшения лодки")
	state.money = 1000
	state.upgrade_boat()
	hud.travel_requested.emit()
	await create_timer(1.2).timeout
	_check(controller.water.habitat_id() == &"fjord" and player.position.x > 140,
			"улучшенная лодка открывает фьорд")
	var fjord_session := FishingSession.create(state.catalog, controller.water.habitat_id(), state.gear, 10.0, 7)
	_check(fjord_session != null and &"fjord" in fjord_session.fish.habitats, "во фьорде клюёт северная рыба")
	hud.travel_requested.emit()
	await create_timer(1.2).timeout
	_check(controller.water.habitat_id() == &"mangrove", "из фьорда можно вернуться в мангры")
	player.position = Vector3(75, 0.6, -9)
	await create_timer(0.2).timeout
	hud.travel_requested.emit()
	await create_timer(1.2).timeout
	_check(controller.water.habitat_id() == &"lake", "полный маршрут возвращает на родной остров")
	player.position = Vector3(4.5, 0.6, -4)
	await create_timer(0.2).timeout
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var shop: Control = hud.get_node("Root/ShopPanel")
	_check(shop.visible and hud.is_modal_open(), "у прилавка открывается разговор с Лукой")
	shop.get_node("VBox/LukaChoices/LukaOrdersButton").pressed.emit()
	_check(shop.get_node("VBox/Scroll/ShopList").get_child_count() == state.orders.orders.size(),
			"Лука показывает все актуальные заказы")
	shop.get_node("VBox/LukaChoices/LukaGearButton").pressed.emit()
	_check(shop.get_node("VBox/Scroll/ShopList").get_child_count() == state.gear_catalog.rods.size(),
			"из разговора доступны все удочки")
	shop.get_node("VBox/LukaChoices/LukaSuppliesButton").pressed.emit()
	_check(shop.get_node("VBox/Scroll/ShopList").get_child_count() == 2, "у Луки доступны приманка и улучшение лодки")
	await create_timer(0.5).timeout
	player.position = Vector3.ZERO
	await create_timer(0.2).timeout
	_check(not shop.visible, "разговор закрывается при уходе от прилавка")
	hud._toggle_collection()
	var collection_panel := hud.get_node("Root/CollectionPanel")
	var tabs := collection_panel.get_node("VBox").get_child(1)
	tabs.get_child(2).pressed.emit()
	_check(collection_panel.get_node("VBox/Scroll/CollectionGrid").get_child_count() == 3,
			"каталог биомов создаёт вкладку с тремя рыбами фьорда")
	tabs.get_child(3).pressed.emit()
	_check(collection_panel.get_node("VBox/Scroll/CollectionGrid").get_child_count() == state.JOURNEY.goals.size(),
			"журнал показывает все цели пути рыболова")
	hud._toggle_collection()
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
