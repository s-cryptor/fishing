class_name CookingPanel
extends PanelContainer
## Игрок заранее видит конкретный улов и цену, от которых отказывается ради блюда.

signal meal_prepared(meal: MealData)
var _list: VBoxContainer
var _greeting: Label
var _active: Label


func _ready() -> void:
	hide()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Марта · походная кухня"
	title.add_theme_font_size_override("font_size", 27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "KitchenCloseButton"
	close.text = "Закрыть"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	header.add_child(close)
	_greeting = Label.new()
	_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_greeting.add_theme_font_size_override("font_size", 17)
	box.add_child(_greeting)
	_active = Label.new()
	_active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active.add_theme_font_size_override("font_size", 16)
	_active.modulate = Color("#ddc589")
	box.add_child(_active)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 330
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_list)
	GameState.inventory_changed.connect(_refresh_if_visible)
	GameState.supplies_changed.connect(_refresh_if_visible)


func open() -> void:
	_rebuild()
	show()


func _refresh_if_visible() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_greeting.text = "Марта: Редкий улов я не трогаю. А из обычного приготовим что-нибудь тёплое в дорогу. Рекорды останутся в журнале."
	var active := GameState.active_meal()
	_active.text = "%s · ещё %s. Новое блюдо — когда закончится эффект." % [active.display_name, MealData.casts_text(GameState.meal_charges)] if active else "Одно блюдо за раз · эффект тратится только при успешном забросе в воду"
	for meal in GameState.MEALS.meals:
		_list.add_child(_make_recipe(meal))


func _make_recipe(meal: MealData) -> Control:
	var panel := PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#20443e")
	background.set_corner_radius_all(10)
	background.content_margin_left = 12
	background.content_margin_right = 12
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", background)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var portrait := MealPortrait.new()
	portrait.custom_minimum_size = Vector2(76, 80)
	portrait.meal = meal
	portrait.tooltip_text = meal.description
	row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	var title := Label.new()
	title.text = meal.display_name
	title.tooltip_text = meal.description
	title.add_theme_font_size_override("font_size", 21)
	box.add_child(title)
	var effect := Label.new()
	effect.text = meal.effect_text()
	effect.add_theme_font_size_override("font_size", 16)
	effect.modulate = Color("#d8c387")
	box.add_child(effect)
	var ingredients := Label.new()
	ingredients.name = "Ingredients"
	ingredients.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ingredients.add_theme_font_size_override("font_size", 16)
	var selected := GameState.cooking_selection(meal)
	ingredients.text = "Рецепт: %s · есть %d/%d" % [meal.ingredient_label, selected.size(), meal.ingredient_count]
	if selected.size() == meal.ingredient_count:
		var names: Array[String] = []
		var value := 0
		for index in selected:
			var item := GameState.inventory[index]
			var fish := GameState.catalog.get_fish(StringName(item["fish_id"]))
			names.append("%s %.2f кг" % [fish.display_name, float(item["weight_kg"])])
			value += fish.value_for(float(item["weight_kg"]))
		ingredients.text = "В блюдо: %s\nВместо продажи: %d монет" % [", ".join(names), value]
	box.add_child(ingredients)
	var button := Button.new()
	button.name = "CookButton"
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	var error := GameState.cooking_error(meal)
	button.text = "Приготовить" if error.is_empty() else error
	button.disabled = not error.is_empty()
	button.pressed.connect(func() -> void:
		if GameState.cook_meal(meal.id):
			meal_prepared.emit(meal)
		else:
			_rebuild())
	box.add_child(button)
	return panel
