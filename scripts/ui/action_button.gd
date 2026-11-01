class_name ActionButton
extends TouchScreenButton
## Тач-кнопка рыбалки. TouchScreenButton сам нажимает action и
## поддерживает мультитач; здесь только круглая форма и отрисовка.

@export var radius := 75.0
@export var label := "ЛОВИТЬ"


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape = circle
	action = "fish_action"
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, 0.4 if is_pressed() else 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.5), 3.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 22
	draw_string(font, Vector2(-radius, font_size * 0.35), label,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size)
