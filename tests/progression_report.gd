extends SceneTree
## Детерминированный отчёт темпа: 20 минут, реакция 0.25 с,
## продажа после каждого улова, 5 с на выбор места/заброс/карточку.
## Не заменяет живой плейтест: бот не тратит время на чтение и поиск пути.

const DT := 1.0 / 60.0
const DURATION := 1200.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state._store = SaveStore.new("user://pacing-report.json")
	for seed_value in 8:
		_reset(state)
		var elapsed := 0.0
		var casts := 0
		var catches := 0
		var habitat: StringName = &"lake"
		var unlocks: Dictionary = {}
		while elapsed < DURATION:
			elapsed += 5.0
			var phase := DayTime.phase_for_hour(fmod(7.0 + elapsed / 480.0 * 24.0, 24.0))
			var session := FishingSession.create(state.catalog, habitat, state.fishing_gear(habitat), 12.0,
					seed_value * 10000 + casts, phase)
			state.consume_bait()
			var bot := HumanPlayer.new(0.25, seed_value * 10000 + casts)
			while not session.is_finished() and elapsed < DURATION:
				var action := bot.wants_action(session, DT)
				if action and session.state == FishingSession.State.BITING:
					session.hook()
				session.tick(DT, action and session.state == FishingSession.State.FIGHTING)
				elapsed += DT
			casts += 1
			if session.state == FishingSession.State.CAUGHT:
				catches += 1
				state.register_catch(session.fish, session.weight_kg)
				state.sell_all()
			for rod in state.gear_catalog.rods:
				if not state.owns_gear(rod.id) and state.money >= rod.price:
					state.buy_gear(rod)
					unlocks[String(rod.id)] = roundi(elapsed)
					elapsed += 15.0
					break
			if not state.boat_upgraded and state.owned_gear.size() >= 2 and state.money >= state.BOAT.price:
				state.upgrade_boat()
				unlocks["boat"] = roundi(elapsed)
				habitat = &"mangrove"
				state.visit_biome(&"mangrove_shallows")
				elapsed += 25.0
			if habitat == &"mangrove" and state.owned_gear.size() >= 3:
				habitat = &"fjord"
				state.visit_biome(&"ice_fjord")
				unlocks["fjord"] = roundi(elapsed)
				elapsed += 20.0
			if state.bait_charges == 0 and state.money > 80 and state.owned_gear.size() >= 2:
				state.buy_bait()
		print("seed=%d: улов %d/%d · видов %d/13 · монет %d · открытия (сек): %s" % [
				seed_value, catches, casts, state.collection.size(), state.money, str(unlocks)])
	quit()


func _reset(state: Node) -> void:
	state.money = 0
	state.collection.clear()
	state.inventory.clear()
	state.claimed_goals.clear()
	state.visited_biomes.assign(["home_lake"])
	state.sales = 0
	state.bait_charges = 0
	state.bait_enabled = false
	state.boat_upgraded = false
	var starter := String(state.gear_catalog.rods[0].id)
	state.owned_gear.assign([starter])
	state.equipped_gear_id = starter
	state.orders = OrderBook.new(state.catalog)
	state.orders.refill()
