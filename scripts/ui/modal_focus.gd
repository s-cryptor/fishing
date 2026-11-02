class_name ModalFocus
extends RefCounted
## Фокус ограничен кнопками открытого окна: HUD не перехватывает кнопку заброса.


static func watch(panel: Control, preferred: StringName = &"") -> void:
	panel.visibility_changed.connect(func() -> void:
		if panel.is_visible_in_tree():
			restore.call_deferred(panel, preferred))


static func restore(panel: Variant, preferred: StringName = &"") -> void:
	# Окно может быть удалено между перестройкой списка и отложенным вызовом.
	if not is_instance_valid(panel) or not panel is Control or not panel.is_inside_tree() or not panel.is_visible_in_tree():
		return
	var buttons: Array[BaseButton] = []
	for scroll in panel.find_children("*", "ScrollContainer", true, false):
		(scroll as ScrollContainer).follow_focus = true
	for node in panel.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		button.focus_mode = Control.FOCUS_ALL
		if button.is_visible_in_tree() and not button.disabled:
			buttons.append(button)
	var owner: Control = panel.get_viewport().gui_get_focus_owner()
	if is_instance_valid(owner) and panel.is_ancestor_of(owner) and owner.is_visible_in_tree() and owner in buttons:
		return
	for button in buttons:
		if button.name == preferred:
			button.grab_focus()
			return
	for button in buttons:
		if button.toggle_mode and button.button_pressed:
			button.grab_focus()
			return
	# Заголовок содержит «Закрыть», поэтому сначала ищем полезное действие.
	for button in buttons:
		if not "Close" in String(button.name):
			button.grab_focus()
			return
	if not buttons.is_empty():
		buttons[0].grab_focus()
