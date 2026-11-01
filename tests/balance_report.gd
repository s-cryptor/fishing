extends SceneTree
## Таблица баланса: какой процент рыбы вытаскивает «человек» с каждой удочкой.
## Запуск: godot --headless --path . -s res://tests/balance_report.gd

const FISH: FishCatalog = preload("res://data/fish_catalog.tres")
const GEAR: GearCatalog = preload("res://data/gear_catalog.tres")
const DT := 1.0 / 60.0
const RUNS := 300


func _initialize() -> void:
	var header := "%-14s" % ""
	for rod in GEAR.rods:
		header += "%12s" % String(rod.id)
	print(header)
	for fish in FISH.fish:
		var row := "%-14s" % fish.display_name
		for rod in GEAR.rods:
			row += "%11d%%" % roundi(catch_rate(fish, rod) * 100.0)
		print(row)
	quit()


## Доля пойманных рыб вида при случайном весе и забросе на 80% дальности.
static func catch_rate(fish: FishData, rod: GearStats, runs := RUNS, reaction := 0.25) -> float:
	var caught := 0
	for i in runs:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		var weight := lerpf(fish.min_weight_kg, fish.max_weight_kg, pow(rng.randf(), 2.0))
		var session := FishingSession.new(fish, weight, rod.max_cast_m * 0.8, rod, rng)
		if play(session, HumanPlayer.new(reaction, i)) == FishingSession.State.CAUGHT:
			caught += 1
	return float(caught) / runs


static func play(session: FishingSession, player: HumanPlayer) -> FishingSession.State:
	var t := 0.0
	while not session.is_finished() and t < 300.0:
		var action := player.wants_action(session, DT)
		if action and session.state == FishingSession.State.BITING:
			session.hook()
		session.tick(DT, action and session.state == FishingSession.State.FIGHTING)
		t += DT
	return session.state
