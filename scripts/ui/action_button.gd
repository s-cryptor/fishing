class_name ActionButton
extends TouchScreenButton
## Тач-кнопка рыбалки. TouchScreenButton сам нажимает action и
## поддерживает мультитач; здесь только круглая форма и отрисовка.

@export var radius := 75.0
@export var label := "ЛОВИТЬ"
var _controller: FishingController
var _detail := "зажми и отпусти"
var _tone := FishingFeedback.CALM
var _progress := -1.0


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape = circle
	action = "fish_action"
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)


func _draw() -> void:
	var background := Color("#173c39")
	background.a = 0.95 if is_pressed() else 0.86
	draw_circle(Vector2.ZERO, radius, background)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, _tone, 2.0, true)
	if _progress >= 0.0:
		draw_arc(Vector2.ZERO, radius - 8.0, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, _progress), 48, _tone, 5.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 22
	draw_string(font, Vector2(-radius, -4), label,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, Color("#efe8cf"))
	draw_string(font, Vector2(-radius, 21), _detail,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 14, _tone)


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _controller == null:
		_controller = get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	if _controller == null:
		return
	var feedback := state_for(_controller.phase, _controller.session, _controller.cast_power())
	if feedback["label"] != label or feedback["detail"] != _detail or feedback["color"] != _tone or not is_equal_approx(feedback["progress"], _progress):
		label = feedback["label"]
		_detail = feedback["detail"]
		_tone = feedback["color"]
		_progress = feedback["progress"]
		queue_redraw()


static func state_for(phase: int, session: FishingSession, power := 0.0) -> Dictionary:
	var result := {"label": "ЗАБРОС", "detail": "зажми и отпусти", "color": FishingFeedback.CALM, "progress": -1.0}
	match phase:
		FishingController.Phase.CHARGING:
			result.merge({"label": "ОТПУСТИ", "detail": "сила заброса", "progress": clampf(power, 0.0, 1.0), "color": FishingFeedback.WARNING}, true)
		FishingController.Phase.CASTING:
			result.merge({"label": "ЛЕТИТ", "detail": "к воде"}, true)
		FishingController.Phase.RESULT:
			result.merge({"label": "ДАЛЬШЕ", "detail": "нажми"}, true)
		FishingController.Phase.SESSION:
			if session:
				match session.state:
					FishingSession.State.WAITING:
						result.merge({"label": "СМОТАТЬ", "detail": "нажми"}, true)
					FishingSession.State.BITING:
						result.merge({"label": "ПОДСЕЧЬ!", "detail": "нажми сейчас", "color": FishingFeedback.WARNING,
							"progress": clampf(session.bite_time_left() / session.bite_window(), 0.0, 1.0)}, true)
					FishingSession.State.FIGHTING:
						return FishingFeedback.fight(session)
	return result
