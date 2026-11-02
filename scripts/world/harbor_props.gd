class_name HarborProps
extends RefCounted
## Деревянные детали гавани собираются в единые меши с общей палитрой.

static func barrel(art: ArtMesh, point: Vector3, scale := 1.0) -> void:
	var wood := Color("#9b7954")
	art.tube(point, point + Vector3.UP * 0.4 * scale, 0.29 * scale, wood, 0.35 * scale, 10)
	art.tube(point + Vector3.UP * 0.4 * scale, point + Vector3.UP * 0.8 * scale, 0.35 * scale, wood, 0.29 * scale, 10)
	for y in [0.15, 0.65]:
		art.tube(point + Vector3.UP * y * scale, point + Vector3.UP * (y + 0.06) * scale, 0.34 * scale, Color("#586364"), -1.0, 10)


static func dock(parent: Node3D) -> void:
	parent.get_node("Pier").hide()
	var art := ArtMesh.new()
	for i in 16:
		art.box(Vector3(0, -0.08, 0.7 - i * 0.31), Vector3(2.8, 0.18, 0.285), Color("#a78a64").lightened((i % 4) * 0.018))
	for x in [-1.3, 1.3]:
		art.box(Vector3(x, -0.3, -1.6), Vector3(0.18, 0.22, 5.0), Color("#6b5946"))
		for z in [-0.3, -2.2, -3.9]:
			art.tube(Vector3(x, -1.2, z), Vector3(x, 0.55, z), 0.115, Color("#806a4e"))
			art.tube(Vector3(x, 0.52, z), Vector3(x, 0.62, z), 0.15, Color("#b9a47e"))
		for z in [-0.3, -2.2]:
			var a := Vector3(x, 0.42, z)
			var b := Vector3(x, 0.42, z - 1.7)
			var middle := a.lerp(b, 0.5) - Vector3.UP * 0.25
			art.tube(a, middle, 0.025, Color("#d5c49a"), -1.0, 5)
			art.tube(middle, b, 0.025, Color("#d5c49a"), -1.0, 5)
	barrel(art, Vector3(1.8, 0, 0.4), 0.8)
	art.instance(parent, "TimberPier")


static func shop(parent: Node3D) -> void:
	parent.get_node("Body/Counter").hide()
	parent.get_node("Body/Awning").hide()
	var art := ArtMesh.new()
	var wood := Color("#8f7152")
	art.box(Vector3(0, 0.45, 0), Vector3(2.35, 0.9, 0.95), Color("#6f5845"))
	for i in 9:
		art.box(Vector3(-1.08 + i * 0.27, 0.45, 0.5), Vector3(0.25, 0.83, 0.09), wood.lightened(i % 3 * 0.025))
	art.box(Vector3(0, 0.96, 0), Vector3(2.6, 0.15, 1.15), Color("#b19a74"))
	for i in 7:
		var color := Color("#507b72") if i % 2 == 0 else Color("#dfd4b2")
		var x := -1.23 + i * 0.41
		art.box(Vector3(x, 2.55, -0.12), Vector3(0.405, 0.09, 1.85), color, Vector3(0.18, 0, 0))
		art.box(Vector3(x, 2.28, 0.8), Vector3(0.405, 0.24, 0.05), color)
		art.pebble(Vector3(x, 2.16, 0.8), Vector3(0.2, 0.07, 0.026), color)
	art.box(Vector3(-0.5, 1.08, 0.1), Vector3(0.95, 0.15, 0.65), Color("#6e604c"))
	for i in 3:
		art.pebble(Vector3(-0.78 + i * 0.27, 1.2, 0.1), Vector3(0.1, 0.06, 0.25), Color("#8aabb0"), i)
	barrel(art, Vector3(1.7, 0, 0), 1.0)
	art.box(Vector3(-1.7, 0.3, 0), Vector3(0.7, 0.6, 0.65), Color("#a38a64"))
	for y in [0.15, 0.45]:
		art.box(Vector3(-1.7, y, 0.34), Vector3(0.72, 0.04, 0.03), Color("#6b5e46"))
	art.instance(parent, "LukasMarket")


static func garden(parent: Node3D) -> void:
	var art := ArtMesh.new()
	var wood := Color("#a69471")
	for x in range(-8, -2):
		art.box(Vector3(x, 0.95, 8), Vector3(0.12, 0.9, 0.12), wood)
	for y in [0.8, 1.2]:
		art.box(Vector3(-5.5, y, 8), Vector3(5.4, 0.1, 0.09), wood)
	for z in [5.0, 6.0, 7.0]:
		art.box(Vector3(-6, 0.53, z), Vector3(2.3, 0.06, 0.55), Color("#806b51"))
		for i in 6:
			var point := Vector3(-6.9 + i * 0.36, 0.65, z)
			art.pebble(point, Vector3(0.18, 0.12, 0.18), Color("#7e925b"), i)
	barrel(art, Vector3(-5.5, 0.5, 4.0))
	var center := Vector3(8.2, 0.5, 0.5)
	art.box(center + Vector3(0, 0.45, 0), Vector3(0.55, 0.12, 1.7), wood)
	art.box(center + Vector3(-0.25, 0.95, 0), Vector3(0.1, 0.7, 1.7), wood)
	for z in [-0.6, 0.6]:
		for x in [-0.2, 0.2]:
			art.box(center + Vector3(x, 0.2, z), Vector3(0.09, 0.4, 0.09), Color("#5e6251"))
	art.instance(parent, "HarborGarden")


static func lilies(parent: Node3D) -> void:
	var art := ArtMesh.new()
	for center in [Vector3(-12, 0.04, -12), Vector3(15, 0.04, 3)]:
		for i in 9:
			var point: Vector3 = center + Vector3(sin(i * 3.2), 0, cos(i * 2.7)) * (0.2 + i * 0.13)
			var radius := 0.23 + float(i % 3) * 0.06
			for side in 9:
				var a := TAU * (side + 0.4) / 10.0
				var b := TAU * (side + 1.4) / 10.0
				art.triangle(point, point + Vector3(cos(b), 0, sin(b)) * radius,
						point + Vector3(cos(a), 0, sin(a)) * radius, Color("#6b8c6b").lightened(i % 3 * 0.025))
			if i % 4 == 0:
				art.pebble(point + Vector3.UP * 0.07, Vector3(0.12, 0.06, 0.12), Color("#e1b4a5"))
	art.instance(parent, "WaterLilies").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
