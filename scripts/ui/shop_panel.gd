class_name ShopPanel
extends PanelContainer
## Магазин снастей: купить или надеть удочку.

@onready var _money_label: Label = %ShopMoney
@onready var _list: VBoxContainer = %ShopList


func _ready() -> void:
	hide()
	%ShopCloseButton.pressed.connect(hide)
	GameState.money_changed.connect(func(_m: int) -> void: _refresh_if_visible())
	GameState.gear_changed.connect(_refresh_if_visible)


func open() -> void:
	_rebuild()
	show()


func _refresh_if_visible() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	_money_label.text = "Монеты: %d" % GameState.money
	for child in _list.get_children():
		child.queue_free()
	for rod in GameState.gear_catalog.rods:
		_list.add_child(_make_row(rod))


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
