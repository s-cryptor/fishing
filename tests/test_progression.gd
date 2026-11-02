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
	state.visited_biomes.assign(["home_lake"])
	state.sales = 0
	state.owned_gear.assign(["bamboo_rod"])
	state.equipped_gear_id = "bamboo_rod"
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
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
