extends Control
## Две независимые шкалы: расстояние до берега и оставшиеся силы рыбы.

var session: FishingSession


func _draw() -> void:
	if session == null:
		return
	var font := ThemeDB.fallback_font
	var width := (size.x - 28.0) * 0.5
	var ink := Color("#ede6cc")
	var muted := Color("#91afa0")
	draw_string(font, Vector2(0, 14), "До берега  %.1f м" % session.distance_to_land(), HORIZONTAL_ALIGNMENT_LEFT, width, 15, ink)
	draw_string(font, Vector2(width + 28, 14), "Силы рыбы  %d%%" % roundi(session.stamina_ratio() * 100), HORIZONTAL_ALIGNMENT_LEFT, width, 15, ink)
	var ratio := clampf(session.distance_to_land() / maxf(0.01, maxf(session.initial_distance, session.distance) - session.landing_distance), 0, 1)
	_bar(Rect2(0, 27, width, 5), 1.0 - ratio, Color("#d8be82"))
	# Рыба движется влево к берегу по мере подмотки, без раскрытия вида.
	var fish_x := ratio * (width - 12) + 6
	draw_colored_polygon(PackedVector2Array([
		Vector2(fish_x - 6, 29), Vector2(fish_x, 25), Vector2(fish_x + 5, 28),
		Vector2(fish_x + 9, 24), Vector2(fish_x + 9, 34), Vector2(fish_x + 5, 31), Vector2(fish_x, 34)]), ink)
	_bar(Rect2(width + 28, 27, width, 5), session.stamina_ratio(), muted)


func _bar(rect: Rect2, ratio: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#102f2b")
	style.set_corner_radius_all(3)
	draw_style_box(style, rect)
	style = style.duplicate()
	style.bg_color = color
	draw_style_box(style, Rect2(rect.position, Vector2(maxf(5, rect.size.x * ratio), rect.size.y)))
