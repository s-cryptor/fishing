class_name CollectionPanel
extends PanelContainer
## Энциклопедия видов: непойманные показаны силуэтом «???».

const UNKNOWN_COLOR := Color("#1b2633")

@onready var _header: Label = %CollectionHeader
@onready var _grid: GridContainer = %CollectionGrid

var _habitat: StringName = &"lake"


func _ready() -> void:
	hide()
	%CloseButton.pressed.connect(hide)
	var tabs := HBoxContainer.new()
	$VBox.add_child(tabs)
	$VBox.move_child(tabs, 1)
	for pair in [["Родное озеро", &"lake"], ["Мангровые отмели", &"mangrove"], ["Путь рыболова", &"journey"]]:
		var button := Button.new()
		button.text = pair[0]
		button.focus_mode = Control.FOCUS_NONE
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
	_header.text = "%s: %d / %d" % ["Родное озеро" if _habitat == &"lake" else "Мангровые отмели", known, pool.size()]


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
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(190, 0)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 60)
	swatch.color = fish.color if caught else UNKNOWN_COLOR
	box.add_child(swatch)

	var name_label := Label.new()
	name_label.text = fish.display_name if caught else "???"
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
	else:
		var clue := Label.new()
		clue.text = "Клюёт: %s" % DayTime.describe(fish.active_times)
		clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clue.add_theme_font_size_override("font_size", 16)
		box.add_child(clue)
	return box
