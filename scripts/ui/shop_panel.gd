class_name ShopPanel
extends PanelContainer
## Магазин снастей: купить или надеть удочку.

@onready var _money_label: Label = %ShopMoney
@onready var _list: VBoxContainer = %ShopList
@onready var _greeting: Label = %LukaGreeting

var _show_orders := false
var _show_supplies := false


func _ready() -> void:
	hide()
	%ShopCloseButton.pressed.connect(hide)
	GameState.money_changed.connect(func(_m: int) -> void: _refresh_if_visible())
	GameState.gear_changed.connect(_refresh_if_visible)
	GameState.orders_changed.connect(_refresh_if_visible)
	GameState.supplies_changed.connect(_refresh_if_visible)
	%LukaGearButton.pressed.connect(_set_orders.bind(false))
	%LukaOrdersButton.pressed.connect(_set_orders.bind(true))
	%LukaSuppliesButton.pressed.connect(func() -> void:
		_show_supplies = true
		_show_orders = false
		_rebuild())


func open() -> void:
	_show_orders = false
	_show_supplies = false
	_rebuild()
	show()


func _set_orders(value: bool) -> void:
	_show_supplies = false
	_show_orders = value
	_rebuild()


func _refresh_if_visible() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	_money_label.text = "Монеты: %d" % GameState.money
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_greeting.text = "Лука: Соседи оставили заказы. Награду получишь сразу после поимки — рыба останется у тебя." if _show_orders else "Лука: Рад тебя видеть! Подберём удочку? За сильной рыбой лучше идти с хорошей снастью."
	%LukaGearButton.disabled = not _show_orders and not _show_supplies
	%LukaOrdersButton.disabled = _show_orders
	%LukaSuppliesButton.disabled = _show_supplies
	if _show_supplies:
		_greeting.text = "Лука: Для редкой рыбы возьми смесь. А карта отмелей поможет искать удачные места в манграх."
		_list.add_child(_make_offer(GameState.BAIT.display_name, GameState.BAIT.description,
				"Купить: %d" % GameState.BAIT.price, GameState.money < GameState.BAIT.price, GameState.buy_bait))
		_list.add_child(_make_offer(GameState.BOAT.display_name, GameState.BOAT.description,
				"Улучшено" if GameState.boat_upgraded else "Улучшить: %d" % GameState.BOAT.price,
				GameState.boat_upgraded or GameState.money < GameState.BOAT.price, GameState.upgrade_boat))
		return
	if _show_orders:
		for order in GameState.orders.orders:
			_list.add_child(_make_order(order))
		return
	for rod in GameState.gear_catalog.rods:
		_list.add_child(_make_row(rod))


func _make_offer(title: String, description: String, action: String, disabled: bool, callback: Callable) -> Control:
	var box := VBoxContainer.new()
	for text in [title, description]:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	var button := Button.new()
	button.text = action
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	box.add_child(button)
	return box


func _make_order(order: Dictionary) -> Control:
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = OrderBook.describe(order, GameState.catalog)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var fish := GameState.catalog.get_fish(StringName(order["fish_id"]))
	var info := Label.new()
	info.text = "Награда: %d монет · %s\nКлюёт: %s" % [int(order["reward"]),
			"Родное озеро" if &"lake" in fish.habitats else "Мангровые отмели", DayTime.describe(fish.active_times)]
	info.add_theme_font_size_override("font_size", 18)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	return box


func _make_row(rod: GearStats) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var title := Label.new()
	title.text = rod.display_name
	info.add_child(title)

	for line in [rod.description, rod.stats_text()]:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 16)
		info.add_child(label)

	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(170, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if GameState.equipped_gear_id == String(rod.id):
		button.text = "Надета"
		button.disabled = true
	elif GameState.owns_gear(rod.id):
		button.text = "Надеть"
		button.pressed.connect(GameState.equip_gear.bind(rod))
	else:
		button.text = "Купить: %d" % rod.price
		button.disabled = GameState.money < rod.price
		button.pressed.connect(GameState.buy_gear.bind(rod))
	row.add_child(button)
	return row
