class_name Hud
extends CanvasLayer

signal catch_popup_closed
signal travel_requested
signal sailing_requested
signal landmark_requested

var _action_name := "Пробел"
var _touch_available := false
var _fishing_focus := false
var _sailing_active := false
var _sailing_available := false
var _return_to_collection := false
var _return_from_landmark := false
var _nearby_landmark: LandmarkData

@onready var _money_label: Label = %MoneyLabel
@onready var _gear_label: Label = %GearLabel
@onready var _clock_label: Label = %ClockLabel
@onready var _shop_button: Button = %ShopButton
@onready var _shop: ShopPanel = %ShopPanel
@onready var _sell_button: Button = %SellButton
@onready var _hint_label: Label = %HintLabel
@onready var _toast_label: Label = %ToastLabel
@onready var _charge_bar: ProgressBar = %ChargeBar
@onready var _fight_panel: Control = %FightPanel
@onready var _tension_meter: TensionMeter = %TensionMeter
@onready var _fight_status: Label = %FightStatus
@onready var _catch_popup: CatchPopup = %CatchPopup
@onready var _collection: CollectionPanel = %CollectionPanel
@onready var _touch_controls: Control = %TouchControls
@onready var _biome_label: Label = %BiomeLabel
@onready var _travel_button: Button = %TravelButton
@onready var _travel_fade: ColorRect = %TravelFade
@onready var _travel_label: Label = %TravelLabel
@onready var _landmark_popup: LandmarkPopup = %LandmarkPopup

var _toast_tween: Tween
var _travel_destination := ""


func _ready() -> void:
	add_to_group(&"game_hud")
	var touch := DisplayServer.is_touchscreen_available() or DebugTools.touch_ui
	_touch_available = touch
	_touch_controls.visible = touch
	if touch:
		_action_name = "кнопку"

	GameState.money_changed.connect(func(_m: int) -> void:
		Sfx.play(&"coins", -4.0)
		_refresh_wallet())
	GameState.inventory_changed.connect(_refresh_wallet)
	GameState.gear_changed.connect(_refresh_gear)
	GameState.journey_changed.connect(_refresh_journey)
	GameState.supplies_changed.connect(_refresh_bait)
	%BaitButton.pressed.connect(GameState.toggle_bait)
	GameState.milestone_reached.connect(func(title: String, reward: int) -> void:
		toast("%s! +%d монет" % [title, reward]))
	GameState.order_completed.connect(func(order: Dictionary) -> void:
		toast("Заказ выполнен: %s, +%d монет" % [order["giver"], int(order["reward"])]))
	_sell_button.pressed.connect(_on_sell_pressed)
	_shop_button.pressed.connect(_open_shop)
	_travel_button.pressed.connect(travel_requested.emit)
	%SailButton.pressed.connect(sailing_requested.emit)
	%CollectionButton.pressed.connect(_toggle_collection)
	_catch_popup.closed.connect(_on_catch_popup_closed)
	_collection.fish_selected.connect(_inspect_fish)
	_collection.landmark_selected.connect(_inspect_landmark_entry)
	%LandmarkButton.pressed.connect(landmark_requested.emit)
	_landmark_popup.closed.connect(_on_landmark_closed)
	_sell_button.icon = load("res://assets/ui/fish.svg")
	%CollectionButton.icon = load("res://assets/ui/book.svg")
	_shop_button.icon = load("res://assets/ui/chat.svg")
	_travel_button.icon = load("res://assets/ui/compass.svg")
	%CoinIcon.texture = load("res://assets/ui/coin.svg")
	var heading := FontVariation.new()
	heading.base_font = ThemeDB.fallback_font
	heading.variation_embolden = 0.4
	_money_label.add_theme_font_override("font", heading)

	_charge_bar.hide()
	_fight_panel.hide()
	_toast_label.modulate.a = 0.0
	_shop_button.hide()
	_travel_button.hide()
	_travel_fade.hide()
	%ModalShade.hide()
	%SailButton.hide()
	%SailStatus.hide()
	%LandmarkButton.hide()
	_refresh_wallet()
	_refresh_gear()
	_refresh_journey()
	_refresh_bait()


func _refresh_bait() -> void:
	%BaitButton.visible = GameState.bait_charges > 0 and not _fishing_focus
	%BaitButton.text = "Приманка: %s (%d)" % ["ВКЛ" if GameState.bait_enabled else "ВЫКЛ", GameState.bait_charges]


func _refresh_journey() -> void:
	var goal := GameState.next_goal()
	if goal.is_empty():
		%JourneyHint.text = "Путь рыболова завершён!\nОхоться за новыми рекордами."
		return
	%JourneyHint.text = "%s · %d/%d · +%d монет\n%s" % [goal["title"],
		mini(GameState.journey_progress(goal["metric"]), int(goal["target"])),
		int(goal["target"]), int(goal["reward"]), goal["hint"]]


func set_biome(biome: BiomeData) -> void:
	_biome_label.text = biome.display_name
	_biome_label.modulate = Color.WHITE


func set_travel_available(destination_name: String, locked := false) -> void:
	_travel_destination = destination_name
	_travel_button.text = "%s%s" % [destination_name, " · нужна лодка Луки" if locked else " · плыть"]
	_travel_button.tooltip_text = "Улучши лодку у Луки за %d монет" % GameState.BOAT.price if locked else "Отправиться в путешествие"
	_travel_button.show()


func clear_travel_available(destination_name: String) -> void:
	if _travel_destination == destination_name:
		_travel_button.hide()


func fade_out(message: String) -> void:
	_travel_label.text = message
	_travel_fade.modulate.a = 0.0
	_travel_fade.show()
	var tween := create_tween()
	tween.tween_property(_travel_fade, "modulate:a", 1.0, 0.35)
	await tween.finished


func fade_in() -> void:
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(_travel_fade, "modulate:a", 0.0, 0.35)
	await tween.finished
	_travel_fade.hide()


func _process(_delta: float) -> void:
	_clock_label.text = "%s · %s" % [WorldClock.clock_text(), WorldClock.phase_name()]
	_touch_controls.visible = _touch_available and not is_modal_open()
	%SailButton.visible = _sailing_available and not _fishing_focus and not is_modal_open()
	%SailStatus.visible = _sailing_active and not _fishing_focus and not is_modal_open()
	_hint_label.visible = not is_modal_open() and not _hint_label.text.is_empty()
	%ModalShade.visible = _shop.visible or _collection.visible or _catch_popup.visible or _landmark_popup.visible
	%LandmarkButton.visible = _nearby_landmark != null and not _fishing_focus and not is_modal_open()


func set_fishing_focus(active: bool) -> void:
	_fishing_focus = active
	%OrdersTracker.visible = not active and not _sailing_active
	%JourneyHint.visible = not active and not _sailing_active
	_refresh_bait()
	%SailButton.visible = _sailing_available and not active
	%SailStatus.visible = _sailing_active and not active


func set_sailing_available(available: bool, text := "На воду · B") -> void:
	_sailing_available = available
	%SailButton.text = text.replace(" · B / E", "").replace(" · B", "") if _touch_available else text
	if not _touch_available and not Input.get_connected_joypads().is_empty():
		%SailButton.text = text.replace(" · B / E", " · Y / X").replace(" · B", " · Y")
	%SailButton.visible = available and not _fishing_focus


func set_sailing_mode(active: bool) -> void:
	_sailing_active = active
	%OrdersTracker.visible = not active and not _fishing_focus
	%JourneyHint.visible = not active and not _fishing_focus
	%SailStatus.visible = active and not _fishing_focus
	if active:
		_travel_button.hide()


func set_sailing_status(text: String) -> void:
	%SailStatus.text = text


func show_sailing_hint(blocked: bool) -> void:
	if blocked:
		set_hint("Здесь мелко или сильное течение · держись открытой воды вокруг острова")
	elif _touch_available:
		set_hint("Джойстик — плыть · остановись и забрасывай · у берега нажми «Причалить»")
	elif not Input.get_connected_joypads().is_empty():
		set_hint("Стик — плыть · A — заброс · Y / X у причала — на берег")
	else:
		set_hint("WASD — плыть · Пробел — заброс · B / E у причала — на берег")


func _unhandled_input(event: InputEvent) -> void:
	if _travel_fade.visible:
		return
	if event.is_action_pressed(&"interact") and %LandmarkButton.visible:
		landmark_requested.emit()
	elif (event.is_action_pressed(&"sail_action") or (_sailing_active and event.is_action_pressed(&"interact"))) and %SailButton.visible:
		sailing_requested.emit()
	elif event.is_action_pressed(&"toggle_collection"):
		_toggle_collection()
	elif event.is_action_pressed(&"interact") and _shop_button.visible:
		if _shop.visible:
			_shop.hide()
		else:
			_open_shop()
	elif event.is_action_pressed(&"interact") and _travel_button.visible:
		travel_requested.emit()


func is_modal_open() -> bool:
	return _collection.visible or _catch_popup.visible or _shop.visible or _travel_fade.visible or _landmark_popup.visible


func set_landmark_available(data: LandmarkData) -> void:
	_nearby_landmark = data
	%LandmarkButton.text = "Осмотреть" if _touch_available else ("Осмотреть · X" if not Input.get_connected_joypads().is_empty() else "Осмотреть · E")


func clear_landmark_available(data: LandmarkData) -> void:
	if _nearby_landmark == data:
		_nearby_landmark = null


func show_landmark(data: LandmarkData, is_new: bool) -> void:
	_landmark_popup.open(data, is_new)


func _inspect_landmark_entry(data: LandmarkData) -> void:
	if not _collection.visible or String(data.id) not in GameState.discovered_landmarks:
		return
	_return_from_landmark = true
	_collection.hide()
	_landmark_popup.open(data, false)


func _on_landmark_closed() -> void:
	if _return_from_landmark:
		_return_from_landmark = false
		_collection.show()


## Игрок подошёл к прилавку или отошёл от него.
func set_shop_available(available: bool) -> void:
	_shop_button.visible = available
	if not available:
		_shop.hide()


## {action} в тексте заменяется на «Пробел» или «кнопку» в зависимости от устройства.
func set_hint(text: String) -> void:
	_hint_label.text = text.format({"action": _action_name})


func show_idle_hint() -> void:
	if _touch_available:
		set_hint("Зажми «ЗАБРОС», затем отпусти")
	elif not Input.get_connected_joypads().is_empty():
		set_hint("A / Cross — заброс · X — разговор · Start — пауза")
	else:
		set_hint("Удерживай Пробел — заброс · C — коллекция · Esc — пауза")


func toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func show_charge(power: float) -> void:
	_charge_bar.show()
	_charge_bar.value = power


func hide_charge() -> void:
	_charge_bar.hide()


func show_fight() -> void:
	_fight_panel.show()


func hide_fight() -> void:
	_fight_panel.hide()
	%FightReadout.session = null


func update_fight(session: FishingSession) -> void:
	_tension_meter.tension = session.tension
	_tension_meter.thrashing = session.is_thrashing
	_tension_meter.control = session.control
	%FightReadout.session = session
	%FightReadout.to_boat = _sailing_active
	%FightReadout.queue_redraw()
	var status := "Подматывай · светлая зона даёт бонус контроля"
	var color := Color("#ede6cc")
	if session.tension >= TensionMeter.DANGER_FROM:
		status = "ОТПУСТИ · леска на пределе!"
		color = Color("#edaa8e")
	elif session.tension <= FishingSession.SLACK_TENSION:
		status = "ПОДМАТЫВАЙ · не дай леске провиснуть"
	elif session.is_thrashing:
		status = "РЫВОК · дай рыбе выдохнуться"
		color = Color("#edc684")
	elif session.is_telegraphing():
		status = "Готовится рывок · будь готов отпустить"
		color = Color("#edc684")
	elif session.control >= 0.8:
		status = "ХОРОШИЙ КОНТРОЛЬ · подмотка +%d%%" % roundi(session.control * FishingSession.CONTROL_REEL_BONUS * 100)
		color = Color("#cadd9e")
	_fight_status.text = status
	_fight_status.modulate = color


func show_catch(fish: FishData, weight_kg: float, is_new: bool) -> void:
	_catch_popup.open(fish, weight_kg, is_new)


func close_catch_popup() -> void:
	_catch_popup.close()


func _inspect_fish(fish: FishData) -> void:
	if not _collection.visible:
		return
	var entry: Dictionary = GameState.collection.get(String(fish.id), {})
	if entry.is_empty():
		return
	_return_to_collection = true
	_collection.hide()
	_catch_popup.inspect(fish, entry)


func _on_catch_popup_closed() -> void:
	if _return_to_collection:
		_return_to_collection = false
		_collection.show()
	else:
		catch_popup_closed.emit()


func _refresh_wallet() -> void:
	_money_label.text = "%d монет" % GameState.money
	var count := GameState.inventory.size()
	_sell_button.text = "Продать улов (%d)" % count
	_sell_button.disabled = count == 0


func _refresh_gear() -> void:
	_gear_label.text = GameState.gear.display_name


func _open_shop() -> void:
	if _catch_popup.visible or _landmark_popup.visible:
		return
	var controller := get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	if controller and controller.phase != FishingController.Phase.IDLE:
		return
	_collection.hide()
	_shop.open()


func _toggle_collection() -> void:
	if _landmark_popup.visible:
		var return_to_journal := _return_from_landmark
		_landmark_popup.close()
		if not return_to_journal:
			_collection.toggle()
		return
	if _return_to_collection:
		_catch_popup.close()
		return
	var controller := get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	if controller and controller.phase != FishingController.Phase.IDLE:
		return
	_shop.hide()
	_collection.toggle()


func _on_sell_pressed() -> void:
	var earned := GameState.sell_all()
	toast("Улов продан: +%d монет" % earned)
