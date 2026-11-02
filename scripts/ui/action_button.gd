class_name ActionButton
extends TouchScreenButton
## Тач-кнопка рыбалки. TouchScreenButton сам нажимает action и
## поддерживает мультитач; здесь только круглая форма и отрисовка.

@export var radius := 75.0
@export var label := "ЛОВИТЬ"
var _controller: FishingController


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape = circle
	action = "fish_action"
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.03, 0.15, 0.22, 0.9 if is_pressed() else 0.78))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.55, 0.95, 0.85, 0.95), 3.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 22
	draw_string(font, Vector2(-radius, font_size * 0.35), label,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size)


func _process(_delta: float) -> void:
	if _controller == null:
		_controller = get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	if _controller == null:
		return
	var next := "ЗАБРОС"
	match _controller.phase:
		FishingController.Phase.CHARGING: next = "ОТПУСТИ"
		FishingController.Phase.CASTING: next = "ЛЕТИТ"
		FishingController.Phase.RESULT: next = "ДАЛЬШЕ"
		FishingController.Phase.SESSION:
			if _controller.session:
				match _controller.session.state:
					FishingSession.State.WAITING: next = "СМОТАТЬ"
					FishingSession.State.BITING: next = "ПОДСЕЧЬ!"
					FishingSession.State.FIGHTING: next = "ТЯНИ"
	if next != label:
		label = next
		queue_redraw()
