extends SceneTree
## Награды не дублируются при повторном улове, посещении и загрузке.
## Запуск: -s res://tests/test_progression.gd -- --save=user://progression-test.json --mute

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.money = 0
	state.collection.clear()
	state.inventory.clear()
	state.claimed_goals.clear()
	state.discovered_landmarks.clear()
	state.active_meal_id = ""
	state.meal_charges = 0
	state.meals_cooked = 0
	state.visited_biomes.assign(["home_lake"])
	state.sales = 0
	var starter := String(state.gear_catalog.rods[0].id)
	state.owned_gear.assign([starter])
	state.equipped_gear_id = starter
	var fish: FishData = state.catalog.get_fish(&"roach")
	state.register_catch(fish, fish.min_weight_kg)
	_check("first_catch" in state.claimed_goals, "первый улов открывает награду")
	var rewards: int = state.claimed_goals.size()
	state.register_catch(fish, fish.min_weight_kg)
	_check(state.claimed_goals.size() == rewards, "повторный улов не дублирует награду")
	state.register_catch(fish, fish.max_weight_kg)
	_check(state.last_catch_report["record"] and state.last_catch_report["trophy"], "рекорд и трофей отмечаются вместе")
	state.sell_all()
	_check("first_sale" in state.claimed_goals and state.sales == 1, "продажа открывает цель")
	state.sell_all()
	_check(state.sales == 1, "пустая продажа не считается")
	state.visit_biome(&"mangrove_shallows")
	var wallet: int = state.money
	state.visit_biome(&"mangrove_shallows")
	_check(state.money == wallet and "mangrove_visit" in state.claimed_goals, "путешествие награждается один раз")
	state._load()
	_check(state.money == wallet and "mangrove_visit" in state.claimed_goals, "награды переживают загрузку")
	for f in state.catalog.for_habitat(&"lake"):
		state.register_catch(f, f.min_weight_kg)
	_check("lake_collection" in state.claimed_goals and state.journey_progress("lake_species") == 6,
			"полная коллекция озера открывает награду")
	_check("mangrove_collection" not in state.claimed_goals, "озёрные рыбы не закрывают мангровую коллекцию")
	state.money = 0
	state.bait_charges = 0
	state.bait_enabled = false
	state.boat_upgraded = false
	_check(not state.buy_bait() and not state.upgrade_boat(), "без денег нельзя купить приманку и лодку")
	state.money = 1000
	_check(state.buy_bait() and state.bait_charges == state.BAIT.charges, "покупка выдаёт пачку приманки")
	var base: GearStats = state.gear
	var prepared: GearStats = state.fishing_gear(&"mangrove")
	_check(prepared.luck > base.luck and prepared.bite_time_mult < base.bite_time_mult,
			"приманка ускоряет клёв и повышает удачу на копии снасти")
	state.toggle_bait()
	state.consume_bait()
	_check(state.bait_charges == state.BAIT.charges and state.fishing_gear(&"lake").luck == base.luck,
			"выключенная приманка не расходуется и не даёт бонус")
	state.toggle_bait()
	state.consume_bait()
	_check(state.bait_charges == state.BAIT.charges - 1, "заброс расходует одну порцию")
	_check(state.upgrade_boat() and not state.upgrade_boat(), "лодку можно улучшить только один раз")
	var lake_gear: GearStats = state.fishing_gear(&"lake")
	var mangrove_gear: GearStats = state.fishing_gear(&"mangrove")
	_check(is_equal_approx(mangrove_gear.luck - lake_gear.luck, state.BOAT.scouting_luck),
			"лодка даёт бонус только в экспедиции")
	state._load()
	_check(state.boat_upgraded and state.bait_charges == state.BAIT.charges - 1,
			"лодка и остаток приманки переживают загрузку")
	for i in 20:
		state.consume_bait()
	_check(state.bait_charges == 0 and not state.bait_enabled, "последняя порция выключает приманку без отрицательного остатка")
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
