class_name CollectionPanel
extends PanelContainer
## Энциклопедия видов: непойманные показаны силуэтом «???».

const UNKNOWN_COLOR := Color("#1b2633")

signal fish_selected(fish: FishData)
signal landmark_selected(data: LandmarkData)
signal message_selected(data: DriftMessageData)

@onready var _header: Label = %CollectionHeader
@onready var _grid: GridContainer = %CollectionGrid

var _habitat: StringName = &"lake"


func _ready() -> void:
	hide()
	GameState.fishing_target_changed.connect(_refresh_target_buttons)
	ModalFocus.watch(self)
	%CloseButton.pressed.connect(hide)
	var tabs := HBoxContainer.new()
	$VBox.add_child(tabs)
	$VBox.move_child(tabs, 1)
	var pages: Array = []
	var group := ButtonGroup.new()
	for biome in GameState.BIOMES.biomes:
		pages.append([biome.display_name, biome.habitat])
	pages.append(["Путь рыболова", &"journey"])
	pages.append(["Открытия", &"landmarks"])
	pages.append(["Письма", &"messages"])
	for pair in pages:
		var button := Button.new()
		button.text = pair[0]
		button.add_theme_font_size_override("font_size", 15)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = pair[1] == _habitat
		button.set_meta(&"page", pair[1])
		_style_tab(button)
		button.toggled.connect(func(_pressed: bool) -> void: _tab_colors(button))
		button.pressed.connect(func() -> void:
			_habitat = pair[1]
			_rebuild())
		tabs.add_child(button)


func _style_tab(button: Button) -> void:
	var normal := get_theme_stylebox("normal", "Button").duplicate() as StyleBoxFlat
	normal.bg_color = Color("#31564b")
	var hover := get_theme_stylebox("hover", "Button").duplicate() as StyleBoxFlat
	hover.bg_color = Color("#3c6053")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_pressed_color", Color("#21473f"))
	_tab_colors(button)


func _tab_colors(button: Button) -> void:
	var color := Color("#21473f") if button.button_pressed else Color("#dce6ce")
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(state, color)


func toggle() -> void:
	if visible:
		hide()
	else:
		_rebuild()
		show()


func reveal_fish(fish: FishData) -> void:
	if fish == null or fish.habitats.is_empty():
		return
	if _habitat not in fish.habitats:
		_habitat = fish.habitats[0]
	for button: Button in $VBox.get_child(1).get_children():
		button.button_pressed = button.get_meta(&"page") == _habitat
	_rebuild()
	show()
	_focus_fish(fish.id)


func _focus_fish(id: StringName) -> void:
	# Контейнеру нужен кадр, чтобы вычислить положение карточек после смены вкладки.
	await get_tree().process_frame
	if not is_visible_in_tree():
		return
	for button: Button in _grid.find_children("TrackFishButton", "Button", true, false):
		if button.get_meta(&"fish_id") == String(id):
			button.grab_focus()
			$VBox/Scroll.ensure_control_visible(button)
			return


func _rebuild() -> void:
	ModalFocus.restore.call_deferred(self)
	_grid.columns = 3
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if _habitat == &"journey":
		_rebuild_journey()
		return
	if _habitat == &"landmarks":
		_rebuild_landmarks()
		return
	if _habitat == &"messages":
		_rebuild_messages()
		return
	var catalog := GameState.catalog
	var known := 0
	var pool := catalog.for_habitat(_habitat)
	for fish in pool:
		var entry: Dictionary = GameState.collection.get(String(fish.id), {})
		if not entry.is_empty():
			known += 1
		_grid.add_child(_make_card(fish, entry))
	_header.text = "%s: %d / %d" % [GameState.BIOMES.for_habitat(_habitat).display_name, known, pool.size()]


func _rebuild_journey() -> void:
	_header.text = "Путь рыболова: %d / %d" % [GameState.claimed_goals.size(), GameState.JOURNEY.goals.size()]
	for goal in GameState.JOURNEY.goals:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(190, 0)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		var done: bool = goal["id"] in GameState.claimed_goals
		title.text = goal["title"]
		title.add_theme_font_size_override("font_size", 18)
		title.modulate = Color("#a5db91") if done else Color("#ffe0a0")
		box.add_child(title)
		var info := Label.new()
		info.text = "%s\n%s\nНаграда: %d монет" % [
			"Выполнено" if done else "%d / %d" % [mini(GameState.journey_progress(goal["metric"]), int(goal["target"])), int(goal["target"])], goal["hint"], int(goal["reward"])]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_theme_font_size_override("font_size", 16)
		box.add_child(info)
		_grid.add_child(box)


func _rebuild_landmarks() -> void:
	_grid.columns = 3
	_header.text = "Открытия: %d / %d" % [GameState.discovered_landmarks.size(), GameState.LANDMARKS.landmarks.size()]
	for data in GameState.LANDMARKS.landmarks:
		var known := String(data.id) in GameState.discovered_landmarks
		_grid.add_child(_journal_card(data.title if known else "Неизвестное место", data.habitat, data.clue,
			known, landmark_selected.emit.bind(data)))


func _rebuild_messages() -> void:
	_grid.columns = 3
	_header.text = "Письма смотрителя: %d / %d · награда — флажок" % [GameState.found_messages.size(), GameState.MESSAGES.messages.size()]
	for data in GameState.MESSAGES.messages:
		var known := String(data.id) in GameState.found_messages
		_grid.add_child(_journal_card(data.title if known else "Письмо в пути", data.habitat, data.clue,
			known, message_selected.emit.bind(data)))


func _journal_card(heading: String, habitat: StringName, clue: String, known: bool, read: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 240)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#20443e") if known else Color("#193a35")
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = heading
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var text := Label.new()
	text.text = "%s\n\n%s" % [GameState.BIOMES.for_habitat(habitat).display_name, clue]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	box.add_child(text)
	if known:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(spacer)
		var button := Button.new()
		button.name = "ReadEntryButton"
		button.text = "Читать запись"
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(read)
		box.add_child(button)
	return panel


func _refresh_target_buttons() -> void:
	for button: Button in _grid.find_children("TrackFishButton", "Button", true, false):
		var id := str(button.get_meta(&"fish_id"))
		var selected := GameState.fishing_target_id == id
		button.text = "Снять цель" if selected else ("Искать трофей" if GameState.collection.has(id) else "Искать этот вид")
		button.tooltip_text = "Отменить личную цель" if selected else "Закрепить биом и время клёва на экране. Шансы поимки не меняются."
		# Рамка выделяет цель отдельно от редкости и клавиатурного фокуса.
		var card := button.get_parent().get_parent() as PanelContainer
		var style := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.set_border_width_all(2 if selected else 1)
		style.border_color = Color("#e3bc6b") if selected else button.get_meta(&"border_color")
		card.add_theme_stylebox_override("panel", style)


func _make_card(fish: FishData, entry: Dictionary) -> Control:
	var caught := not entry.is_empty()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 250)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#20443e") if caught else Color("#193a35")
	background.set_corner_radius_all(10)
	background.set_border_width_all(1)
	background.border_color = fish.rarity_color().darkened(0.45) if caught else Color(0.42, 0.55, 0.46, 0.2)
	background.content_margin_left = 10
	background.content_margin_right = 10
	background.content_margin_top = 10
	background.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", background)
	var box := VBoxContainer.new()
	panel.add_child(box)

	var swatch := FishPortrait.new()
	swatch.custom_minimum_size = Vector2(0, 72)
	swatch.fish = fish
	swatch.discovered = caught
	box.add_child(swatch)

	var name_label := Label.new()
	name_label.text = fish.display_name if caught else "???"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 18)
	box.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = fish.rarity_name()
	rarity_label.modulate = fish.rarity_color()
	rarity_label.add_theme_font_size_override("font_size", 16)
	box.add_child(rarity_label)

	if caught:
		var stats := Label.new()
		stats.text = "Поймано: %d\nРекорд: %.2f кг\nКлюёт: %s" % [
			int(entry["count"]), float(entry["best_kg"]), DayTime.describe(fish.active_times)]
		stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_theme_font_size_override("font_size", 16)
		box.add_child(stats)
		if GameState.is_trophy(fish, float(entry["best_kg"])):
			var trophy := Label.new()
			trophy.text = "Золотой трофей"
			trophy.add_theme_font_size_override("font_size", 16)
			trophy.modulate = Color("#ffd578")
			box.add_child(trophy)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(spacer)
		var inspect := Button.new()
		inspect.name = "InspectButton"
		inspect.text = "Рассмотреть"
		inspect.focus_mode = Control.FOCUS_NONE
		inspect.add_theme_font_size_override("font_size", 16)
		inspect.pressed.connect(fish_selected.emit.bind(fish))
		box.add_child(inspect)
	else:
		var clue := Label.new()
		clue.text = "Клюёт: %s" % DayTime.describe(fish.active_times)
		clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clue.add_theme_font_size_override("font_size", 16)
		box.add_child(clue)
	var track := Button.new()
	track.name = "TrackFishButton"
	track.add_theme_font_size_override("font_size", 16)
	track.set_meta(&"fish_id", String(fish.id))
	track.set_meta(&"border_color", background.border_color)
	track.text = "Снять цель" if GameState.fishing_target_id == String(fish.id) else ("Искать трофей" if caught else "Искать этот вид")
	track.tooltip_text = "Закрепить личную цель на экране; шансы поимки не меняются"
	track.pressed.connect(func() -> void:
		if GameState.fishing_target_id == String(fish.id):
			GameState.clear_fishing_target()
		else:
			GameState.track_fish(fish.id))
	box.add_child(track)
	if GameState.fishing_target_id == String(fish.id):
		background.set_border_width_all(2)
		background.border_color = Color("#e3bc6b")
	return panel
