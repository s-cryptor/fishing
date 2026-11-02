class_name NatureArt
extends RefCounted
## Округлые кроны, разветвлённые стволы и корни: один меш на дерево.

static func tree(parent: Node3D, point := Vector3.ZERO, mangrove := false) -> void:
	var art := ArtMesh.new()
	var canopy := ArtMesh.new()
	var crown := Node3D.new()
	crown.position = point + Vector3.UP * 1.8
	crown.set_script(preload("res://scripts/world/foliage_sway.gd"))
	parent.add_child(crown)
	var bark := Color("#735948")
	var leaves := Color("#567e61") if not mangrove else Color("#3e7164")
	art.tube(point, point + Vector3(0.14, 1.5, 0.05), 0.22, bark, 0.16)
	art.tube(point + Vector3(0.14, 1.4, 0.05), point + Vector3(-0.1, 2.9, 0), 0.16, bark, 0.06)
	for i in 5:
		var angle := i * TAU / 5.0 + 0.3
		var outward := Vector3(cos(angle), 0, sin(angle))
		var end := point + outward * 0.9 + Vector3.UP * (2.35 + sin(i * 3.0) * 0.2)
		art.tube(point + Vector3(0.1, 1.7, 0), end, 0.09, bark, 0.035)
		canopy.pebble(end - point + Vector3.DOWN * 1.45, Vector3(1.05, 0.8, 1.05), leaves.lightened(i * 0.023), float(i))
		if mangrove:
			art.tube(point + outward * 1.0, point + Vector3(0.1, 1.3, 0), 0.11, bark, 0.09)
	canopy.pebble(Vector3(-0.1, 1.25, 0), Vector3(1.15, 0.85, 1.1), leaves.lightened(0.1), 8.0)
	art.instance(parent, "Branches")
	canopy.instance(crown, "Canopy")


## Небольшие куртины обрамляют берег, не загораживая рыбака и причалы.
static func shoreline(parent: Node3D, origin: Vector3, biome: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 810 + biome
	var stones := ArtMesh.new()
	for cluster in 22:
		var angle := cluster * 2.39996
		var radius := ShoreProfile.radius_at(angle)
		var point := origin + Vector3(cos(angle), 0, sin(angle)) * (radius - 1.6)
		point.y = 0.52
		if point.z < -7.0 and absf(point.x - origin.x) < 6.5:
			continue
		if biome == 1 and point.x - origin.x > 8 and absf(point.z) < 2:
			continue
		if cluster % 4 == 0 or biome == 2:
			for pebble in 3:
				stones.pebble(point + Vector3(rng.randf_range(-0.6, 0.6), -0.05, rng.randf_range(-0.4, 0.4)),
					Vector3(rng.randf_range(0.18, 0.42), 0.16, 0.28), Color("#82968a") if biome != 2 else Color("#7e959d"), cluster + pebble)
		if biome == 2:
			continue
		var tuft := Node3D.new()
		tuft.position = point
		tuft.set_script(preload("res://scripts/world/foliage_sway.gd"))
		tuft.strength = 0.055
		parent.add_child(tuft)
		var art := ArtMesh.new()
		for blade in 13:
			var start := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.3, 0.3))
			var height := rng.randf_range(0.35, 0.85)
			var bend := Vector3(rng.randf_range(-0.2, 0.2), height, rng.randf_range(-0.2, 0.2))
			var green := Color("#71845b").lightened(blade * 0.008)
			art.triangle(start + Vector3.LEFT * 0.045, start + bend, start + Vector3.RIGHT * 0.045, green)
			art.triangle(start + Vector3.FORWARD * 0.04, start + bend, start + Vector3.BACK * 0.04, green)
			if blade % 4 == 0:
				art.tube(start, start + bend * 1.15, 0.014, green, 0.009, 5)
				art.tube(start + bend, start + bend * 1.22, 0.045, Color("#9e845d"), 0.035, 5)
		art.instance(tuft, "Reeds")
	stones.instance(parent, "ShoreStones%d" % biome)


static func fir(parent: Node3D, point: Vector3) -> void:
	var art := ArtMesh.new()
	art.tube(point, point + Vector3.UP * 3.4, 0.18, Color("#776651"), 0.05)
	for layer in 3:
		var height := 1.15 + layer * 0.9
		var radius := 1.5 - layer * 0.35
		for i in 9:
			var a := TAU * i / 9.0
			var b := TAU * (i + 1) / 9.0
			var left := point + Vector3(cos(a) * radius, height, sin(a) * radius)
			var right := point + Vector3(cos(b) * radius, height, sin(b) * radius)
			var peak := point + Vector3.UP * (height + 1.4)
			art.triangle(left, peak, right, Color("#597e80"))
			art.triangle(left.lerp(peak, 0.16) + Vector3.UP * 0.06, peak + Vector3.UP * 0.06,
					right.lerp(peak, 0.16) + Vector3.UP * 0.06, Color("#bfd2d0"))
	art.instance(parent, "SnowFir")


static func scatter(parent: Node3D, origin: Vector3, biome: int) -> void:
	var art := ArtMesh.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1954 + biome
	for i in 95:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(7.0, 11.0)
		var point := origin + Vector3(cos(angle) * distance, 0.52, sin(angle) * distance)
		if point.z < -7.5 and absf(point.x - origin.x) < 6.0:
			continue
		if biome == 0 and (point.distance_to(Vector3(4.5, 0.5, -6)) < 3.0 or point.distance_to(Vector3(-5, 0.5, -6)) < 1.5):
			continue
		if i % 7 == 0:
			art.pebble(point, Vector3(rng.randf_range(0.25, 0.65), 0.3, 0.42), Color("#819089"), i)
		elif biome != 2:
			for blade in 4:
				var lean := Vector3(rng.randf_range(-0.17, 0.17), rng.randf_range(0.2, 0.45), rng.randf_range(-0.17, 0.17))
				art.triangle(point + Vector3(-0.04, 0, 0), point + lean, point + Vector3(0.04, 0, 0), Color("#66825c"))
				if i % 5 == 0:
					art.pebble(point + lean, Vector3(0.09, 0.06, 0.09), Color("#e8c27f") if i % 2 else Color("#cf9693"), i)
	art.instance(parent, "WildGarden%d" % biome)
