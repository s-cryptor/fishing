extends SceneTree
## Фокус модальных окон и отпускание общей кнопки после подтверждения.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var state := root.get_node("GameState")
	var hud: Node = scene.get_node("Hud")
	var controller: Node = scene.get_node("FishingController")
	await create_timer(0.2).timeout
	state.money = 1000
	state.owned_gear.assign(["bamboo"])
	state.equipped_gear_id = "bamboo"
	state.active_meal_id = ""
	state.meal_charges = 0
	state.inventory.assign([{"fish_id": "roach", "weight_kg": 0.2}, {"fish_id": "perch", "weight_kg": 0.3}])
	var shop: Control = hud.get_node("Root/ShopPanel")
	hud._open_shop()
	await process_frame
	await process_frame
	var owner := root.gui_get_focus_owner()
	_check(owner != null and owner.name == &"BuyButton" and shop.is_ancestor_of(owner), "магазин выбирает доступное действие покупки")
	var buy_buttons := shop.find_children("BuyButton", "Button", true, false)
	_check(buy_buttons.size() == 4 and buy_buttons[0].disabled, "надетая удочка исключена из действий")
	_check(owner.focus_mode == Control.FOCUS_ALL, "модальные кнопки доступны Tab и крестовине")
	_check(shop.get_node("VBox/Scroll").follow_focus, "прокрутка следует за выбранным действием")
	var old_owner := owner
	shop._rebuild()
	await process_frame
	await process_frame
	owner = root.gui_get_focus_owner()
	_check(owner != null and owner != old_owner and owner.name == &"BuyButton", "после перестройки списка фокус переходит на новую кнопку")
	shop.hide()
	hud.open_kitchen()
	await process_frame
	await process_frame
	owner = root.gui_get_focus_owner()
	_check(owner != null and owner.name == &"CookButton", "кухня выбирает доступный рецепт")
	state.active_meal_id = "fish_soup"
	state.meal_charges = 5
	state.supplies_changed.emit()
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner().name == &"KitchenCloseButton", "при активном блюде фокус остаётся на закрытии, а не на недоступном рецепте")
	hud.get_node("Root/CookingPanel").hide()
	state.collection["roach"] = {"count": 1, "best_kg": 0.2}
	hud._toggle_collection()
	await process_frame
	await process_frame
	var collection: Control = hud.get_node("Root/CollectionPanel")
	owner = root.gui_get_focus_owner()
	_check(owner is Button and owner.toggle_mode and owner.button_pressed, "коллекция начинает с текущей вкладки")
	var tab := owner
	hud._inspect_fish(state.catalog.get_fish(&"roach"))
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner().name == &"TakeButton", "галерея выбирает возврат в коллекцию")
	hud.close_catch_popup()
	await process_frame
	await process_frame
	_check(collection.visible and root.gui_get_focus_owner() == tab, "возврат из галереи восстанавливает вкладку и фокус")
	collection.hide()
	hud.show_landmark(state.LANDMARKS.landmarks[0], false)
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner().name == &"ContinueButton", "запись путешествия доступна кнопкой подтверждения")
	var confirm := InputEventKey.new()
	confirm.keycode = KEY_ENTER
	confirm.pressed = true
	root.push_input(confirm)
	confirm = confirm.duplicate()
	confirm.pressed = false
	root.push_input(confirm)
	_check(not hud.get_node("Root/LandmarkPopup").visible, "Enter действительно активирует выбранную кнопку")
	for path in ["Root/TopBar/SellButton", "Root/TopBar/CollectionButton"]:
		var button := hud.get_node(path) as Button
		_check(button.focus_mode == Control.FOCUS_NONE, "кнопка HUD не перехватывает заброс: %s" % button.name)
	# Воспроизводим одновременные ui_accept и fish_action без физического геймпада.
	hud.show_catch(state.catalog.get_fish(&"roach"), 0.2, false)
	controller.phase = 4
	Input.action_press(&"fish_action")
	hud.close_catch_popup()
	controller._process(0.016)
	_check(controller.phase == 0, "подтверждение улова не начинает зарядку в том же кадре")
	controller._process(0.016)
	_check(controller.phase == 0, "удержание кнопки после закрытия не начинает зарядку")
	Input.action_release(&"fish_action")
	controller._process(0.016)
	_check(not controller._require_action_release, "отпускание снова разрешает заброс")
	Input.action_press(&"fish_action")
	controller._process(0.016)
	_check(controller.phase == 1, "отдельное новое нажатие начинает зарядку")
	Input.action_release(&"fish_action")
	controller._to_idle()
	controller._preview.hide()
	controller._cast_guide.hide()
	var transient := Control.new()
	root.add_child(transient)
	ModalFocus.restore.call_deferred(transient)
	transient.free()
	await process_frame
	_check(true, "отложенный фокус безопасен после удаления окна")
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
