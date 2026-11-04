class_name LandmarkPopup
extends PanelContainer
## Короткая запись об открытии, доступная повторно из дневника.

signal closed
var _eyebrow: Label
var _title: Label
var _body: Label
var _scroll: ScrollContainer
var _continue: Button


func _ready() -> void:
	hide()
	ModalFocus.watch(self, &"ContinueButton")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	_eyebrow = Label.new()
	_eyebrow.add_theme_font_size_override("font_size", 16)
	_eyebrow.modulate = Color("#d5bb7f")
	box.add_child(_eyebrow)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(490, 160)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_ALL
	_scroll.gui_input.connect(_on_reader_input)
	box.add_child(_scroll)
	_body = Label.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 19)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_body)
	var close_button := Button.new()
	_continue = close_button
	close_button.name = "ContinueButton"
	close_button.text = "Продолжить"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(close)
	box.add_child(close_button)
	close_button.focus_neighbor_top = close_button.get_path_to(_scroll)
	close_button.focus_next = close_button.get_path_to(_scroll)
	_scroll.focus_neighbor_bottom = _scroll.get_path_to(close_button)
	_scroll.focus_next = _scroll.get_path_to(close_button)


func _on_reader_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_page_down"):
		var bar := _scroll.get_v_scroll_bar()
		if _scroll.scroll_vertical >= bar.max_value - bar.page - 1:
			_continue.grab_focus()
		else:
			_scroll.scroll_vertical += roundi(_scroll.size.y * 0.8) if event.is_action_pressed(&"ui_page_down") else 42
		_scroll.accept_event()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_page_up"):
		_scroll.scroll_vertical -= roundi(_scroll.size.y * 0.8) if event.is_action_pressed(&"ui_page_up") else 42
		_scroll.accept_event()
	elif event.is_action_pressed(&"ui_accept"):
		_continue.grab_focus()
		_scroll.accept_event()


func open(data: LandmarkData, is_new: bool) -> void:
	offset_top = -190
	offset_bottom = 190
	_scroll.scroll_vertical = 0
	_eyebrow.text = "%s · %s" % ["НОВОЕ ОТКРЫТИЕ" if is_new else "ДНЕВНИК ПУТЕШЕСТВИЙ",
		GameState.BIOMES.for_habitat(data.habitat).display_name]
	_title.text = data.title
	_body.text = data.description
	show()


func open_message(data: DriftMessageData, is_new: bool) -> void:
	offset_top = -290
	offset_bottom = 290
	_scroll.scroll_vertical = 0
	_eyebrow.text = "%s · %s" % ["НАЙДЕНО ПИСЬМО" if is_new else "ПИСЬМА СМОТРИТЕЛЯ",
		GameState.BIOMES.for_habitat(data.habitat).display_name]
	_title.text = data.title
	_body.text = data.body
	if GameState.found_messages.size() == GameState.MESSAGES.messages.size():
		_body.text += "\n\nВсе письма сохранены. На лодке появился флажок возвращения."
	show()


func close() -> void:
	if visible:
		hide()
		closed.emit()
