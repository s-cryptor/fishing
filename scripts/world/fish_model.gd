class_name FishModel
extends Node3D
## Собственные объёмные трофеи: силуэт, плавники и приметы каждого вида.

var _tail: Node3D
var _time := 0.0
var _pectoral: Array[Node3D] = []
var _body: MeshInstance3D


func build(fish: FishData) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_pectoral.clear()
	_tail = null
	_body = null
	_time = 0.0
	if fish == null:
		return
	var art := ArtMesh.new()
	var base := fish.color
	var slender := fish.id in [&"pike", &"catfish", &"barramundi", &"sawfish", &"atlantic_salmon", &"arctic_char"]
	var flat := fish.id == &"greenland_halibut"
	var height := 0.65 if slender else 1.0
	var depth := 2.3 if flat else 1.0
	if flat:
		height = 0.27
	elif fish.id == &"bream":
		height = 1.25
	elif fish.id == &"golden_carp":
		height = 1.1
	elif fish.id == &"sawfish":
		height = 0.4
		depth = 1.35
	var profile := _profile_for(fish.id)
	for ring in profile.size() - 1:
		for side in 10:
			var a := TAU * side / 10.0
			var b := TAU * (side + 1) / 10.0
			var left: Vector2 = profile[ring]
			var right: Vector2 = profile[ring + 1]
			var top := sin((a + b) * 0.5)
			var color := base.darkened(0.22 * maxf(0, top)).lightened(0.4 * maxf(0, -top))
			art.quad(_point(left, a, height, depth), _point(right, a, height, depth),
				_point(right, b, height, depth), _point(left, b, height, depth), color)
	# Нос и хвостовая перемычка закрывают торцы.
	for side in 10:
		var a := TAU * side / 10.0
		var b := TAU * (side + 1) / 10.0
		art.triangle(Vector3(profile.back().x + 0.04, 0, 0), _point(profile.back(), a, height, depth), _point(profile.back(), b, height, depth), base)
		art.triangle(Vector3(-1.25, 0, 0), _point(profile.front(), b, height, depth), _point(profile.front(), a, height, depth), base)
	var fin := base.darkened(0.2)
	if fish.id in [&"perch", &"roach"]:
		fin = Color("#bf7954")
	elif fish.id == &"golden_carp":
		fin = Color("#c69343")
	if fish.id in [&"perch", &"tilapia", &"archerfish"]:
		for spike in 5:
			var x := -0.65 + spike * 0.18
			art.triangle(Vector3(x, 0.32 * height, 0), Vector3(x + 0.12, (0.65 + sin(spike * 0.7) * 0.15) * height, 0), Vector3(x + 0.27, 0.38 * height, 0), fin)
	elif fish.id == &"pike":
		art.triangle(Vector3(-0.95, 0.2, 0), Vector3(-0.85, 0.55, 0), Vector3(-0.3, 0.26, 0), fin)
	elif not flat:
		var fin_height := 0.65 if fish.id in [&"bream", &"golden_carp", &"catfish"] else 0.88
		art.triangle(Vector3(-0.65, 0.25 * height, 0), Vector3(-0.35, fin_height * height, 0), Vector3(0.4, 0.4 * height, 0), fin)
	for side in [-1, 1]:
		var z: float = side * 0.24 * depth
		var span := 0.42 if flat else (0.8 if fish.id == &"sawfish" else 0.58)
		var pivot := Node3D.new()
		pivot.name = "PectoralLeft" if side < 0 else "PectoralRight"
		pivot.position = Vector3(0.3, -0.04, z)
		add_child(pivot)
		_pectoral.append(pivot)
		var pectoral := ArtMesh.new()
		var tip := Vector3(-0.6, -0.28 * height, side * (span - 0.24) * depth)
		pectoral.triangle(Vector3.ZERO, tip, Vector3(-0.38, 0.08, 0), fin)
		for ray in 3:
			pectoral.tube(Vector3(-0.02, 0, side * 0.006), tip.lerp(Vector3(-0.38, 0.08, 0), ray * 0.3), 0.006, fin.lightened(0.3), 0.002, 4)
		pectoral.instance(pivot, "Fin")
		art.triangle(Vector3(-0.5, -0.25 * height, 0), Vector3(-0.8, -0.64 * height, side * 0.16), Vector3(-0.15, -0.4 * height, 0), fin)
		if not flat and fish.id != &"sawfish":
			var eye := _skin_point(profile, 0.87, 0.35, side, height, depth)
			art.pebble(eye, Vector3(0.108, 0.108, 0.045), Color("#eee0ad"))
			art.pebble(eye + Vector3(0.015, 0, side * 0.037), Vector3(0.061, 0.066, 0.016), Color("#183a38"))
			art.pebble(eye + Vector3(0.035, 0.025, side * 0.05), Vector3.ONE * 0.019, Color("#fff5dc"))
			art.tube(Vector3(1.08, -0.04, side * 0.12), Vector3(1.18, -0.055, side * 0.05), 0.008, fin.darkened(0.2), 0.006, 5)
		for arc in 5:
			var a := lerpf(0.8, -0.65, arc / 5.0)
			var b := lerpf(0.8, -0.65, (arc + 1) / 5.0)
			art.tube(_skin_point(profile, 0.6, a, side, height, depth), _skin_point(profile, 0.6, b, side, height, depth), 0.008, base.darkened(0.35), 0.006, 4)
		if fish.id == &"catfish":
			for whisker in 3:
				art.tube(Vector3(1.04, -0.04 - whisker * 0.04, side * 0.16), Vector3(1.43 - whisker * 0.16, -0.16 - whisker * 0.12, side * (0.5 - whisker * 0.08)), 0.015, base.lightened(0.3), 0.004, 5)
		elif fish.id == &"golden_carp":
			art.tube(Vector3(1.1, -0.05, side * 0.1), Vector3(1.2, -0.18, side * 0.16), 0.009, fin, 0.003, 4)
	if fish.id in [&"arctic_char", &"atlantic_salmon"]:
		art.triangle(Vector3(-1.0, 0.15, 0), Vector3(-0.9, 0.33, 0), Vector3(-0.65, 0.22, 0), fin)
	if flat:
		for side in [-1, 1]:
			for segment in 9:
				var x := -1.0 + segment * 0.22
				var edge := _skin_point(profile, x, 0.0, side, height, depth)
				var next := _skin_point(profile, x + 0.22, 0.0, side, height, depth)
				art.triangle(edge, next, edge.lerp(next, 0.5) + Vector3(-0.08, 0.01, side * 0.15), fin)
	if flat or fish.id == &"sawfish":
		var eyes := [Vector3(0.78, 0.10, 0.12), Vector3(0.6, 0.10, 0.32)] if flat else [Vector3(0.85, 0.13, -0.15), Vector3(0.85, 0.13, 0.15)]
		for eye in eyes:
			art.pebble(eye, Vector3(0.08, 0.035, 0.08), Color("#d9d5ac"))
			art.pebble(eye + Vector3.UP * 0.03, Vector3(0.045, 0.012, 0.045), Color("#183a38"))
	if fish.id == &"sawfish":
		art.box(Vector3(1.53, 0, 0), Vector3(0.8, 0.065, 0.12), base)
		for tooth in 7:
			var x := 1.2 + tooth * 0.11
			for side in [-1, 1]:
				art.triangle(Vector3(x, 0, side * 0.06), Vector3(x + 0.05, 0, side * 0.19), Vector3(x + 0.08, 0, side * 0.06), base.lightened(0.25))
	_add_pattern(art, fish, profile, height, depth)
	if flat:
		for spot in 18:
			var x := -0.9 + (spot % 6) * 0.3
			var z := -0.6 + floorf(spot / 6.0) * 0.6
			var tint := base.lightened(0.15) if spot % 3 == 0 else base.darkened(0.2)
			for petal in 6:
				var a := TAU * petal / 6.0
				var b := TAU * (petal + 1) / 6.0
				art.triangle(_top_point(profile, x, z, height, depth),
					_top_point(profile, x + cos(a) * 0.055, z + sin(a) * 0.13, height, depth),
					_top_point(profile, x + cos(b) * 0.055, z + sin(b) * 0.13, height, depth), tint)
	_body = art.instance(self, "Body")
	_tail = Node3D.new()
	_tail.position = Vector3(-1.2, 0, 0)
	add_child(_tail)
	var tail := ArtMesh.new()
	var tail_height := 1.0 if flat else height
	tail.triangle(Vector3.ZERO, Vector3(-0.85, 0.55 * tail_height, 0), Vector3(-0.65, 0, 0), fin)
	tail.triangle(Vector3.ZERO, Vector3(-0.65, 0, 0), Vector3(-0.85, -0.55 * tail_height, 0), fin.lightened(0.08))
	for ray in 5:
		var end := Vector3(-0.8, (ray - 2) * 0.24 * tail_height, 0.008)
		tail.tube(Vector3(-0.05, 0, 0.008), end, 0.009, base.lightened(0.16), 0.004, 5)
	var tail_mesh := tail.instance(_tail, "Tail")
	if flat:
		tail_mesh.rotation.x = PI * 0.5
	# Материал рыбы отдельный: не меняем общий матовый материал островных ассетов.
	var skin := (_body.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	skin.roughness = 0.62
	skin.metallic = 0.18 if fish.id == &"golden_carp" else 0.05
	for mesh in find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = skin


static func _profile_for(id: StringName) -> Array[Vector2]:
	match id:
		&"pike": return [Vector2(-1.25, 0.08), Vector2(-0.95, 0.25), Vector2(-0.45, 0.36), Vector2(0.2, 0.34), Vector2(0.7, 0.25), Vector2(1.05, 0.15), Vector2(1.4, 0.08)]
		&"catfish": return [Vector2(-1.25, 0.08), Vector2(-0.95, 0.18), Vector2(-0.5, 0.32), Vector2(0.15, 0.42), Vector2(0.7, 0.43), Vector2(1.12, 0.27)]
		&"bream": return [Vector2(-1.25, 0.07), Vector2(-0.95, 0.17), Vector2(-0.55, 0.37), Vector2(-0.1, 0.52), Vector2(0.42, 0.43), Vector2(0.85, 0.23), Vector2(1.1, 0.07)]
		&"golden_carp": return [Vector2(-1.25, 0.09), Vector2(-0.9, 0.23), Vector2(-0.4, 0.47), Vector2(0.15, 0.48), Vector2(0.62, 0.36), Vector2(1.1, 0.17)]
		&"arctic_char", &"atlantic_salmon": return [Vector2(-1.25, 0.06), Vector2(-0.95, 0.19), Vector2(-0.4, 0.38), Vector2(0.25, 0.37), Vector2(0.8, 0.23), Vector2(1.24, 0.06)]
		&"sawfish": return [Vector2(-1.25, 0.07), Vector2(-0.8, 0.2), Vector2(-0.2, 0.38), Vector2(0.4, 0.44), Vector2(0.9, 0.3), Vector2(1.15, 0.12)]
	return [Vector2(-1.25, 0.08), Vector2(-0.95, 0.22), Vector2(-0.4, 0.45), Vector2(0.2, 0.47), Vector2(0.7, 0.34), Vector2(1.15, 0.1)]


static func _skin_point(profile: Array[Vector2], x: float, vertical: float, side: int, height: float, depth: float) -> Vector3:
	var radius: float = profile[0].y
	for index in profile.size() - 1:
		if x >= profile[index].x:
			var ratio := clampf(inverse_lerp(profile[index].x, profile[index + 1].x, x), 0.0, 1.0)
			radius = lerpf(profile[index].y, profile[index + 1].y, ratio)
	var angle := asin(clampf(vertical, -0.96, 0.96))
	return Vector3(x, sin(angle) * radius * height, side * cos(angle) * radius * 0.72 * depth) * Vector3(1, 1.065, 1.065)


static func _top_point(profile: Array[Vector2], x: float, sideways: float, height: float, depth: float) -> Vector3:
	# Та же поверхность, но рисунок идёт по верхней стороне плоской рыбы.
	var point := _skin_point(profile, x, sideways, 1, depth * 0.72, height / 0.72)
	return Vector3(point.x, point.z, point.y)


func _add_pattern(art: ArtMesh, fish: FishData, profile: Array[Vector2], height: float, depth: float) -> void:
	for side in [-1, 1]:
		if fish.id in [&"perch", &"archerfish", &"tilapia"]:
			for band in 5:
				var x := -0.85 + band * 0.31
				_patch(art, profile, x - 0.055, x + 0.055, 0.95, -0.25, side, height, depth, fish.color.darkened(0.4), 2, 8)
		if fish.id in [&"arctic_char", &"barramundi"]:
			var stripe := Color("#c57e73") if fish.id == &"arctic_char" else fish.color.lightened(0.35)
			_patch(art, profile, -0.95, 0.72, -0.02, -0.25, side, height, depth, stripe, 12, 2)
		if fish.id in [&"pike", &"arctic_char", &"atlantic_salmon", &"golden_carp", &"greenland_halibut"]:
			for spot in 24:
				var x := -0.95 + (spot % 8) * 0.225 + (0.05 if spot >= 8 and spot < 16 else 0.0)
				var y := -0.3 + floorf(spot / 8.0) * 0.4
				var tint := fish.color.lightened(0.5) if fish.id in [&"pike", &"arctic_char", &"golden_carp"] else fish.color.darkened(0.35)
				if fish.id == &"golden_carp":
					tint = fish.color.lightened(0.22)
				var center := _skin_point(profile, x, y, side, height, depth)
				# Пятна лежат на коже, а не состоят из десятков объёмных шариков.
				var petals := 4 if fish.id == &"golden_carp" else 6
				for petal in petals:
					var a := TAU * petal / float(petals)
					var b := TAU * (petal + 1) / float(petals)
					art.triangle(center, _skin_point(profile, x + cos(a) * 0.05, y + sin(a) * 0.11, side, height, depth),
						_skin_point(profile, x + cos(b) * 0.05, y + sin(b) * 0.11, side, height, depth), tint)


static func _patch(art: ArtMesh, profile: Array[Vector2], x0: float, x1: float, y0: float, y1: float, side: int,
		height: float, depth: float, color: Color, columns: int, rows: int) -> void:
	# Разбиваем рисунок по изгибу тела: один плоский полигон утонет внутри выпуклого меша.
	for column in columns:
		for row in rows:
			var a := lerpf(x0, x1, column / float(columns))
			var b := lerpf(x0, x1, (column + 1) / float(columns))
			var c := lerpf(y0, y1, row / float(rows))
			var d := lerpf(y0, y1, (row + 1) / float(rows))
			art.quad(_skin_point(profile, a, c, side, height, depth), _skin_point(profile, b, c, side, height, depth),
				_skin_point(profile, b, d, side, height, depth), _skin_point(profile, a, d, side, height, depth), color)


func _point(profile: Vector2, angle: float, height: float, depth: float) -> Vector3:
	return Vector3(profile.x, sin(angle) * profile.y * height, cos(angle) * profile.y * 0.72 * depth)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	if _tail:
		_tail.rotation.y = sin(_time * 3.5) * 0.18
	for index in _pectoral.size():
		_pectoral[index].rotation.x = sin(_time * 2.3 + index * 0.8) * 0.18 * (-1 if index == 0 else 1)
	if _body:
		_body.scale.y = 1.0 + sin(_time * 2.0) * 0.012
