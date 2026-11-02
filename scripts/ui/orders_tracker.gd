class_name OrdersTracker
extends PanelContainer
## Компактный список активных заказов в углу экрана.

@onready var _list: VBoxContainer = %OrdersList
var _expanded := false


func _ready() -> void:
	GameState.orders_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var orders := GameState.orders.orders
	for i in orders.size() if _expanded else mini(1, orders.size()):
		var order: Dictionary = orders[i]
		var label := Label.new()
		label.text = OrderBook.describe(order, GameState.catalog)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("#385047"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var reward := Label.new()
		reward.text = "+%d монет за заказ" % int(order["reward"])
		reward.add_theme_font_size_override("font_size", 14)
		reward.add_theme_color_override("font_color", Color("#937344"))
		_list.add_child(label)
		_list.add_child(reward)
	if orders.size() > 1:
		var button := Button.new()
		button.text = "Свернуть" if _expanded else "Ещё %d заказа" % (orders.size() - 1)
		button.add_theme_font_size_override("font_size", 14)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			_expanded = not _expanded
			_rebuild())
		_list.add_child(button)
