class_name Hud
extends CanvasLayer

signal catch_popup_closed

var _action_name := "Пробел"

@onready var _money_label: Label = %MoneyLabel
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

var _toast_tween: Tween


func _ready() -> void:
	var touch := DisplayServer.is_touchscreen_available() or DebugTools.touch_ui
	_touch_controls.visible = touch
	if touch:
		_action_name = "кнопку"

	GameState.money_changed.connect(func(_m: int) -> void: _refresh_wallet())
	GameState.inventory_changed.connect(_refresh_wallet)
	_sell_button.pressed.connect(_on_sell_pressed)
	%CollectionButton.pressed.connect(_collection.toggle)
	_catch_popup.closed.connect(catch_popup_closed.emit)

	_charge_bar.hide()
	_fight_panel.hide()
	_toast_label.modulate.a = 0.0
	_refresh_wallet()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_collection"):
		_collection.toggle()


func is_modal_open() -> bool:
	return _collection.visible or _catch_popup.visible


## {action} в тексте заменяется на «Пробел» или «кнопку» в зависимости от устройства.
func set_hint(text: String) -> void:
	_hint_label.text = text.format({"action": _action_name})


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


func update_fight(session: FishingSession) -> void:
	_tension_meter.tension = session.tension
	_tension_meter.thrashing = session.is_thrashing
	_fight_status.text = "%s  ·  %.1f м  ·  силы рыбы %d%%" % [
		"РЫВОК!" if session.is_thrashing else "Тянет",
		session.distance, roundi(session.stamina_ratio() * 100.0)]


func show_catch(fish: FishData, weight_kg: float, is_new: bool) -> void:
	_catch_popup.open(fish, weight_kg, is_new)


func close_catch_popup() -> void:
	_catch_popup.close()


func _refresh_wallet() -> void:
	_money_label.text = "Монеты: %d" % GameState.money
	var count := GameState.inventory.size()
	_sell_button.text = "Продать улов (%d)" % count
	_sell_button.disabled = count == 0


func _on_sell_pressed() -> void:
	var earned := GameState.sell_all()
	toast("Улов продан: +%d монет" % earned)
