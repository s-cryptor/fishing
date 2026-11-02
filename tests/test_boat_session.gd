extends SceneTree
## Навигация проверяется без сцены, ввода и кадров рендера.

var _failures := 0


func _initialize() -> void:
	var a := BoatSession.new(Vector2(0, -16))
	var b := BoatSession.new(Vector2(0, -16))
	for i in 600:
		var input := Vector2(sin(i * 0.03), cos(i * 0.03))
		a.tick(1.0 / 60, input, false)
		b.tick(1.0 / 60, input, false)
	_check(a.position.is_equal_approx(b.position) and a.velocity.is_equal_approx(b.velocity), "одинаковый ввод даёт одинаковый маршрут")
	var safe := true
	for direction in 72:
		var outward := Vector2.from_angle(TAU * direction / 72)
		var boat := BoatSession.new(outward * 19)
		for step in 100:
			boat.tick(0.1, -outward, false)
			safe = safe and boat.is_safe(boat.position)
	_check(safe, "лодка не пересекает фигурный берег с 72 направлений")
	var boat := BoatSession.new(Vector2(0, -16))
	for step in 100:
		boat.tick(0.1, Vector2.UP, false)
	_check(boat.position.length() <= BoatSession.EXCURSION_RADIUS and boat.blocked, "сильное течение ограничивает прогулку текущей бухтой")
	boat = BoatSession.new(Vector2(0, -16))
	boat.tick(10, Vector2.DOWN, false)
	_check(boat.is_safe(boat.position), "длинный кадр не позволяет проскочить насквозь остров")
	boat = BoatSession.new(Vector2(0, -16))
	boat.tick(0.5, Vector2.UP, false)
	var anchored := boat.position
	boat.tick(1.0, Vector2.RIGHT, true)
	_check(boat.position == anchored and boat.velocity == Vector2.ZERO, "якорь немедленно останавливает лодку во время рыбалки")
	var stats: BoatStats = load("res://data/boats/explorer.tres")
	var upgraded := BoatSession.new(Vector2(0, -16), stats.sailing_speed)
	_check(upgraded.speed > boat.speed, "улучшенная лодка быстрее обычной")
	var starter := BoatSession.new(Vector2.ZERO)
	_check(starter.is_safe(starter.position), "посадка всегда помещает корпус в безопасную воду")
	boat = BoatSession.new(Vector2(0, -20))
	for step in 60:
		boat.tick(1.0 / 60, Vector2.ONE, false)
	_check(boat.velocity.length() <= boat.speed + 0.001, "диагональный ход не ускоряет лодку")
	for step in 120:
		boat.tick(1.0 / 60, Vector2.ZERO, false)
	_check(boat.velocity.length() < 0.01, "без ввода лодка плавно останавливается")
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
