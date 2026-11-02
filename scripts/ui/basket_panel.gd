class_name BasketPanel
extends PanelContainer
## Выбор продажи явный; смена садка сбрасывает индексы, чтобы не продать другой улов.

signal sold(value: int)
const PAGE_SIZE := 12

var _selected: Dictionary = {}
var _page := 0
var _list: VBoxContainer
var _summary: Label
var _selection: Label
var _sell: Button
var _page_label: Label
var _previous: Button
var _next: Button
var _scroll: ScrollContainer
var _checks: Dictionary = {}


func _ready() -> void:
	hide()
	ModalFocus.watch(self, &"SelectCommonButton")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Твой садок"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_add_button(header, "Закрыть", &"BasketCloseButton", hide)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 17)
	box.add_child(_summary)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	box.add_child(tools)
	_add_button(tools, "Обычный улов", &"SelectCommonButton", select_common).tooltip_text = "Отметить обычную рыбу, не включая необычные и редкие виды"
	_add_button(tools, "Оставить для ухи", &"KeepSoupButton", select_except_soup).tooltip_text = "Отметить обычную рыбу, кроме двух самых недорогих ингредиентов. Редкие виды не отмечаются."
	_add_button(tools, "Всё", &"SelectAllButton", select_all)
	_add_button(tools, "Снять выбор", &"ClearSelectionButton", clear_selection)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size.y = 220
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list)
	var pages := HBoxContainer.new()
	pages.alignment = BoxContainer.ALIGNMENT_CENTER
	pages.add_theme_constant_override("separation", 16)
	box.add_child(pages)
	_previous = _add_button(pages, "← Назад", &"PreviousPageButton", _turn_page.bind(-1))
	_page_label = Label.new()
	_page_label.add_theme_font_size_override("font_size", 16)
	pages.add_child(_page_label)
	_next = _add_button(pages, "Дальше →", &"NextPageButton", _turn_page.bind(1))
	_selection = Label.new()
	_selection.add_theme_font_size_override("font_size", 16)
	box.add_child(_selection)
	_sell = _add_button(box, "Продать выбранное", &"BasketSellButton", _sell_selected)
	GameState.inventory_changed.connect(_inventory_changed)


func open() -> void:
	_selected.clear()
	_page = 0
	_rebuild()
	show()


func _inventory_changed() -> void:
	_selected.clear()
	if visible:
		_rebuild()


func _rebuild() -> void:
	_checks.clear()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var count := GameState.inventory.size()
	_summary.text = "В садке: %d · весь улов: %d монет · рекорды останутся в коллекции" % [count, GameState.inventory_value()]
	_page = clampi(_page, 0, maxi(0, ceili(float(count) / PAGE_SIZE) - 1))
	for index in range(_page * PAGE_SIZE, mini(count, (_page + 1) * PAGE_SIZE)):
		_list.add_child(_make_row(index))
	if count == 0:
		var empty := Label.new()
		empty.text = "Садок пока пуст.\nПопробуй забросить в золотое кольцо стаи."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(empty)
	_previous.disabled = _page == 0
	_next.disabled = (_page + 1) * PAGE_SIZE >= count
	_page_label.text = "%d / %d" % [_page + 1, maxi(1, ceili(float(count) / PAGE_SIZE))]
	_refresh_selection()
	ModalFocus.restore.call_deferred(self, &"SelectCommonButton")


func _make_row(index: int) -> Control:
	var item := GameState.inventory[index]
	var fish := GameState.catalog.get_fish(StringName(item["fish_id"]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var check := CheckBox.new()
	check.name = "SelectFish%d" % index
	check.button_pressed = _selected.has(index)
	check.text = ""
	check.custom_minimum_size = Vector2(48, 64)
	check.toggled.connect(func(selected: bool) -> void:
		if selected:
			_selected[index] = true
		else:
			_selected.erase(index)
		_refresh_selection())
	row.add_child(check)
	_checks[index] = check
	var portrait := FishPortrait.new()
	portrait.fish = fish
	portrait.custom_minimum_size = Vector2(72, 64)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title := Label.new()
	title.text = "%s · %.2f кг" % [fish.display_name, float(item["weight_kg"])]
	title.add_theme_font_size_override("font_size", 19)
	info.add_child(title)
	check.tooltip_text = "Выбрать: " + title.text
	var rarity := Label.new()
	rarity.text = fish.rarity_name() + (" · золотой трофей" if GameState.is_trophy(fish, float(item["weight_kg"])) else "")
	rarity.add_theme_font_size_override("font_size", 15)
	rarity.modulate = fish.rarity_color()
	info.add_child(rarity)
	var value := Label.new()
	value.text = "%d монет" % fish.value_for(float(item["weight_kg"]))
	value.add_theme_font_size_override("font_size", 18)
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value)
	return row


func _refresh_selection() -> void:
	var total := 0
	var special := 0
	for index: int in _selected:
		var item := GameState.inventory[index]
		var fish := GameState.catalog.get_fish(StringName(item["fish_id"]))
		total += fish.value_for(float(item["weight_kg"]))
		if fish.rarity > FishData.Rarity.COMMON:
			special += 1
	_selection.text = "Выбрано: %d · необычных и редких: %d · к продаже: %d монет" % [_selected.size(), special, total]
	_selection.modulate = Color("#edd08c") if special > 0 else Color("#c6d4c5")
	_sell.text = "Продать выбранное (%d) · +%d монет" % [_selected.size(), total]
	_sell.disabled = _selected.is_empty()
	for index: int in _checks:
		(_checks[index] as CheckBox).set_pressed_no_signal(_selected.has(index))


func select_common() -> void:
	_selected.clear()
	for index in GameState.inventory.size():
		var fish := GameState.catalog.get_fish(StringName(GameState.inventory[index]["fish_id"]))
		if fish.rarity == FishData.Rarity.COMMON:
			_selected[index] = true
	_refresh_selection()


func select_except_soup() -> void:
	# Быстрый выбор никогда не включает редкую рыбу; ингредиенты остаются в садке.
	select_common()
	for index in GameState.cooking_selection(GameState.MEALS.get_meal(&"fish_soup")):
		_selected.erase(index)
	_refresh_selection()


func select_all() -> void:
	_selected.clear()
	for index in GameState.inventory.size():
		_selected[index] = true
	_refresh_selection()


func clear_selection() -> void:
	_selected.clear()
	_refresh_selection()


func _turn_page(direction: int) -> void:
	_page += direction
	_scroll.scroll_vertical = 0
	_rebuild()


func _sell_selected() -> void:
	var indices: Array[int] = []
	for index: int in _selected:
		indices.append(index)
	var value := GameState.sell_selected(indices)
	if value > 0:
		sold.emit(value)


func _add_button(parent: Node, text: String, node_name: StringName, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
