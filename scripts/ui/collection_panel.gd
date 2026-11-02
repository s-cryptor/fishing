class_name CollectionPanel
extends PanelContainer
## Энциклопедия видов: непойманные показаны силуэтом «???».

const UNKNOWN_COLOR := Color("#1b2633")

signal fish_selected(fish: FishData)

@onready var _header: Label = %CollectionHeader
@onready var _grid: GridContainer = %CollectionGrid

var _habitat: StringName = &"lake"


func _ready() -> void:
	hide()
	%CloseButton.pressed.connect(hide)
	var tabs := HBoxContainer.new()
	$VBox.add_child(tabs)
	$VBox.move_child(tabs, 1)
	var pages: Array = []
	var group := ButtonGroup.new()
	for biome in GameState.BIOMES.biomes:
		pages.append([biome.display_name, biome.habitat])
	pages.append(["Путь рыболова", &"journey"])
	for pair in pages:
		var button := Button.new()
		button.text = pair[0]
		button.add_theme_font_size_override("font_size", 16)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = pair[1] == _habitat
		button.pressed.connect(func() -> void:
			_habitat = pair[1]
			_rebuild())
		tabs.add_child(button)


func toggle() -> void:
	if visible:
		hide()
	else:
		_rebuild()
		show()


func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if _habitat == &"journey":
		_rebuild_journey()
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


func _make_card(fish: FishData, entry: Dictionary) -> Control:
	var caught := not entry.is_empty()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 250)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#20443e") if caught else Color("#193a35")
	background.set_corner_radius_all(10)
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
	return panel
