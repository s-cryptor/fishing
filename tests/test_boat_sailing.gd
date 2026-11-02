extends SceneTree
## Посадка, якорь, заброс с воды и возвращение на берег через настоящую сцену.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var player: Node3D = scene.get_node("Player")
	var captain: Node = scene.get_node("BoatSailing")
	var controller: Node = scene.get_node("FishingController")
	var hud: Node = scene.get_node("Hud")
	player.position = Vector3(-5, 0.6, -9)
	await create_timer(0.3).timeout
	hud.sailing_requested.emit()
	await physics_frame
	await physics_frame
	_check(captain.active and player.ride_target != null, "у причала можно сесть в управляемую лодку")
	_check(player.get_node("CollisionShape3D").disabled and captain.session.is_safe(captain.session.position),
		"посадка безопасно отключает береговую коллизию рыбака")
	var start: Vector2 = captain.session.position
	Input.action_press(&"move_right")
	await create_timer(0.5).timeout
	Input.action_release(&"move_right")
	_check(captain.session.position.x > start.x + 0.3, "обычный ввод движения управляет лодкой")
	controller._start_charge()
	await physics_frame
	var anchored: Vector2 = captain.session.position
	Input.action_press(&"move_right")
	await create_timer(0.2).timeout
	Input.action_release(&"move_right")
	_check(captain.session.position == anchored, "при зарядке заброса лодка стоит на якоре")
	controller._charge_time = 0.95
	controller._release_cast()
	await create_timer(0.8).timeout
	_check(controller.session != null and controller.water.habitat_id() == &"lake", "с лодки начинается рыбалка текущего биома")
	_check(captain.session.position == anchored, "во время ожидания поклёвки лодка не дрейфует")
	hud.sailing_requested.emit()
	_check(captain.active, "во время рыбалки нельзя высадиться")
	controller._end_session()
	controller._to_idle()
	captain.session.position = Vector2(0, -28)
	await physics_frame
	await physics_frame
	hud.sailing_requested.emit()
	_check(captain.active, "в открытой воде нельзя выйти из лодки")
	_check(not hud.get_node("Root/SailButton").visible, "вдали от причала нет ложной кнопки высадки")
	hud._toggle_collection()
	var before: Vector2 = captain.session.position
	Input.action_press(&"move_right")
	await create_timer(0.2).timeout
	Input.action_release(&"move_right")
	_check(captain.session.position == before, "открытый журнал ставит лодку на якорь")
	hud._toggle_collection()
	captain.session.position = start
	await physics_frame
	await physics_frame
	hud.sailing_requested.emit()
	await physics_frame
	await physics_frame
	_check(not captain.active and player.ride_target == null and not player.get_node("CollisionShape3D").disabled,
		"причаливание возвращает управление и коллизию рыбака")
	_check(not controller.water.is_water(player.position) and player.can_move, "высадка происходит на безопасной суше")
	_check(scene.get_node("HomeDock/Boat").visible, "после прогулки у причала снова стоит лодка")
	for route in [["MangroveWater", "MangroveDock"], ["FjordWater", "FjordDock"]]:
		controller.water = scene.get_node(route[0])
		var dock: Node3D = scene.get_node(route[1])
		player.global_position = dock.to_global(Vector3(0, 0.15, 0.8))
		await create_timer(0.2).timeout
		captain.launch(dock)
		await physics_frame
		_check(captain.active and controller.water.is_water(player.position), "прогулка доступна в %s" % route[0])
		captain._land(dock)
		await physics_frame
		_check(not controller.water.is_water(player.position), "из %s можно безопасно высадиться" % route[0])
	# Дожидаемся завершения короткого всплеска перед остановкой аудиосервера.
	await create_timer(0.8).timeout
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
