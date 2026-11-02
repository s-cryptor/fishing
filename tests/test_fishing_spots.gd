extends SceneTree
## Рыбное место сохраняется во время заброса, точность усиливает бонус на копии снасти.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	await create_timer(1.0).timeout
	var spot := scene.get_node("Lake/Spot1") as FishingSpot
	var point := spot.global_position
	_check(spot.contains(point) and spot.is_precise(point), "центр стаи доступен для точного заброса")
	_check(spot.contains(point + Vector3.RIGHT * spot.radius * 0.9)
		and not spot.is_precise(point + Vector3.RIGHT * spot.radius * 0.31), "край рыбного места не считается точным попаданием")
	_check(not spot.contains(point + Vector3.RIGHT * (spot.radius + 0.1)), "за пределами кольца бонус не выдаётся")
	var gear: GearStats = load("res://data/gear/bamboo_rod.tres")
	var original_luck := gear.luck
	var original_bite := gear.bite_time_mult
	var normal := spot.boost(gear)
	var precise := spot.boost(gear, true)
	_check(precise.luck > normal.luck and precise.bite_time_mult < normal.bite_time_mult, "точное попадание даёт дополнительную удачу и ускоряет клёв")
	_check(gear.luck == original_luck and gear.bite_time_mult == original_bite and precise != gear,
		"бонусы не меняют общий ресурс удочки")
	_check(spot.reserve() and not spot.reserve(), "место можно занять только один раз")
	spot._lifetime = 0.01
	spot._process(1.0)
	_check(spot.global_position == point and not spot._relocating and not spot.contains(point), "занятая стая не переезжает по таймеру и не выбирается повторно")
	spot.release()
	spot._process(0.1)
	_check(spot._relocating, "освобождённая просроченная стая начинает переезд")
	await create_timer(1.6).timeout
	_check(not spot._relocating and spot.global_position.distance_to(point) > 0.1, "после переезда стая снова доступна")
	var controller: Node = scene.get_node("FishingController")
	var player: Node3D = scene.get_node("Player")
	player.position = Vector3(0, 0.6, -9)
	await physics_frame
	var state := root.get_node("GameState")
	state.equipped_gear_id = "bamboo"
	controller._start_charge()
	controller._charge_time = 0.6
	var distance := lerpf(gear.min_cast_m, gear.max_cast_m, 0.6)
	spot.global_position = Vector3(0, 0.02, -9) + Vector3.FORWARD * distance
	controller._release_cast()
	_check(controller._spot == spot and spot._reserved, "контроллер резервирует стаю при успешном забросе")
	_check(controller.session.gear.luck >= gear.luck + spot.luck_bonus + spot.precision_luck_bonus,
		"попадание в центр передаёт точный бонус в сессию")
	await create_timer(0.8).timeout
	controller._end_session()
	controller._to_idle()
	_check(not spot._reserved and not spot._relocating, "сматывание освобождает стаю без истощения")
	point = spot.global_position
	spot.reserve()
	spot.deplete()
	_check(not spot._reserved and spot._relocating, "улов истощает даже занятую стаю")
	await create_timer(1.6).timeout
	_check(spot.global_position.distance_to(point) > 0.1, "после улова стая появляется в новом месте")
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
