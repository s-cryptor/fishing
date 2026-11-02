extends SceneTree
## Выбор продажи атомарен, кухня и рекорды не теряют нужную рыбу.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.money = 0
	state.sales = 0
	state.claimed_goals.clear()
	for goal in state.JOURNEY.goals:
		state.claimed_goals.append(goal["id"])
	state.inventory.assign([
		{"fish_id": "golden_carp", "weight_kg": 6.0}, {"fish_id": "roach", "weight_kg": 0.6},
		{"fish_id": "roach", "weight_kg": 0.1}, {"fish_id": "perch", "weight_kg": 0.2}])
	state.collection = {"golden_carp": {"count": 1, "best_kg": 6.0}, "roach": {"count": 2, "best_kg": 0.6}}
	var records: Dictionary = state.collection.duplicate(true)
	var before := JSON.stringify(state.inventory)
	for raw in [[], [-1], [0, 99], [1, 1]]:
		var invalid: Array[int] = []
		invalid.assign(raw)
		_check(state.sell_selected(invalid) == 0 and JSON.stringify(state.inventory) == before and state.money == 0
			and state.sales == 0, "недопустимый выбор не продаёт ничего: %s" % str(invalid))
	var expected: int = state.catalog.get_fish(&"roach").value_for(0.6) + state.catalog.get_fish(&"perch").value_for(0.2)
	var selected: Array[int] = [3, 1]
	_check(state.sell_selected(selected) == expected and state.money == expected and state.sales == 1,
		"несортированный выбор продаёт точные экземпляры и считается одной продажей")
	_check(state.inventory.size() == 2 and state.inventory[0]["fish_id"] == "golden_carp"
		and state.inventory[1]["weight_kg"] == 0.1 and state.collection == records,
		"невыбранный трофей, остаток садка и рекорды не меняются")
	state._load()
	_check(state.money == expected and state.inventory.size() == 2 and state.sales == 1, "частичная продажа сохраняется")
	state.sell_all()
	_check(state.inventory.is_empty() and state.sales == 2, "старый sell_all использует ту же логику продажи")
	var after: int = state.money
	state.sell_all()
	_check(state.money == after and state.sales == 2, "пустой садок не создаёт новую продажу и награды")
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var hud: Node = scene.get_node("Hud")
	var controller: Node = scene.get_node("FishingController")
	var panel: Node = hud.get_node("Root/BasketPanel")
	await process_frame
	hud._on_sell_pressed()
	_check(panel.visible and hud.is_modal_open() and panel._sell.disabled, "пустой садок доступен, но продажа заблокирована")
	_check(panel._list.get_child(0) is Label, "пустой садок подсказывает следующий шаг")
	state.inventory.assign([
		{"fish_id": "golden_carp", "weight_kg": 6.0}, {"fish_id": "roach", "weight_kg": 0.6},
		{"fish_id": "roach", "weight_kg": 0.1}, {"fish_id": "perch", "weight_kg": 0.2}])
	state.inventory_changed.emit()
	_check(panel._selected.is_empty() and panel._list.get_child_count() == 4, "новый улов не отмечается для продажи сам")
	panel.select_common()
	_check(panel._selected.size() == 3 and not panel._selected.has(0), "быстрый выбор не включает золотого карпа")
	panel.select_except_soup()
	_check(panel._selected.keys() == [1], "для ухи остаются две самые недорогие обычные рыбы")
	panel.select_all()
	_check(panel._selected.size() == 4 and panel._selection.text.contains("редких: 1"), "выбор всего явно показывает особый улов")
	panel.clear_selection()
	_check(panel._selected.is_empty() and panel._sell.disabled, "снятие выбора блокирует продажу")
	panel.select_except_soup()
	var old_money: int = state.money
	panel._sell_selected()
	_check(state.inventory.size() == 3 and state.money > old_money and panel._selected.is_empty(), "продажа через меню очищает устаревший выбор")
	_check(state.cooking_selection(state.MEALS.get_meal(&"fish_soup")).size() == 2, "после продажи оставленного улова достаточно для ухи")
	_check(int(state.collection["golden_carp"]["count"]) == int(records["golden_carp"]["count"])
		and is_equal_approx(float(state.collection["golden_carp"]["best_kg"]), float(records["golden_carp"]["best_kg"]))
		and int(state.collection["roach"]["count"]) == int(records["roach"]["count"])
		and is_equal_approx(float(state.collection["roach"]["best_kg"]), float(records["roach"]["best_kg"])),
		"продажа через меню не стирает коллекцию после JSON-загрузки")
	for i in 100:
		state.inventory.append({"fish_id": "roach", "weight_kg": 0.2})
	state.inventory_changed.emit()
	_check(panel._list.get_child_count() == panel.PAGE_SIZE and not panel._next.disabled, "большой садок создаёт не более одной страницы строк")
	panel._checks[1].toggled.emit(true)
	panel._turn_page(1)
	_check(panel._page == 1 and panel._selected.has(1) and not panel._previous.disabled, "выбор сохраняется между страницами")
	panel._checks[12].toggled.emit(true)
	_check(panel._selected.has(12), "на следующей странице отмечается абсолютный индекс")
	state.inventory.remove_at(0)
	state.inventory_changed.emit()
	_check(panel._selected.is_empty(), "любая смена садка сбрасывает индексы до следующей продажи")
	panel.hide()
	controller._start_charge()
	hud._on_sell_pressed()
	_check(not panel.visible, "садок нельзя открыть поверх заброса")
	controller._to_idle()
	controller._preview.hide()
	controller._cast_guide.hide()
	hud._on_sell_pressed()
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner() != null and panel.is_ancestor_of(root.gui_get_focus_owner()), "садок доступен без мыши")
	hud._toggle_collection()
	_check(not panel.visible and hud.get_node("Root/CollectionPanel").visible, "коллекция и садок не перекрывают друг друга")
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
