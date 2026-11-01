extends SceneTree
## Headless-тесты логики вываживания и баланса.
## Запуск: godot --headless --path . -s res://tests/test_fishing_session.gd

const CATALOG: FishCatalog = preload("res://data/fish_catalog.tres")
const GEAR: GearStats = preload("res://data/gear/starter_rod.tres")
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
	test_bot_lands_fish()
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


func test_bot_lands_fish() -> void:
	print("\nБаланс: бот, стартовая удочка, макс. вес, заброс 12 м")
	for fish in CATALOG.fish:
		var caught := 0
		var total_time := 0.0
		for i in RUNS:
			var s := _session(fish.id, 1.0, i)
			var t := _fight_time(s)
			if s.state == FishingSession.State.CAUGHT:
				caught += 1
				total_time += t
		var rate := caught * 100 / RUNS
		print("  %-14s %-12s поймано %3d%%  среднее время %.1f с" % [
			fish.display_name, fish.rarity_name(), rate, total_time / maxi(caught, 1)])
		if fish.rarity <= FishData.Rarity.RARE:
			_check(rate == 100, "бот всегда вытаскивает: %s" % fish.display_name)
		else:
			_check(rate >= 30, "%s ловится хотя бы иногда" % fish.display_name)


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
