class_name OrdersTracker
extends PanelContainer
## Компактный список активных заказов в углу экрана.

@onready var _list: VBoxContainer = %OrdersList


func _ready() -> void:
	GameState.orders_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for order in GameState.orders.orders:
		var label := Label.new()
		label.text = OrderBook.describe(order, GameState.catalog)
		label.add_theme_font_size_override("font_size", 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var reward := Label.new()
		reward.text = "   награда %d" % int(order["reward"])
		reward.add_theme_font_size_override("font_size", 14)
		reward.modulate = Color(1.0, 0.88, 0.4)
		_list.add_child(label)
		_list.add_child(reward)
