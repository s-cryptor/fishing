extends SceneTree
## Геометрия трофеев, ограничение бюджета и отключение скрытого просмотра.

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	var shapes: Dictionary = {}
	for fish in state.catalog.fish:
		var model := FishModel.new()
		root.add_child(model)
		model.build(fish)
		var finite := true
		var vertices := 0
		var fingerprint := 0
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		for mesh: MeshInstance3D in meshes:
			for surface in mesh.mesh.get_surface_count():
				var array := mesh.mesh.surface_get_arrays(surface)
				var positions: PackedVector3Array = array[Mesh.ARRAY_VERTEX]
				vertices += positions.size()
				fingerprint = hash([fingerprint, positions, array[Mesh.ARRAY_COLOR]])
				for point in positions:
					finite = finite and point.is_finite()
		_check(finite and vertices > 500 and vertices < 15000 and meshes.size() == 4,
			"%s: конечная геометрия, 4 меша, %d вершин" % [fish.id, vertices])
		_check(not shapes.has(fingerprint), "%s отличается геометрией или окраской от остальных видов" % fish.id)
		shapes[fingerprint] = fish.id
		var old_tail: float = model._tail.rotation.y
		model._process(0.2)
		_check(model._tail.rotation.y != old_tail and not is_zero_approx(model._pectoral[0].rotation.x),
			"%s: хвост и грудные плавники двигаются независимо" % fish.id)
		model.build(fish)
		_check(model.get_child_count() == 4, "%s: повторная сборка не накапливает меши" % fish.id)
		model.queue_free()
		await process_frame
	var showcase := FishShowcase.new()
	showcase.hide()
	root.add_child(showcase)
	showcase.fish = state.catalog.get_fish(&"perch")
	_check(not showcase._model.is_processing() and showcase._viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"пересборка скрытого трофея не включает анимацию и рендер")
	showcase.show()
	_check(showcase._model.is_processing(), "открытие возобновляет анимацию модели")
	var yaw: float = showcase._yaw
	Input.action_press(&"camera_right")
	showcase._process(0.25)
	Input.action_release(&"camera_right")
	_check(showcase._yaw > yaw + 0.4, "правый стик и Q/R вращают трофей")
	showcase.grab_focus()
	yaw = showcase._yaw
	Input.action_press(&"ui_left")
	showcase._process(0.25)
	Input.action_release(&"ui_left")
	_check(showcase._yaw < yaw - 0.4, "сфокусированный трофей управляется крестовиной")
	showcase.fish = null
	_check(showcase._model == null, "пустой вид безопасно убирает предыдущую модель")
	showcase.queue_free()
	await process_frame
	quit(1 if _failures else 0)

func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
