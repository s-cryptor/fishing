class_name FishingSession
extends RefCounted
## Логика одного заброса: ожидание поклёвки, подсечка и вываживание.
##
## Не знает ни про сцену, ни про ввод: состояние меняется только через
## tick() и hook(). Весь заброс определяется одним seed, поэтому сессию
## можно переиграть на сервере (турниры), в реплее или в балансном тесте.

signal state_changed(new_state: State)
signal thrash_started

enum State { WAITING, BITING, FIGHTING, CAUGHT, MISSED, ESCAPED, SNAPPED }

## Натяжение, при котором леска рвётся, если держится дольше SNAP_GRACE.
const SNAP_TENSION := 1.0
const SNAP_GRACE := 0.3
## Ниже этого натяжения леска провисает; дольше SLACK_GRACE — рыба сходит.
const SLACK_TENSION := 0.08
const SLACK_GRACE := 2.5
## Натяжение от самой подмотки, без сопротивления рыбы.
const REEL_TENSION := 0.35
## Насколько тяга рыбы добавляет натяжения при подмотке и без неё.
const REEL_PULL_FACTOR := 1.6
const IDLE_PULL_FACTOR := 0.5
## Скорость роста натяжения: базовая + доля от тяги (сильная рыба дёргает резче).
const TENSION_RISE_BASE := 1.5
const TENSION_RISE_PER_PULL := 2.5
const TENSION_FALL_RATE := 1.5
## Скорость, с которой рыба уходит прочь при полной тяге, м/с.
const FISH_SWIM_SPEED := 3.5
const LANDED_DISTANCE := 0.6

var state := State.WAITING
var fish: FishData
var weight_kg: float
var gear: GearStats
## Расстояние от игрока до рыбы, м.
var distance: float
var tension := 0.0
var stamina: float
var is_thrashing := false

var _rng: RandomNumberGenerator
var _timer: float
var _thrash_timer := 0.0
var _overload_time := 0.0
var _slack_time := 0.0
## Сила конкретной особи: сила вида с поправкой на вес.
var _power: float


## Выбирает рыбу и вес по seed. Возвращает null, если в водоёме никто не водится.
static func create(catalog: FishCatalog, habitat: StringName, p_gear: GearStats,
		cast_distance: float, seed_value: int) -> FishingSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool := catalog.for_habitat(habitat)
	if pool.is_empty():
		return null
	var weights := PackedFloat32Array()
	for f in pool:
		weights.append(f.spawn_weight * (1.0 + p_gear.luck * f.rarity))
	var picked := pool[rng.rand_weighted(weights)]
	# Квадрат смещает вес к лёгким особям: крупные встречаются реже.
	var weight := lerpf(picked.min_weight_kg, picked.max_weight_kg, pow(rng.randf(), 2.0))
	return FishingSession.new(picked, weight, cast_distance, p_gear, rng)


func _init(p_fish: FishData, p_weight: float, cast_distance: float, p_gear: GearStats,
		rng: RandomNumberGenerator) -> void:
	fish = p_fish
	weight_kg = p_weight
	distance = cast_distance
	gear = p_gear
	_rng = rng
	stamina = fish.stamina
	var weight_norm := inverse_lerp(fish.min_weight_kg, fish.max_weight_kg, weight_kg)
	_power = fish.strength * lerpf(0.75, 1.25, weight_norm)
	_timer = _rng.randf_range(2.0, 6.0) * gear.bite_time_mult


func is_finished() -> bool:
	return state >= State.CAUGHT


func stamina_ratio() -> float:
	return stamina / fish.stamina


func value() -> int:
	return fish.value_for(weight_kg)


## Окно на подсечку: у редких рыб короче.
func bite_window() -> float:
	return lerpf(1.0, 0.55, fish.rarity / 4.0)


## Текущая тяга рыбы 0..~1.25: рывки сильнее, усталость ослабляет.
func current_pull() -> float:
	var fatigue := lerpf(0.3, 1.0, stamina_ratio())
	return _power * fatigue * (1.0 if is_thrashing else 0.35)


## Подсечка. Срабатывает только во время поклёвки.
func hook() -> bool:
	if state != State.BITING:
		return false
	tension = REEL_TENSION
	_thrash_timer = _next_thrash_delay()
	_set_state(State.FIGHTING)
	return true


func tick(delta: float, reeling: bool) -> void:
	match state:
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_timer = bite_window()
				_set_state(State.BITING)
		State.BITING:
			_timer -= delta
			if _timer <= 0.0:
				_set_state(State.MISSED)
		State.FIGHTING:
			_tick_fight(delta, reeling)


func _tick_fight(delta: float, reeling: bool) -> void:
	_update_thrash(delta)
	var pull := current_pull()

	var target := (REEL_TENSION + pull * REEL_PULL_FACTOR) if reeling else pull * IDLE_PULL_FACTOR
	target /= gear.line_strength
	var rate := TENSION_RISE_BASE + pull * TENSION_RISE_PER_PULL if target > tension else TENSION_FALL_RATE
	tension = move_toward(tension, target, rate * delta)

	var reel_speed := gear.reel_speed if reeling else 0.0
	distance = clampf(distance - (reel_speed - pull * FISH_SWIM_SPEED) * delta, 0.0, gear.max_line_m)

	# Под натяжением рыба выдыхается быстрее.
	stamina = maxf(stamina - delta * (0.3 + tension), 0.0)

	_overload_time = _overload_time + delta if tension >= SNAP_TENSION else 0.0
	_slack_time = _slack_time + delta if tension <= SLACK_TENSION else 0.0

	if _overload_time >= SNAP_GRACE or distance >= gear.max_line_m:
		_set_state(State.SNAPPED)
	elif _slack_time >= SLACK_GRACE:
		_set_state(State.ESCAPED)
	elif distance <= LANDED_DISTANCE:
		_set_state(State.CAUGHT)


func _update_thrash(delta: float) -> void:
	_thrash_timer -= delta
	if _thrash_timer > 0.0:
		return
	is_thrashing = not is_thrashing
	if is_thrashing:
		_thrash_timer = _rng.randf_range(0.6, 1.4)
		thrash_started.emit()
	else:
		_thrash_timer = _next_thrash_delay()


## Уставшая рыба дёргается реже.
func _next_thrash_delay() -> float:
	return _rng.randf_range(0.5, 1.5) / (fish.thrash_rate * lerpf(0.4, 1.0, stamina_ratio()))


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)
