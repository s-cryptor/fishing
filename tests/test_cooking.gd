extends SceneTree
## Кухня расходует явно выбранный обычный улов, сохраняет рекорды и считает забросы.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.money = 0
	state.inventory.clear()
	state.collection = {"roach": {"count": 3, "best_kg": 0.6}, "golden_carp": {"count": 1, "best_kg": 6.0}}
	state.owned_gear.assign(["bamboo"])
	state.equipped_gear_id = "bamboo"
	state.active_meal_id = ""
	state.meal_charges = 0
	state.meals_cooked = 0
	state.bait_charges = 0
	state.bait_enabled = false
	state.boat_upgraded = false
	state.claimed_goals.clear()
	for goal in state.JOURNEY.goals:
		if goal["id"] != "first_meal":
			state.claimed_goals.append(goal["id"])
	var soup: MealData = state.MEALS.get_meal(&"fish_soup")
	var grilled: MealData = state.MEALS.get_meal(&"grilled_perch")
	_check(state.MEALS.meals.size() == 2 and soup.charges == 5 and grilled.charges == 3, "рецепты и длительности заданы ресурсами")
	_check(MealData.casts_text(1) == "1 заброс" and MealData.casts_text(3) == "3 заброса"
		and MealData.casts_text(5) == "5 забросов" and MealData.casts_text(11) == "11 забросов", "число порций корректно склоняется в интерфейсе")
	_check(not state.cook_meal(&"unknown"), "несуществующий рецепт не меняет прогресс")
	state.inventory.assign([{"fish_id": "golden_carp", "weight_kg": 6.0}])
	_check(not state.cook_meal(soup.id) and state.inventory.size() == 1 and state.meals_cooked == 0,
		"редкий улов не подходит для обычной ухи и не расходуется")
	state.inventory.assign([
		{"fish_id": "golden_carp", "weight_kg": 6.0}, {"fish_id": "roach", "weight_kg": 0.6},
		{"fish_id": "roach", "weight_kg": 0.1}, {"fish_id": "perch", "weight_kg": 0.2}])
	_check(state.cooking_selection(soup) == [2, 3], "кухня выбирает самый недорогой подходящий улов")
	_check(state.cooking_selection(grilled) == [3], "рецепт окуня не принимает другую обычную рыбу")
	var records := JSON.stringify(state.collection)
	_check(state.cook_meal(soup.id) and state.inventory.size() == 2 and state.active_meal_id == "fish_soup",
		"готовка расходует ровно две выбранные рыбы и включает уху")
	_check(state.inventory[0]["fish_id"] == "golden_carp" and state.inventory[1]["weight_kg"] == 0.6
		and JSON.stringify(state.collection) == records, "дорогой улов и рекорды остаются нетронутыми")
	_check(state.money == 40 and state.meals_cooked == 1 and "first_meal" in state.claimed_goals,
		"первая готовка даёт разовую награду пути")
	var before := JSON.stringify(state.inventory)
	_check(not state.cook_meal(grilled.id) and JSON.stringify(state.inventory) == before and state.meal_charges == 5,
		"активное блюдо нельзя незаметно заменить или сложить с другим")
	var base: GearStats = state.gear
	var prepared: GearStats = state.fishing_gear(&"lake")
	_check(is_equal_approx(prepared.reel_speed, base.reel_speed * 1.1) and is_equal_approx(base.reel_speed, 1.8),
		"уха усиливает копию снасти, а не общий ресурс")
	state.bait_charges = 3
	state.bait_enabled = true
	state.boat_upgraded = true
	prepared = state.fishing_gear(&"mangrove")
	_check(is_equal_approx(prepared.luck, base.luck + state.BAIT.luck_bonus + state.BOAT.scouting_luck),
		"блюдо совместимо с приманкой и лодкой")
	state.consume_fishing_supplies()
	_check(state.meal_charges == 4 and state.bait_charges == 2, "один заброс расходует по одной порции блюда и приманки")
	state._load()
	_check(state.meal_charges == 4 and state.active_meal_id == "fish_soup" and state.meals_cooked == 1,
		"эффект и счётчик готовки переживают загрузку")
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var controller: Node = scene.get_node("FishingController")
	var player: Node3D = scene.get_node("Player")
	var hud: Node = scene.get_node("Hud")
	await process_frame
	var has_cook := false
	var has_trader := false
	for neighbor in get_nodes_in_group(&"neighbor"):
		has_cook = has_cook or neighbor.cook
		has_trader = has_trader or not neighbor.cook
	_check(has_cook and has_trader, "Марта и Лука используют собственные модели соседей")
	player.position = Vector3(0, 0.6, 0)
	controller._start_charge()
	controller._release_cast()
	_check(state.meal_charges == 4 and state.bait_charges == 2, "заброс на сушу не расходует ни еду, ни приманку")
	state.meal_charges = 1
	player.position = Vector3(0, 0.6, -9)
	controller._start_charge()
	controller._charge_time = 0.95
	controller._release_cast()
	_check(state.active_meal() == null and state.meal_charges == 0, "последний заряд заканчивает эффект только для следующих забросов")
	_check(controller.session != null and is_equal_approx(controller.session.gear.reel_speed, base.reel_speed * 1.1),
		"уже начавшаяся сессия сохраняет бонус последнего заряда")
	await create_timer(0.8).timeout
	controller._end_session()
	controller._to_idle()
	state.inventory.append({"fish_id": "roach", "weight_kg": 0.1})
	state.inventory.append({"fish_id": "perch", "weight_kg": 0.2})
	player.position = Vector3(-4.8, 0.65, 8)
	await create_timer(0.3).timeout
	_check(hud.get_node("Root/KitchenButton").visible, "у Марты появляется действие кухни")
	_check(scene.get_node("CameraRig")._idle_goal().z < player.position.z, "на южном берегу камера показывает остров, а не пустое море")
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		Input.parse_input_event(event)
	await process_frame
	var panel: Node = hud.get_node("Root/CookingPanel")
	_check(panel.visible and hud.is_modal_open() and panel._list.get_child_count() == 2, "разговор с Мартой открывает два рецепта")
	var ingredients: Node = panel._list.get_child(0).find_child("Ingredients", true, false)
	_check(ingredients.text.contains("0.10") and ingredients.text.contains("Вместо продажи")
		and not ingredients.text.contains("Золотой карп"), "перед готовкой видны конкретные ингредиенты и цена отказа от продажи")
	var cook: Node = panel._list.get_child(0).find_child("CookButton", true, false)
	_check(not cook.disabled, "доступный рецепт разрешает готовку")
	cook.pressed.emit()
	_check(state.meals_cooked == 2 and state.money == 40, "повторная готовка не повторяет разовую выплату")
	_check(panel._list.get_child(0).find_child("CookButton", true, false).disabled, "после готовки меню явно блокирует замену активного эффекта")
	panel.hide()
	hud.set_fishing_focus(false)
	_check(hud.get_node("Root/SideStack/MealInfo").visible, "HUD показывает оставшиеся порции блюда")
	hud.set_fishing_focus(true)
	_check(not hud.get_node("Root/SideStack/MealInfo").visible, "во время рыбалки статус еды не перекрывает борьбу")
	hud.set_fishing_focus(false)
	var original: SaveStore = state._store
	var legacy := SaveStore.new("user://meal-legacy-fixture.json")
	var file := FileAccess.open(legacy.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 6, "money": 77, "discovered_landmarks": ["harbor_light"]}))
	file.close()
	state._store = legacy
	state._load()
	_check(state.money == 77 and state.discovered_landmarks == ["harbor_light"] and state.active_meal() == null
		and state.meals_cooked == 0, "v6 загружается без еды, сохраняя деньги и открытия")
	legacy.save_data({"active_meal_id": "missing", "meal_charges": 1000})
	state._load()
	_check(state.active_meal_id.is_empty() and state.meal_charges == 0, "неизвестное блюдо в сохранении не создаёт эффект")
	legacy.save_data({"active_meal_id": "grilled_perch", "meal_charges": 1000})
	state._load()
	_check(state.meal_charges == grilled.charges, "сохранение не создаёт больше порций, чем разрешает рецепт")
	_check(is_equal_approx(state.fishing_gear(&"lake").luck, base.luck + grilled.luck_bonus)
		and is_equal_approx(state.fishing_gear(&"lake").reel_speed, base.reel_speed), "окунь усиливает удачу, не выдавая бонус ухи")
	state._store = original
	state._load()
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
