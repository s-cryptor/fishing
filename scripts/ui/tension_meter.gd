class_name TensionMeter
extends Control
## Шкала натяжения лески: провис — рабочая зона — опасная зона.

const DANGER_FROM := 0.85
const SLACK_COLOR := Color("#819b9c")
const SAFE_COLOR := Color("#83aa7c")
const DANGER_COLOR := Color("#cf7865")

var tension := 0.0:
	set(value):
		tension = value
		queue_redraw()
var thrashing := false:
	set(value):
		thrashing = value
		queue_redraw()


func _draw() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#102f2b")
	background.set_corner_radius_all(8)
	draw_style_box(background, Rect2(Vector2.ZERO, size).grow(4.0))
	_draw_zone(0.0, FishingSession.SLACK_TENSION, SLACK_COLOR)
	_draw_zone(FishingSession.SLACK_TENSION, DANGER_FROM, SAFE_COLOR)
	_draw_zone(DANGER_FROM, 1.0, DANGER_COLOR)
	var x := clampf(tension, 0.0, 1.0) * size.x
	var marker := StyleBoxFlat.new()
	marker.bg_color = Color("#f3c578") if thrashing else Color("#f0e7ce")
	marker.set_corner_radius_all(3)
	draw_style_box(marker, Rect2(x - 3.0, -5.0, 6.0, size.y + 10.0))


func _draw_zone(from: float, to: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6 if from == 0.0 else 0
	style.corner_radius_bottom_left = 6 if from == 0.0 else 0
	style.corner_radius_top_right = 6 if to == 1.0 else 0
	style.corner_radius_bottom_right = 6 if to == 1.0 else 0
	draw_style_box(style, Rect2(from * size.x, 0.0, (to - from) * size.x, size.y))
