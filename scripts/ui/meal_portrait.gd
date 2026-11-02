class_name MealPortrait
extends Control
## Небольшие векторные блюда в палитре гавани, без внешних текстур.

var meal: MealData
var _time := 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	if meal == null:
		return
	var center := size * 0.5
	draw_circle(center, 34, Color("#2b5147"))
	if meal.kind == MealData.Kind.SOUP:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-26, -2), center + Vector2(26, -2),
			center + Vector2(18, 20), center + Vector2(-18, 20)]), Color("#d4c69d"))
		draw_set_transform(center + Vector2(0, -2), 0, Vector2(1, 0.36))
		draw_circle(Vector2.ZERO, 26, Color("#e2d5b1"))
		draw_circle(Vector2.ZERO, 22, Color("#c59d5d"))
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			var p := center + Vector2((i - 1) * 11, -2)
			draw_line(p + Vector2(-3, -2), p + Vector2(3, 1), Color("#758c59"), 3, true)
			var steam := PackedVector2Array()
			for j in 8:
				steam.append(center + Vector2((i - 1) * 12 + sin(_time * 1.5 + j * 0.5 + i) * 2, -15 - j * 2))
			draw_polyline(steam, Color(0.9, 0.86, 0.7, 0.35), 1.5, true)
	else:
		draw_circle(center, 29, Color("#d9ceb0"))
		draw_set_transform(center, -0.2, Vector2(1, 0.55))
		draw_colored_polygon(PackedVector2Array([Vector2(-15, 0), Vector2(-31, -12), Vector2(-31, 12)]), Color("#9e794b"))
		draw_circle(Vector2.ZERO, 21, Color("#b48b53"))
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			var x := center.x + (i - 1) * 8
			draw_line(Vector2(x - 2, center.y - 7), Vector2(x + 3, center.y + 4), Color("#7d6845"), 2, true)
		draw_circle(center + Vector2(14, -5), 2, Color("#4b5140"))
		draw_arc(center + Vector2(14, 17), 9, -PI, 0, 12, Color("#8c9c64"), 4, true)
