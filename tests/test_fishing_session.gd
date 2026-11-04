extends SceneTree
## Headless-тесты логики вываживания и баланса.
## Запуск: godot --headless --path . -s res://tests/test_fishing_session.gd

const CATALOG: FishCatalog = preload("res://data/fish_catalog.tres")
const GEAR: GearStats = preload("res://data/gear/bamboo_rod.tres")
const GEAR_CATALOG: GearCatalog = preload("res://data/gear_catalog.tres")
const Balance := preload("res://tests/balance_report.gd")
const DT := 1.0 / 60.0
const MAX_TIME := 180.0
const RUNS := 100

var _failures := 0


func _initialize() -> void:
	test_catalog_loaded()
	test_biomes_have_fish()
	test_same_seed_same_outcome()
	test_missed_bite()
	test_idle_lets_fish_escape()
	test_always_reeling_snaps_strong_fish()
	test_thrash_warning()
	test_control_bonus()
	test_landing_at_shore()
	test_luck_brings_rare_fish()
	test_bite_schedule()
	test_orders()
	test_balance_curve()
	print("\n%s" % ("ВСЕ ТЕСТЫ ПРОЙДЕНЫ" if _failures == 0 else "ПРОВАЛОВ: %d" % _failures))
	quit(1 if _failures > 0 else 0)


func test_catalog_loaded() -> void:
	_check(CATALOG.fish.size() == 14, "в каталоге 14 видов")
	_check(CATALOG.for_habitat(&"lake").size() == 6, "все виды водятся в озере")
	_check(CATALOG.for_habitat(&"mangrove").size() == 5, "в манграх 5 видов")
	_check(CATALOG.for_habitat(&"fjord").size() == 3, "во фьорде 3 вида")


func test_biomes_have_fish() -> void:
	for habitat in [&"lake", &"mangrove", &"fjord"]:
		for phase in DayTime.Phase.values():
			_check(not CATALOG.biting(habitat, phase).is_empty(),
					"%s: есть клёв в фазе %s" % [habitat, DayTime.PHASE_NAMES[phase]])


func test_same_seed_same_outcome() -> void:
	var a := _play(FishingSession.create(CATALOG, &"lake", GEAR, 10.0, 42), AutoPlayer.wants_action)
	var b := _play(FishingSession.create(CATALOG, &"lake", GEAR, 10.0, 42), AutoPlayer.wants_action)
	_check(a.fish == b.fish and a.weight_kg == b.weight_kg and a.state == b.state
			and is_equal_approx(a.distance, b.distance), "один seed — одинаковый исход")


func test_missed_bite() -> void:
	var s := _play(_session(&"roach", 1.0, 1), func(_s: FishingSession) -> bool: return false)
	_check(s.state == FishingSession.State.MISSED, "без подсечки поклёвка прозевана")


func test_idle_lets_fish_escape() -> void:
	var s := _play(_session(&"roach", 0.5, 1),
			func(x: FishingSession) -> bool: return x.state == FishingSession.State.BITING)
	_check(s.state == FishingSession.State.ESCAPED, "без подмотки рыба сходит")


func test_always_reeling_snaps_strong_fish() -> void:
	var snapped := 0
	for i in RUNS:
		var s := _play(_session(&"catfish", 1.0, i), func(_s: FishingSession) -> bool: return true)
		if s.state == FishingSession.State.SNAPPED:
			snapped += 1
	_check(snapped > RUNS * 0.9, "сом рвёт леску, если тупо мотать (%d%%)" % (snapped * 100 / RUNS))


func test_thrash_warning() -> void:
	var s := _session(&"pike", 0.5, 21)
	_check(not s.is_telegraphing(), "до подсечки нет ложного предупреждения о рывке")
	while s.state == FishingSession.State.WAITING:
		s.tick(DT, false)
	s.hook()
	var events: Array[String] = []
	s.thrash_warned.connect(func() -> void: events.append("warning"))
	s.thrash_started.connect(func() -> void: events.append("thrash"))
	var warning_time := -1.0
	var time := 0.0
	while not s.is_thrashing and time < 10:
		s.tick(DT, true)
		time += DT
		if s.is_telegraphing() and warning_time < 0:
			warning_time = time
	_check(events == ["warning", "thrash"], "перед рывком ровно одно предупреждение")
	_check(absf(time - warning_time - FishingSession.THRASH_WARNING) < DT * 2,
		"предупреждение оставляет 0.45 секунды на реакцию")
	_check(not s.is_telegraphing(), "во время рывка предупреждение снято")
	# Следующий цикл должен снова предупредить, но не создавать спам каждый кадр.
	while events.size() < 4 and time < 20 and not s.is_finished():
		s.tick(DT, s.tension < 0.7)
		time += DT
	_check(events == ["warning", "thrash", "warning", "thrash"], "предупреждение повторяется на следующем рывке")


func test_control_bonus() -> void:
	var steady := _session(&"roach", 0.5, 11)
	var plain := _session(&"roach", 0.5, 11)
	for s in [steady, plain]:
		while s.state == FishingSession.State.WAITING:
			s.tick(DT, false)
		s.hook()
		# Изолируем спокойную подмотку от случайного расписания рывков.
		s._thrash_timer = 20.0
	for i in 90:
		plain.control = 0
		steady.tick(DT, true)
		plain.tick(DT, true)
	_check(steady.control > 0.99, "бонус контроля постепенно набирается в светлой зоне")
	_check(steady.distance < plain.distance and steady.stamina < plain.stamina,
		"контроль ускоряет подмотку и утомляет рыбу")
	steady.tick(0.1, false)
	_check(steady.control < 1.0, "без подмотки накопленный контроль затухает")
	steady.is_thrashing = true
	steady.control = 1.0
	var before := steady.distance
	var expected_speed := steady.gear.reel_speed - steady.current_pull() * FishingSession.FISH_SWIM_SPEED
	steady.tick(DT, true)
	_check(not steady.in_control_zone() and absf(steady.distance - (before - expected_speed * DT)) < 0.001,
		"рывок отключает бонус: накопить его и мотать сквозь рывок нельзя")
	var frozen := steady.control
	steady.state = FishingSession.State.CAUGHT
	steady.tick(2.0, true)
	_check(steady.control == frozen and not steady.is_telegraphing(), "завершённая сессия больше не меняется")


func test_landing_at_shore() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var fish := CATALOG.get_fish(&"roach")
	var s := FishingSession.new(fish, 0.3, 12.0, GEAR, rng, 4.5)
	_check(is_equal_approx(s.distance_to_land(), 7.5), "до берега считается оставшаяся водная дистанция")
	_play(s, AutoPlayer.wants_action)
	_check(s.state == FishingSession.State.CAUGHT and s.distance > 4.0,
		"сессия заканчивается у переданной кромки берега")
	_check(s.distance_to_land() == 0.0, "пойманная рыба находится у берега")


func test_orders() -> void:
	var book := OrderBook.new(CATALOG)
	book.refill()
	_check(book.orders.size() == OrderBook.ACTIVE_ORDERS, "выдано %d заказа" % OrderBook.ACTIVE_ORDERS)
	var again := OrderBook.new(CATALOG)
	again.refill()
	_check(again.orders == book.orders, "заказы детерминированы")
	for i in OrderBook.TUTORIAL_ORDERS:
		var first_fish := CATALOG.get_fish(StringName(book.orders[i]["fish_id"]))
		_check(first_fish.rarity == FishData.Rarity.COMMON, "обучающий заказ %d — на обычную рыбу" % (i + 1))
		_check(&"lake" in first_fish.habitats, "обучающий заказ доступен на родном озере")

	var feasible := true
	for i in 500:
		var order := book.generate(i)
		var fish := CATALOG.get_fish(StringName(order["fish_id"]))
		feasible = feasible and order["min_kg"] < fish.max_weight_kg and order["reward"] > 0
	_check(feasible, "требуемый вес всегда достижим")
	var locked_orders := false
	for i in 500:
		locked_orders = locked_orders or &"fjord" in CATALOG.get_fish(StringName(book.generate(i)["fish_id"])).habitats
	_check(not locked_orders, "до улучшения лодки заказы не требуют рыбу фьорда")
	book.available_habitats.append(&"fjord")
	var northern_orders := false
	for i in 500:
		northern_orders = northern_orders or &"fjord" in CATALOG.get_fish(StringName(book.generate(i)["fish_id"])).habitats
	_check(northern_orders, "после открытия фьорда появляются северные заказы")

	var order: Dictionary = book.orders[0]
	var fish := CATALOG.get_fish(StringName(order["fish_id"]))
	book.register_catch(fish, order["min_kg"] - 0.05)
	_check(int(order["progress"]) == 0, "лёгкая рыба не засчитывается")
	var completed: Array[Dictionary] = []
	for i in int(order["count"]):
		completed = book.register_catch(fish, order["min_kg"] + 0.01)
	_check(completed.size() == 1 and completed[0] == order and not order in book.orders,
			"заказ выполняется ровно на нужной рыбе")
	_check(book.refill() and book.orders.size() == OrderBook.ACTIVE_ORDERS, "на место выполненного приходит новый")

	var restored := OrderBook.new(CATALOG)
	restored.load_dict(JSON.parse_string(JSON.stringify(book.to_dict())))
	_check(restored.orders.size() == book.orders.size() and restored.issued == book.issued, "заказы переживают сохранение")


func test_bite_schedule() -> void:
	for phase in DayTime.Phase.values():
		_check(not CATALOG.biting(&"lake", phase).is_empty(),
				"%s: кто-то клюёт" % DayTime.PHASE_NAMES[phase])
	var night := CATALOG.biting(&"lake", DayTime.Phase.NIGHT).map(func(f: FishData) -> StringName: return f.id)
	_check(&"catfish" in night and not &"pike" in night, "ночью клюёт сом, но не щука")
	var day := CATALOG.biting(&"lake", DayTime.Phase.DAY).map(func(f: FishData) -> StringName: return f.id)
	_check(not &"golden_carp" in day and not &"catfish" in day, "днём нет ни карпа, ни сома")
	for i in 300:
		var fish := FishingSession.create(CATALOG, &"lake", GEAR, 10.0, i, DayTime.Phase.NIGHT).fish
		if not fish.is_active(DayTime.Phase.NIGHT):
			_check(false, "ночью попался %s" % fish.display_name)
			return
	_check(DayTime.phase_for_hour(6.0) == DayTime.Phase.DAWN and DayTime.phase_for_hour(23.5) == DayTime.Phase.NIGHT
			and DayTime.phase_for_hour(2.0) == DayTime.Phase.NIGHT, "часы → части суток")


func test_luck_brings_rare_fish() -> void:
	var lucky := GEAR.duplicate() as GearStats
	lucky.luck += 1.0
	var plain_rare := _rare_share(GEAR)
	var lucky_rare := _rare_share(lucky)
	_check(lucky_rare > plain_rare * 1.5, "удача повышает долю редких: %.1f%% → %.1f%%" % [
		plain_rare * 100.0, lucky_rare * 100.0])


func _rare_share(gear: GearStats) -> float:
	var rare := 0
	for i in 2000:
		if FishingSession.create(CATALOG, &"lake", gear, 10.0, i).fish.rarity >= FishData.Rarity.RARE:
			rare += 1
	return rare / 2000.0


## Кривая сложности для «человека» (реакция ~0.25 с): обычные рыбы ловятся
## всегда, редкие требуют апгрейда, лучшая удочка вытаскивает всех.
func test_balance_curve() -> void:
	var rods := GEAR_CATALOG.rods
	for fish in CATALOG.fish:
		var rates: Array[float] = []
		for rod in rods:
			rates.append(Balance.catch_rate(fish, rod, 100))
		print("  %-14s %s" % [fish.display_name, "  ".join(rates.map(func(r: float) -> String: return "%3d%%" % roundi(r * 100.0)))])
		if fish.rarity <= FishData.Rarity.UNCOMMON:
			_check(rates[0] >= 0.95, "%s ловится почти всегда даже бамбуковой" % fish.display_name)
		else:
			_check(rates[0] <= 0.8, "%s на бамбуковой — испытание" % fish.display_name)
		_check(rates.back() >= 0.9, "%s ловится лучшей удочкой" % fish.display_name)
		var monotonic := true
		for i in range(1, rates.size()):
			monotonic = monotonic and rates[i] >= rates[i - 1] - 0.05
		_check(monotonic, "%s: каждая удочка не хуже предыдущей" % fish.display_name)


## Сессия с конкретной рыбой; weight_norm 0..1 внутри диапазона вида.
func _session(id: StringName, weight_norm: float, seed_value: int) -> FishingSession:
	var fish := CATALOG.get_fish(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FishingSession.new(fish, lerpf(fish.min_weight_kg, fish.max_weight_kg, weight_norm), 12.0, GEAR, rng)


func _play(s: FishingSession, policy: Callable) -> FishingSession:
	_fight_time(s, policy)
	return s


func _fight_time(s: FishingSession, policy: Callable = AutoPlayer.wants_action) -> float:
	var t := 0.0
	var fight_start := 0.0
	while not s.is_finished() and t < MAX_TIME:
		var action: bool = policy.call(s)
		if action and s.state == FishingSession.State.BITING:
			s.hook()
			fight_start = t
		s.tick(DT, action and s.state == FishingSession.State.FIGHTING)
		t += DT
	return t - fight_start


func _check(ok: bool, name: String) -> void:
	print("%s %s" % ["  ok " if ok else "FAIL", name])
	if not ok:
		_failures += 1
