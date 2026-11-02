class_name IslandTerrain
extends RefCounted
## Рельефная кромка и цветовые пятна вместо плоского цилиндра.

static func build(parent: Node3D, center: Vector3, biome := 0) -> void:
	var grass := Color("#78946a")
	var sand := Color("#d3bc8b")
	if biome == 1:
		grass = Color("#597b61")
		sand = Color("#b5ac80")
	elif biome == 2:
		grass = Color("#b4ced1")
		sand = Color("#728e9c")
	var art := ArtMesh.new()
	var offsets := [-12.8, -3.0, -1.7, -0.4, 0.0, 1.0]
	var heights := [0.5, 0.5, 0.5, 0.5, 0.0, -0.9]
	var colors := [grass, grass, grass.lerp(sand, 0.25), sand, sand, sand.darkened(0.12)]
	for ring in 5:
		for i in 96:
			var a := TAU * i / 96.0
			var b := TAU * (i + 1) / 96.0
			var points: Array[Vector3] = []
			for pair in [Vector2(a, ring), Vector2(a, ring + 1), Vector2(b, ring + 1), Vector2(b, ring)]:
				var radius := maxf(0.0, ShoreProfile.radius_at(pair.x) + offsets[int(pair.y)])
				if int(pair.y) == 0:
					radius = 0.0
				points.append(center + Vector3(cos(pair.x) * radius, heights[int(pair.y)], sin(pair.x) * radius))
			var color: Color = colors[ring + 1]
			if ring > 1:
				color = color.lightened(sin(i * 3.0 + ring * 7.0) * 0.012)
			art.quad(points[0], points[3], points[2], points[1], color)
	for i in 26:
		var angle := i * 2.39996
		var distance := sqrt(float(i) / 26.0) * 9.0
		var patch := center + Vector3(cos(angle) * distance, 0.503, sin(angle) * distance)
		for side in 7:
			var a := TAU * side / 7.0
			var b := TAU * (side + 1) / 7.0
			var left := patch + Vector3(cos(a), 0, sin(a)) * (1.1 + sin(a * 3 + i) * 0.3)
			var right := patch + Vector3(cos(b), 0, sin(b)) * (1.1 + sin(b * 3 + i) * 0.3)
			art.triangle(patch, right, left, grass.lightened(sin(i * 7.0) * 0.025))
	art.instance(parent, "Coast%d" % biome).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if biome == 0:
		_path(parent, [Vector3(-5, 0, -10), Vector3(-5, 0, -6), Vector3(-1, 0, -3), Vector3(-1, 0, 4)], 1.1)
		_path(parent, [Vector3(-1, 0, -3), Vector3(2, 0, -3), Vector3(4.5, 0, -4)], 0.9)
	elif biome == 1:
		_path(parent, [center + Vector3(-5, 0, -9), center + Vector3(-2, 0, -3), center + Vector3(4, 0, -2), center + Vector3(10, 0, 0)], 0.8)


static func _path(parent: Node3D, controls: Array, width: float) -> void:
	var curve := Curve3D.new()
	for i in controls.size():
		var tangent: Vector3 = (controls[mini(i + 1, controls.size() - 1)] - controls[maxi(i - 1, 0)]) * 0.18
		curve.add_point(controls[i] + Vector3.UP * 0.516, -tangent, tangent)
	var art := ArtMesh.new()
	var points := curve.get_baked_points()
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in points.size():
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := tangent.cross(Vector3.UP) * width * 0.5
		left.append(points[i] - side)
		right.append(points[i] + side)
	for i in points.size() - 1:
		art.quad(left[i], right[i], right[i + 1], left[i + 1], Color("#bbab80"))
	art.instance(parent, "Path").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
