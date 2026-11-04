extends SceneTree
## Личная цель сохраняется, но не меняет рыбалку и не выдаёт повторные награды.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dawn := DayTime.flag(DayTime.Phase.DAWN)
	var night := DayTime.flag(DayTime.Phase.NIGHT)
	_check(DayTime.hours_until_active(dawn, 5.0) == 0.0, "клёв начинается точно на границе рассвета")
	_check(DayTime.hours_until_active(dawn, 8.0) == 21.0, "после рассвета учитывается следующий день")
	_check(DayTime.hours_until_active(night, 0.0) == 0.0, "ночной клёв продолжается через полночь")
	_check(DayTime.hours_until_active(night, 5.0) == 16.0, "ночь заканчивается точно в пять")
	_check(DayTime.hours_until_active(dawn | night, 19.0) == 2.0, "выбирается ближайшая разрешённая фаза")
	_check(DayTime.hours_until_active(dawn, -1.0) == 6.0 and DayTime.hours_until_active(dawn, 29.0) == 0.0,
		"расчёт нормализует часы до одного дня")
	_check(DayTime.hours_until_active(0, 7.0) < 0.0 and DayTime.hours_until_active(DayTime.ALL_PHASES, 12.0) == 0.0,
		"пустое расписание и круглосуточный клёв не создают ложный таймер")
	var state := root.get_node("GameState")
	var debug := root.get_node("DebugTools")
	var save_before: String = debug.save_path
	for path in ["", "user://save.json", "user://unused/../save.json"]:
		debug.save_path = path
		_check(not debug._isolated_save(), "отладочная цель не использует основной сейв: %s" % path)
	debug.save_path = save_before
	_check(debug._isolated_save(), "отдельный тестовый сейв разрешает отладочную цель")
	debug._take_shot()
	_check(true, "headless-прогон снимков не ожидает несуществующий кадр рендера")
	state.inventory.clear()
	state.collection.clear()
	state.fishing_target_id = ""
	state.fishing_target_trophy = false
	state.claimed_goals.clear()
	for goal in state.JOURNEY.goals:
		state.claimed_goals.append(goal["id"])
	var money: int = state.money
	var fish: FishData = state.catalog.get_fish(&"golden_carp")
	_check(not state.track_fish(&"invalid") and state.fishing_target_id.is_empty(), "неизвестный id не становится целью")
	_check(state.track_fish(fish.id) and not state.fishing_target_trophy, "неоткрытый вид становится целью первой поимки")
	_check(not FishingTarget.title(fish, false, false).contains(fish.display_name), "неоткрытая цель не раскрывает название")
	state._load()
	_check(state.fishing_target_id == String(fish.id) and not state.fishing_target_trophy, "выбранная цель переживает перезапуск")
	_check(not state.track_fish(fish.id), "повторный выбор через API не меняет режим цели")
	state.register_catch(state.catalog.get_fish(&"roach"), 0.2)
	_check(state.fishing_target_id == String(fish.id) and not state.last_catch_report.has("target_completed"), "другая рыба не завершает выбранную цель")
	state.register_catch(fish, fish.min_weight_kg)
	_check(state.fishing_target_id.is_empty() and state.last_catch_report.has("target_completed"), "первая поимка отмечает выполнение и снимает цель")
	_check(state.money == money, "личная цель не печатает дополнительные монеты")
	state._load()
	_check(state.fishing_target_id.is_empty(), "выполненная цель не возвращается после загрузки")
	state.register_catch(fish, fish.min_weight_kg)
	_check(not state.last_catch_report.has("target_completed"), "следующий улов не повторяет отметку выполнения")
	_check(state.track_fish(fish.id) and state.fishing_target_trophy, "для известного вида цель — новый золотой трофей")
	state.register_catch(fish, lerpf(fish.min_weight_kg, fish.max_weight_kg, 0.84))
	_check(not state.fishing_target_id.is_empty(), "обычный экземпляр не завершает трофейную цель")
	state.register_catch(fish, lerpf(fish.min_weight_kg, fish.max_weight_kg, 0.85))
	_check(state.fishing_target_id.is_empty() and state.last_catch_report["target_completed"].contains("Золотой"),
		"точная граница трофейного веса завершает цель")
	var snapper: FishData = state.catalog.get_fish(&"mangrove_snapper")
	_check(FishingTarget.status(snapper, 10.0, &"lake", false, state.BIOMES).contains("18:00"), "дневная подсказка луциана указывает начало заката")
	_check(FishingTarget.status(snapper, 22.0, &"mangrove", false, state.BIOMES).contains("Сейчас клюёт · здесь"), "в нужном биоме и времени подсказка разрешает ловить")
	_check(FishingTarget.status(state.catalog.get_fish(&"arctic_char"), 10.0, &"lake", false, state.BIOMES).contains("улучши лодку"),
		"цель фьорда сначала объясняет необходимое улучшение лодки")
	var gear_before: GearStats = state.fishing_gear(&"lake")
	var session_a := FishingSession.create(state.catalog, &"lake", state.gear, 10.0, 678)
	state.track_fish(fish.id)
	var session_b := FishingSession.create(state.catalog, &"lake", state.gear, 10.0, 678)
	var gear_after: GearStats = state.fishing_gear(&"lake")
	_check(session_a.fish == session_b.fish and session_a.weight_kg == session_b.weight_kg
		and gear_after.luck == gear_before.luck and gear_after.reel_speed == gear_before.reel_speed and gear_after.bite_time_mult == gear_before.bite_time_mult,
		"выбор цели не меняет снасть, seed и результат выбора рыбы")
	state.clear_fishing_target()
	state._load()
	_check(state.fishing_target_id.is_empty(), "ручная отмена также сохраняется")
	var old_store: SaveStore = state._store
	state._store = SaveStore.new("user://target-migration-fixture.json")
	for target in [null, "bad", {"fish_id": 23}, {"fish_id": "invalid"}, {"fish_id": "roach", "trophy": []}]:
		state._store.save_data({"money": 321, "fishing_target": target})
		state._load()
		_check(state.money == 321 and state.fishing_target_id.is_empty(), "повреждённая цель не ломает остальной прогресс: %s" % str(target))
	var file := FileAccess.open(state._store.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 9, "money": 543, "collection": {"roach": {"count": 2, "best_kg": 0.3}}}))
	file.close()
	state._load()
	_check(state.money == 543 and state.collection.has("roach") and state.fishing_target_id.is_empty(), "v9 мигрирует без цели и без потери коллекции")
	state._store = old_store
	state._load()
	await _test_ui(state)
	quit(1 if _failures else 0)


func _test_ui(state: Node) -> void:
	state.collection.clear()
	state.collection["roach"] = {"count": 1, "best_kg": 0.2}
	state.clear_fishing_target()
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var hud: Node = scene.get_node("Hud")
	hud._toggle_collection()
	var panel: Node = hud.get_node("Root/CollectionPanel")
	await process_frame
	await process_frame
	var buttons: Array[Node] = panel._grid.find_children("TrackFishButton", "Button", true, false)
	_check(buttons.size() == 6 and buttons[0].focus_mode == Control.FOCUS_ALL, "цель доступна на всех карточках с клавиатуры и геймпада")
	buttons[0].grab_focus()
	buttons[0].pressed.emit()
	_check(state.fishing_target_id == "roach" and buttons[0].text == "Снять цель" and root.gui_get_focus_owner() == buttons[0],
		"выбор цели обновляет карточку без потери фокуса и пересоздания списка")
	var hint: Label = hud.get_node("Root/SideStack/JourneyHint")
	_check(hint.text.contains("Золотой трофей") and hint.text.contains("Плотва"), "HUD показывает выбранный трофей вместо общей цели")
	hud.set_sailing_mode(true)
	_check(hint.visible, "личная цель остаётся видимой во время лодочной прогулки")
	hud.set_fishing_focus(true)
	_check(not hint.visible, "личная цель не перекрывает вываживание")
	hud.set_fishing_focus(false)
	hud.set_sailing_mode(false)
	buttons[3].pressed.emit()
	_check(buttons[0].text == "Искать трофей" and buttons[3].text == "Снять цель" and state.fishing_target_id == "pike",
		"смена цели снимает прежнее выделение и не раскрывает неизвестную рыбу")
	panel.hide()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	hud._on_journey_input(click)
	await process_frame
	await process_frame
	_check(panel.visible and root.gui_get_focus_owner().get_meta(&"fish_id", "") == "pike",
		"нажатие на подсказку открывает выбранную карточку и прокручивает к действию")
	buttons = panel._grid.find_children("TrackFishButton", "Button", true, false)
	buttons[3].pressed.emit()
	_check(state.fishing_target_id.is_empty() and not hint.text.contains("Неизвестный вид"), "повторное действие снимает цель и возвращает путь рыболова")
	state.track_fish(&"roach")
	var entry_before := JSON.stringify(state.collection)
	hud._inspect_fish(state.catalog.get_fish(&"roach"))
	_check(state.fishing_target_id == "roach" and JSON.stringify(state.collection) == entry_before, "просмотр трофея не выполняет личную цель")
	hud.close_catch_popup()
	panel.hide()
	state.register_catch(state.catalog.get_fish(&"roach"), 0.6)
	hud.show_catch(state.catalog.get_fish(&"roach"), 0.6, false)
	var popup: Control = hud.get_node("Root/CatchPopup")
	_check(popup.get_node("VBox/DescriptionScroll/Description").text.contains("Цель выполнена!"), "результат поимки явно отмечает завершение цели")
	# Длинный отчёт не вытесняет кнопку за нижнюю границу экрана.
	state.last_catch_report = {"record": true, "previous_best": 0.55, "target_completed": "Золотой трофей: Плотва", "rewards": state.JOURNEY.goals}
	popup.open(state.catalog.get_fish(&"roach"), 0.6, false)
	await create_timer(0.3).timeout
	var scroll: ScrollContainer = popup.get_node("VBox/DescriptionScroll")
	_check(popup.get_global_rect().position.y >= 0 and popup.get_global_rect().end.y <= popup.get_viewport_rect().size.y,
		"даже длинный отчёт помещается в логическую высоту экрана")
	_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "длинные награды доступны прокруткой, а не обрезаны")
	scroll.grab_focus()
	var down := InputEventKey.new()
	down.keycode = KEY_PAGEDOWN
	down.pressed = true
	root.push_input(down)
	_check(scroll.scroll_vertical > 0, "описание и награды прокручиваются клавиатурой")
	popup.inspect(state.catalog.get_fish(&"roach"), state.collection["roach"])
	_check(scroll.scroll_vertical == 0, "следующее открытие сбрасывает прокрутку описания")
	hud.close_catch_popup()
	scene.queue_free()
	await process_frame


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
