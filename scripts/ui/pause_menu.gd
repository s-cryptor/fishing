extends CanvasLayer
## Пауза останавливает часы, поклёвку и вываживание. Меню работает на паузе.

var _overlay: Control
var _resume: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	add_to_group(&"pause_menu")
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.theme = preload("res://scenes/ui/ui_theme.tres")
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.09, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Тихая гавань · Пауза"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	_resume = Button.new()
	_resume.text = "Вернуться к рыбалке"
	_resume.pressed.connect(toggle)
	box.add_child(_resume)
	var sound := CheckButton.new()
	sound.text = "Звук"
	sound.button_pressed = PlayerSettings.sound_enabled
	sound.toggled.connect(PlayerSettings.set_sound)
	box.add_child(sound)
	var vibration := CheckButton.new()
	vibration.text = "Вибрация при поклёвке (телефон)"
	vibration.button_pressed = PlayerSettings.vibration_enabled
	vibration.toggled.connect(PlayerSettings.set_vibration)
	box.add_child(vibration)
	var help := Label.new()
	help.text = "Удерживай и отпускай — заброс. Мышь / стик — прицел.\nКлюнуло — нажми сразу. На рывке отпускай.\nДержи натяжение в золотой зоне для быстрой подмотки.\n\nWASD / стик — ходьба · E / X — разговор\nB / Y у причала — лодка · C / Back — коллекция\nTab / стрелки / крестовина — меню · Enter / A — выбор\nEsc / Start — пауза\n\nМарта готовит бонусы из обычного улова.\nПрогресс сохраняется после улова и покупок."
	help.add_theme_font_size_override("font_size", 18)
	box.add_child(help)
	_overlay.hide()
	# На мобильном кнопка остаётся доступной без клавиатуры.
	var button := Button.new()
	button.text = "Пауза"
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = 16.0
	button.offset_top = -55.0
	button.offset_right = 110.0
	button.offset_bottom = -15.0
	button.add_theme_font_size_override("font_size", 16)
	button.theme = _overlay.theme
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(toggle)
	add_child(button)
	# Меню должно отрисовываться поверх кнопки.
	move_child(_overlay, -1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_overlay.visible = paused
	if paused:
		Sfx.set_reel(false)
		_resume.grab_focus()
	else:
		_resume.release_focus()
		# Кнопка действия не должна остаться зажатой после переключения окна.
		Input.action_release(&"fish_action")
		var controller := get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
		if controller:
			controller.require_action_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_overlay) and not get_tree().paused and not DebugTools.automated and DisplayServer.get_name() != "headless":
		toggle()
