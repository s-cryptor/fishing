class_name FishPortrait
extends Control
## Векторный портрет вида: работает в WebGL и масштабируется без текстур.

var fish: FishData
var discovered := true
var _time := 0.0
var _box: StyleBoxFlat


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if fish == null:
		return
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var center := size * Vector2(0.48, 0.52) + Vector2(0, sin(_time * 1.8) * 2.0)
	var length := minf(size.x * 0.55, size.y * 1.8)
	var slender := fish.id in [&"pike", &"barramundi", &"sawfish", &"catfish", &"atlantic_salmon", &"arctic_char"]
	var height := length * (0.28 if slender else 0.43)
	var base := fish.color if discovered else Color("#243c50")
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * length * 0.5, sin(angle) * height * 0.5))
	var tail := center + Vector2(-length * 0.43, 0)
	var sway := sin(_time * 3.0) * 3.0
	draw_colored_polygon(PackedVector2Array([tail, tail + Vector2(-length * 0.3, -height * 0.65 + sway), tail + Vector2(-length * 0.3, height * 0.65 + sway)]), base.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-length * 0.2, -height * 0.3), center + Vector2(-length * 0.08, -height * 0.95), center + Vector2(length * 0.25, -height * 0.3)]), base.darkened(0.1))
	draw_colored_polygon(points, base)
	if not discovered:
		return
	# Светлое брюшко и боковой плавник создают объём.
	draw_line(center + Vector2(-length * 0.28, height * 0.24), center + Vector2(length * 0.25, height * 0.24), base.lightened(0.35), height * 0.13, true)
	draw_colored_polygon(PackedVector2Array([center, center + Vector2(-length * 0.12, height * 0.6), center + Vector2(length * 0.1, height * 0.15)]), base.darkened(0.2))
	if fish.id in [&"perch", &"archerfish", &"tilapia"]:
		for i in 4:
			var x := center.x + (i - 1.5) * length * 0.13
			draw_line(Vector2(x, center.y - height * 0.35), Vector2(x - 3, center.y + height * 0.25), base.darkened(0.4), 4.0, true)
	if fish.id == &"sawfish":
		var nose := center + Vector2(length * 0.47, 0)
		draw_line(nose, nose + Vector2(length * 0.38, 0), base, height * 0.2, true)
		for i in 6:
			var tooth := nose + Vector2(i * length * 0.06, 0)
			draw_line(tooth - Vector2(0, height * 0.2), tooth + Vector2(0, height * 0.2), base.lightened(0.3), 2.0, true)
	var eye := center + Vector2(length * 0.32, -height * 0.12)
	draw_circle(eye, maxf(3.0, height * 0.11), Color("#f5eed7"))
	draw_circle(eye + Vector2(1, 0), maxf(1.5, height * 0.06), Color("#122331"))
	if fish.id == &"catfish":
		for side in [-1, 1]:
			draw_line(center + Vector2(length * 0.42, height * 0.13), center + Vector2(length * 0.65, height * 0.5 * side), base.lightened(0.3), 2.0, true)


func _background() -> StyleBoxFlat:
	if _box == null:
		_box = StyleBoxFlat.new()
		_box.bg_color = Color("#102e40")
		_box.set_corner_radius_all(12)
	return _box
