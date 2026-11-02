extends SceneTree
## Просмотр коллекции не считается новым уловом и не повторяет выплаты.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var state := root.get_node("GameState")
	var hud: Node = scene.get_node("Hud")
	var controller: Node = scene.get_node("FishingController")
	state.collection["roach"] = {"count": 3, "best_kg": 0.4}
	state.collection.erase("pike")
	state.last_catch_report = {"record": true, "previous_best": 0.3,
		"rewards": [{"title": "Нельзя выдавать повторно", "reward": 999}]}
	var before := JSON.stringify(state.collection)
	var money: int = state.money
	var count: int = state.inventory.size()
	hud._toggle_collection()
	await process_frame
	var collection: Node = hud.get_node("Root/CollectionPanel")
	var popup: Node = hud.get_node("Root/CatchPopup")
	var card: Node = collection._grid.get_child(0)
	var inspect := card.find_child("InspectButton", true, false)
	_check(inspect != null, "у открытого вида есть кнопка просмотра трофея")
	if inspect == null:
		quit(1)
		return
	inspect.pressed.emit()
	await process_frame
	_check(popup.visible and not collection.visible and hud.is_modal_open(), "карточка рекорда заменяет коллекцию без наложения окон")
	_check(popup.get_node("VBox/Stats").text.contains("0.40") and popup.get_node("VBox/Stats").text.contains("3"), "в карточке показаны сохранённые рекорд и количество")
	_check(not popup.get_node("VBox/Description").text.contains("Нельзя выдавать повторно"), "просмотр не использует награды от последней поимки")
	_check(controller.phase == 0, "просмотр трофея не переводит рыбалку в фазу результата")
	hud._open_shop()
	_check(not hud.get_node("Root/ShopPanel").visible, "магазин не перекрывает просмотр трофея")
	popup.close()
	_check(collection.visible and not popup.visible, "закрытие трофея возвращает в коллекцию")
	_check(popup.get_node("VBox/Swatch")._viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "закрытый просмотр не расходует рендер")
	hud._inspect_fish(state.catalog.get_fish(&"pike"))
	_check(not popup.visible and collection.visible, "неоткрытый вид нельзя рассмотреть в 3D")
	hud._inspect_fish(state.catalog.get_fish(&"roach"))
	hud._toggle_collection()
	_check(collection.visible and not popup.visible, "клавиша коллекции возвращает из просмотра в журнал")
	_check(JSON.stringify(state.collection) == before and state.money == money and state.inventory.size() == count,
		"просмотр не меняет коллекцию, инвентарь и деньги")
	hud._toggle_collection()
	popup.open(state.catalog.get_fish(&"roach"), 0.2, false)
	_check(popup.get_node("VBox/TakeButton").text == "Забрать", "следующий настоящий улов восстанавливает кнопку забора")
	popup.close()
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
