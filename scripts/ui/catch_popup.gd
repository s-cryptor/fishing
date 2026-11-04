class_name CatchPopup
extends PanelContainer
## Карточка улова.

signal closed

@onready var _title: Label = %Title
@onready var _swatch: FishShowcase = %Swatch
@onready var _name: Label = %FishName
@onready var _rarity: Label = %Rarity
@onready var _stats: Label = %Stats
@onready var _description: Label = %Description
@onready var _scroll: ScrollContainer = %DescriptionScroll
var _open_tween: Tween


func _ready() -> void:
	hide()
	ModalFocus.watch(self, &"TakeButton")
	%TakeButton.pressed.connect(close)
	%TakeButton.focus_neighbor_top = %TakeButton.get_path_to(_scroll)
	_swatch.focus_neighbor_bottom = _swatch.get_path_to(_scroll)
	_scroll.focus_neighbor_top = _scroll.get_path_to(_swatch)
	_scroll.focus_neighbor_bottom = _scroll.get_path_to(%TakeButton)
	_scroll.focus_next = _scroll.get_path_to(%TakeButton)
	_scroll.gui_input.connect(_on_reader_input)


func _on_reader_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_page_down"):
		var bar := _scroll.get_v_scroll_bar()
		if _scroll.scroll_vertical >= bar.max_value - bar.page - 1:
			%TakeButton.grab_focus()
		else:
			_scroll.scroll_vertical += roundi(_scroll.size.y * 0.8) if event.is_action_pressed(&"ui_page_down") else 42
		_scroll.accept_event()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_page_up"):
		if _scroll.scroll_vertical == 0:
			_swatch.grab_focus()
		else:
			_scroll.scroll_vertical -= roundi(_scroll.size.y * 0.8) if event.is_action_pressed(&"ui_page_up") else 42
		_scroll.accept_event()
	elif event.is_action_pressed(&"ui_accept"):
		%TakeButton.grab_focus()
		_scroll.accept_event()


func open(fish: FishData, weight_kg: float, is_new: bool) -> void:
	%TakeButton.text = "Забрать"
	_title.text = "Новый вид!" if is_new else "Улов!"
	var report := GameState.last_catch_report
	if report.get("record", false):
		_title.text = "Личный рекорд!"
	if report.get("trophy", false):
		_title.text = "Золотой трофей!"
	_swatch.fish = fish
	_name.text = fish.display_name
	_rarity.text = fish.rarity_name()
	_rarity.modulate = fish.rarity_color()
	_stats.text = "%.2f кг  ·  цена %d" % [weight_kg, fish.value_for(weight_kg)]
	_description.text = fish.description
	if report.has("target_completed"):
		_description.text += "\nЦель выполнена! %s" % report["target_completed"]
	if report.get("record", false):
		_description.text += "\nПрежний рекорд: %.2f кг" % float(report["previous_best"])
	for goal in report.get("rewards", []):
		_description.text += "\n%s: +%d монет" % [goal["title"], int(goal["reward"])]
	_animate_open()


## Просмотр рекорда не использует отчёт последнего улова и не выдаёт награды.
func inspect(fish: FishData, entry: Dictionary) -> void:
	var best := float(entry.get("best_kg", 0.0))
	_title.text = "Золотой трофей" if GameState.is_trophy(fish, best) else "Твой рекорд"
	_swatch.fish = fish
	_name.text = fish.display_name
	_rarity.text = fish.rarity_name()
	_rarity.modulate = fish.rarity_color()
	_stats.text = "Рекорд: %.2f кг · поймано %d" % [best, int(entry.get("count", 0))]
	_description.text = "%s\nКлюёт: %s" % [fish.description, DayTime.describe(fish.active_times)]
	%TakeButton.text = "К коллекции"
	_animate_open()


func _animate_open() -> void:
	if _open_tween:
		_open_tween.kill()
	_scroll.scroll_vertical = 0
	show()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 0.8
	_open_tween = create_tween()
	_open_tween.tween_property(self, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if visible:
		if _open_tween:
			_open_tween.kill()
		scale = Vector2.ONE
		hide()
		closed.emit()
