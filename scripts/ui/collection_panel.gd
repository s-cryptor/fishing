class_name CollectionPanel
extends PanelContainer
## Энциклопедия видов: непойманные показаны силуэтом «???».

const UNKNOWN_COLOR := Color("#1b2633")

@onready var _header: Label = %CollectionHeader
@onready var _grid: GridContainer = %CollectionGrid


func _ready() -> void:
	hide()
	%CloseButton.pressed.connect(hide)


func toggle() -> void:
	if visible:
		hide()
	else:
		_rebuild()
		show()


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var catalog := GameState.catalog
	var known := 0
	for fish in catalog.fish:
		var entry: Dictionary = GameState.collection.get(String(fish.id), {})
		if not entry.is_empty():
			known += 1
		_grid.add_child(_make_card(fish, entry))
	_header.text = "Коллекция видов: %d / %d" % [known, catalog.fish.size()]


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
	return box
