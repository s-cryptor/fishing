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
	test_same_seed_same_outcome()
	test_missed_bite()
	test_idle_lets_fish_escape()
	test_always_reeling_snaps_strong_fish()
	test_luck_brings_rare_fish()
	test_bite_schedule()
	test_balance_curve()
	print("\n%s" % ("ВСЕ ТЕСТЫ ПРОЙДЕНЫ" if _failures == 0 else "ПРОВАЛОВ: %d" % _failures))
	quit(1 if _failures > 0 else 0)


func test_catalog_loaded() -> void:
	_check(CATALOG.fish.size() == 6, "в каталоге 6 видов")
	_check(CATALOG.for_habitat(&"lake").size() == 6, "все виды водятся в озере")


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
