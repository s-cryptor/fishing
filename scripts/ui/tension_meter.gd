class_name TensionMeter
extends Control
## Шкала натяжения лески: провис — рабочая зона — опасная зона.

const DANGER_FROM := 0.85
const SLACK_COLOR := Color("#5d7089")
const SAFE_COLOR := Color("#3fae5a")
const DANGER_COLOR := Color("#d64545")

var tension := 0.0:
	set(value):
		tension = value
		queue_redraw()
var thrashing := false:
	set(value):
		thrashing = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size).grow(3.0), Color(0.0, 0.0, 0.0, 0.55))
	_draw_zone(0.0, FishingSession.SLACK_TENSION, SLACK_COLOR)
	_draw_zone(FishingSession.SLACK_TENSION, DANGER_FROM, SAFE_COLOR)
	_draw_zone(DANGER_FROM, 1.0, DANGER_COLOR)
	var x := clampf(tension, 0.0, 1.0) * size.x
	var marker_color := Color("#ffe14d") if thrashing else Color.WHITE
	draw_rect(Rect2(x - 4.0, -8.0, 8.0, size.y + 16.0), marker_color)


func _draw_zone(from: float, to: float, color: Color) -> void:
	draw_rect(Rect2(from * size.x, 0.0, (to - from) * size.x, size.y), color)
