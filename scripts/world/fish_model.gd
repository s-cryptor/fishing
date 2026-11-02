class_name FishModel
extends Node3D
## Собственные объёмные трофеи: силуэт, плавники и приметы каждого вида.

var _tail: Node3D
var _time := 0.0


func build(fish: FishData) -> void:
	var art := ArtMesh.new()
	var base := fish.color
	var slender := fish.id in [&"pike", &"catfish", &"barramundi", &"sawfish", &"atlantic_salmon", &"arctic_char"]
	var flat := fish.id == &"greenland_halibut"
	var height := 0.65 if slender else 1.0
	var depth := 0.65 if flat else 1.0
	var profile := [Vector2(-1.25, 0.08), Vector2(-0.9, 0.28), Vector2(-0.35, 0.47), Vector2(0.35, 0.44), Vector2(0.85, 0.3), Vector2(1.15, 0.12)]
	for ring in profile.size() - 1:
		for side in 10:
			var a := TAU * side / 10.0
			var b := TAU * (side + 1) / 10.0
			var left: Vector2 = profile[ring]
			var right: Vector2 = profile[ring + 1]
			var top := sin((a + b) * 0.5)
			var color := base.darkened(0.22 * maxf(0, top)).lightened(0.4 * maxf(0, -top))
			if fish.id in [&"perch", &"archerfish", &"tilapia"] and ring % 2 == 1:
				color = color.darkened(0.32)
			art.quad(_point(left, a, height, depth), _point(right, a, height, depth),
				_point(right, b, height, depth), _point(left, b, height, depth), color)
	# Нос и хвостовая перемычка закрывают торцы.
	for side in 10:
		var a := TAU * side / 10.0
		var b := TAU * (side + 1) / 10.0
		art.triangle(Vector3(1.2, 0, 0), _point(profile.back(), a, height, depth), _point(profile.back(), b, height, depth), base)
		art.triangle(Vector3(-1.25, 0, 0), _point(profile.front(), b, height, depth), _point(profile.front(), a, height, depth), base)
	var fin := base.darkened(0.2)
	art.triangle(Vector3(-0.65, 0.25 * height, 0), Vector3(-0.35, 0.88 * height, 0), Vector3(0.4, 0.4 * height, 0), fin)
	for side in [-1, 1]:
		var z: float = side * 0.24 * depth
		art.triangle(Vector3(0.3, -0.04, z), Vector3(-0.3, -0.38 * height, side * 0.58 * depth), Vector3(-0.08, 0.04, z), fin)
		art.triangle(Vector3(-0.5, -0.25 * height, 0), Vector3(-0.8, -0.64 * height, side * 0.16), Vector3(-0.15, -0.4 * height, 0), fin)
		var eye := Vector3(0.88, 0.12 * height, side * 0.205 * depth)
		art.pebble(eye, Vector3(0.108, 0.108, 0.045), Color("#eee0ad"))
		art.pebble(eye + Vector3(0.015, 0, side * 0.037), Vector3(0.061, 0.066, 0.016), Color("#183a38"))
		art.pebble(eye + Vector3(0.035, 0.025, side * 0.05), Vector3.ONE * 0.019, Color("#fff5dc"))
		art.tube(Vector3(0.58, 0.22 * height, side * 0.25 * depth), Vector3(0.55, -0.2 * height, side * 0.26 * depth), 0.012, fin, 0.008, 5)
		if fish.id == &"catfish":
			art.tube(Vector3(1.07, -0.05, side * 0.12), Vector3(1.46, -0.3, side * 0.46), 0.018, base.lightened(0.3), 0.005, 5)
	if fish.id == &"sawfish":
		art.box(Vector3(1.53, 0, 0), Vector3(0.8, 0.065, 0.12), base)
		for tooth in 7:
			var x := 1.2 + tooth * 0.11
			for side in [-1, 1]:
				art.triangle(Vector3(x, 0, side * 0.06), Vector3(x + 0.05, 0, side * 0.19), Vector3(x + 0.08, 0, side * 0.06), base.lightened(0.25))
	if fish.id in [&"pike", &"arctic_char", &"atlantic_salmon", &"barramundi"]:
		for spot in 20:
			var x := -0.8 + (spot % 7) * 0.22
			var y := (spot / 7 - 1) * 0.11
			var z := sqrt(maxf(0.0, 1.0 - (x / 1.3) * (x / 1.3) - (y / (height * 0.45)) * (y / (height * 0.45)))) * 0.31
			for side in [-1, 1]:
				art.pebble(Vector3(x, y, side * z), Vector3(0.035, 0.025, 0.012), base.lightened(0.28) if fish.id == &"pike" else base.darkened(0.3), spot)
	art.instance(self, "Body")
	_tail = Node3D.new()
	_tail.position = Vector3(-1.2, 0, 0)
	add_child(_tail)
	var tail := ArtMesh.new()
	tail.triangle(Vector3.ZERO, Vector3(-0.85, 0.55 * height, 0), Vector3(-0.65, 0, 0), fin)
	tail.triangle(Vector3.ZERO, Vector3(-0.65, 0, 0), Vector3(-0.85, -0.55 * height, 0), fin.lightened(0.08))
	for ray in 5:
		var end := Vector3(-0.8, (ray - 2) * 0.24 * height, 0.008)
		tail.tube(Vector3(-0.05, 0, 0.008), end, 0.009, base.lightened(0.16), 0.004, 5)
	tail.instance(_tail, "Tail")


func _point(profile: Vector2, angle: float, height: float, depth: float) -> Vector3:
	return Vector3(profile.x, sin(angle) * profile.y * height, cos(angle) * profile.y * 0.72 * depth)


func _process(delta: float) -> void:
	_time += delta
	if _tail:
		_tail.rotation.y = sin(_time * 3.5) * 0.18
