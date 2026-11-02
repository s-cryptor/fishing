class_name LandmarkArt
extends RefCounted
## Узнаваемые ориентиры островов. Арт и коллизии создаются вместе.

static func build(parent: Node3D, kind: LandmarkData.Kind) -> void:
	match kind:
		LandmarkData.Kind.LIGHTHOUSE: _lighthouse(parent)
		LandmarkData.Kind.BOATKEEPER_HUT: _hut(parent)
		LandmarkData.Kind.STONE_ARCH: _arch(parent)


static func _lighthouse(parent: Node3D) -> void:
	var art := ArtMesh.new()
	var stone := Color("#8d9688")
	var cream := Color("#ded2ae")
	var green := Color("#537b70")
	art.pebble(Vector3(0, 0.08, 0), Vector3(1.35, 0.2, 1.25), stone)
	for band in 4:
		var y := 0.15 + band * 0.83
		var radius := 0.95 - band * 0.065
		art.tube(Vector3(0, y, 0), Vector3(0, y + 0.83, 0), radius, cream if band % 2 == 0 else green, radius - 0.065, 12)
	art.box(Vector3(0, 0.65, 0.92), Vector3(0.48, 1.0, 0.09), Color("#506351"))
	for i in 5:
		art.box(Vector3(-0.19 + i * 0.095, 0.65, 0.976), Vector3(0.012, 0.9, 0.015), cream.darkened(0.3))
	art.pebble(Vector3(0.15, 0.65, 0.99), Vector3.ONE * 0.035, Color("#b9a469"))
	for y in [1.55, 2.5]:
		art.box(Vector3(0, y, 0.85 - y * 0.04), Vector3(0.28, 0.38, 0.06), Color("#31534f"))
		art.box(Vector3(0, y, 0.89 - y * 0.04), Vector3(0.035, 0.4, 0.025), cream)
	art.tube(Vector3(0, 3.48, 0), Vector3(0, 3.61, 0), 1.1, Color("#a9916b"), 1.1, 12)
	for i in 12:
		var a := TAU * i / 12
		var b := TAU * (i + 1) / 12
		var p := Vector3(cos(a), 0, sin(a)) * 1.03
		var q := Vector3(cos(b), 0, sin(b)) * 1.03
		art.tube(p + Vector3.UP * 3.6, p + Vector3.UP * 4.0, 0.025, green, 0.025, 5)
		art.tube(p + Vector3.UP * 4.0, q + Vector3.UP * 4.0, 0.025, green, 0.025, 5)
	for i in 6:
		var p := Vector3(cos(TAU * i / 6), 0, sin(TAU * i / 6)) * 0.58
		art.tube(p + Vector3.UP * 3.7, p + Vector3.UP * 4.62, 0.045, green, 0.045, 6)
	art.tube(Vector3(0, 4.6, 0), Vector3(0, 5.24, 0), 0.87, Color("#a86850"), 0, 12)
	art.tube(Vector3(0, 5.24, 0), Vector3(0, 5.52, 0), 0.03, green, 0.02, 6)
	art.box(Vector3(0, 0.05, 1.2), Vector3(0.8, 0.12, 0.55), stone)
	art.instance(parent, "HarborLighthouse")
	_box_collision(parent, Vector3(0, 1.6, 0), Vector3(1.7, 3.2, 1.7))
	var beacon := Node3D.new()
	beacon.position.y = 4.15
	beacon.set_script(preload("res://scripts/world/lighthouse_beacon.gd"))
	parent.add_child(beacon)


static func _hut(parent: Node3D) -> void:
	var art := ArtMesh.new()
	var wood := Color("#8a7354")
	var wall := Color("#729185")
	for x in [-1.2, 1.2]:
		for z in [-0.9, 0.9]:
			art.tube(Vector3(x, -0.1, z), Vector3(x, 2.3, z), 0.085, wood, 0.065)
	for plank in 12:
		art.box(Vector3(-1.45 + plank * 0.26, 0.4, 0.25), Vector3(0.24, 0.12, 2.7), wood.lightened((plank % 3) * 0.025))
	art.box(Vector3(0, 1.25, -0.2), Vector3(2.4, 1.65, 1.9), wall)
	for plank in 10:
		art.box(Vector3(-1.1 + plank * 0.245, 1.25, 0.78), Vector3(0.022, 1.6, 0.025), wall.darkened(0.2))
	art.box(Vector3(0.4, 1.1, 0.82), Vector3(0.7, 1.3, 0.08), Color("#50695c"))
	art.box(Vector3(-0.65, 1.45, 0.83), Vector3(0.55, 0.55, 0.08), Color("#36584e"))
	for x in [-0.95, -0.65, -0.35]:
		art.box(Vector3(x, 1.45, 0.89), Vector3(0.035, 0.6, 0.03), wood.lightened(0.25))
	for y in [1.15, 1.75]:
		art.box(Vector3(-0.65, y, 0.89), Vector3(0.63, 0.035, 0.03), wood.lightened(0.25))
	for strip in 13:
		var z := -1.35 + strip * 0.21
		var color := Color("#a79664").lightened((strip % 4) * 0.018)
		art.quad(Vector3(-1.55, 2.15, z + 0.2), Vector3(0, 3.1, z + 0.2), Vector3(0, 3.1, z), Vector3(-1.55, 2.15, z), color)
		art.quad(Vector3(0, 3.1, z + 0.2), Vector3(1.55, 2.15, z + 0.2), Vector3(1.55, 2.15, z), Vector3(0, 3.1, z), color.darkened(0.05))
	art.tube(Vector3(0, 3.12, -1.4), Vector3(0, 3.12, 1.4), 0.06, wood, 0.06)
	for step in 3:
		art.box(Vector3(0.4, 0.1 + step * 0.12, 1.8 - step * 0.25), Vector3(0.9, 0.16, 0.35), wood)
	HarborProps.barrel(art, Vector3(1.9, 0, -0.4), 0.8)
	# Сушильная рама и сеть — примета старой рыбацкой стоянки.
	for x in [-3.0, -1.8]:
		art.tube(Vector3(x, 0, 0), Vector3(x, 1.9, 0), 0.055, wood, 0.04)
	art.tube(Vector3(-3, 1.85, 0), Vector3(-1.8, 1.85, 0), 0.055, wood, 0.04)
	for i in 7:
		var x := -2.95 + i * 0.18
		art.tube(Vector3(x, 0.5, 0), Vector3(x, 1.8, 0), 0.009, Color("#bbba91"), 0.009, 4)
	for i in 7:
		var y := 0.5 + i * 0.2
		art.tube(Vector3(-2.95, y, 0), Vector3(-1.85, y, 0), 0.009, Color("#bbba91"), 0.009, 4)
	art.instance(parent, "BoatkeepersHut")
	_box_collision(parent, Vector3(0, 1.1, 0.25), Vector3(3.1, 2.2, 2.7))
	var lantern := Node3D.new()
	lantern.position = Vector3(1.35, 0.4, 0.85)
	lantern.scale = Vector3.ONE * 0.4
	lantern.set_script(preload("res://scripts/world/harbor_lantern.gd"))
	parent.add_child(lantern)


static func _arch(parent: Node3D) -> void:
	var art := ArtMesh.new()
	var stone := Color("#7c9297")
	var snow := Color("#c9d9d3")
	for side in [-1, 1]:
		for block in 3:
			art.pebble(Vector3(side * 1.5, 0.3 + block * 0.58, 0), Vector3(0.5, 0.43, 0.62), stone.lightened(block * 0.02), side * 7 + block)
		art.pebble(Vector3(side * 1.7, 0.1, 0.1), Vector3(0.85, 0.3, 0.9), stone, side)
		_box_collision(parent, Vector3(side * 1.5, 1.2, 0), Vector3(0.9, 2.4, 1.1))
	for block in 9:
		var angle := PI * (block + 0.5) / 9
		var point := Vector3(cos(angle) * 1.5, 1.7 + sin(angle) * 1.5, 0)
		art.pebble(point, Vector3(0.48, 0.52, 0.65), stone.lightened((block % 3) * 0.025), block * 2.3)
		art.pebble(point + Vector3.UP * 0.34, Vector3(0.44, 0.16, 0.62), snow, block)
	art.box(Vector3(0, 0.45, 0.1), Vector3(0.55, 0.9, 0.45), stone.darkened(0.12))
	art.box(Vector3(0, 0.55, 0.34), Vector3(0.34, 0.32, 0.025), Color("#b19c6c"))
	art.instance(parent, "StoneSail")
	_box_collision(parent, Vector3(0, 0.45, 0.1), Vector3(0.6, 0.9, 0.5))


static func _box_collision(parent: Node3D, point: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = point
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
