class_name LandmarkPopup
extends PanelContainer
## Короткая запись об открытии, доступная повторно из дневника.

signal closed
var _eyebrow: Label
var _title: Label
var _body: Label


func _ready() -> void:
	hide()
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
	_body = Label.new()
	_body.custom_minimum_size.x = 490
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 19)
	box.add_child(_body)
	var close_button := Button.new()
	close_button.name = "ContinueButton"
	close_button.text = "Продолжить"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(close)
	box.add_child(close_button)


func open(data: LandmarkData, is_new: bool) -> void:
	_eyebrow.text = "%s · %s" % ["НОВОЕ ОТКРЫТИЕ" if is_new else "ДНЕВНИК ПУТЕШЕСТВИЙ",
		GameState.BIOMES.for_habitat(data.habitat).display_name]
	_title.text = data.title
	_body.text = data.description
	show()


func close() -> void:
	if visible:
		hide()
		closed.emit()
