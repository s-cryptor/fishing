class_name DayTime
## Части суток и их битовые флаги (для FishData.active_times).

enum Phase { DAWN, DAY, DUSK, NIGHT }

const PHASE_NAMES: Array[String] = ["Рассвет", "День", "Закат", "Ночь"]
const ALL_PHASES := 0b1111

## Начало каждой части суток, часы.
const DAWN_START := 5.0
const DAY_START := 8.0
const DUSK_START := 18.0
const NIGHT_START := 21.0


static func phase_for_hour(hour: float) -> Phase:
	if hour >= DAWN_START and hour < DAY_START:
		return Phase.DAWN
	if hour >= DAY_START and hour < DUSK_START:
		return Phase.DAY
	if hour >= DUSK_START and hour < NIGHT_START:
		return Phase.DUSK
	return Phase.NIGHT


static func flag(phase: Phase) -> int:
	return 1 << phase


## Сколько игровых часов до ближайшего клёва, с переходом через полночь.
static func hours_until_active(flags: int, hour: float) -> float:
	if flags & ALL_PHASES == 0:
		return -1.0
	var normalized := fposmod(hour, 24.0)
	if flags & flag(phase_for_hour(normalized)):
		return 0.0
	var result := 24.0
	var starts := [DAWN_START, DAY_START, DUSK_START, NIGHT_START]
	for phase in Phase.values():
		if flags & flag(phase):
			result = minf(result, fposmod(starts[phase] - normalized, 24.0))
	return result


## «Рассвет, закат» по набору флагов.
static func describe(flags: int) -> String:
	if flags & ALL_PHASES == ALL_PHASES:
		return "в любое время"
	var names: Array[String] = []
	for phase in Phase.values():
		if flags & flag(phase):
			names.append(PHASE_NAMES[phase].to_lower())
	return ", ".join(names)
