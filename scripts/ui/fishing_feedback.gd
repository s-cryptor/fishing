class_name FishingFeedback
extends RefCounted
## Единая тактическая подсказка для HUD и тач-кнопки; не меняет сессию.

const CALM := Color("#c6d5bd")
const WARNING := Color("#edc684")
const DANGER := Color("#edaa8e")
const CONTROL := Color("#cadd9e")


static func fight(session: FishingSession) -> Dictionary:
	var result := {"label": "ТЯНИ", "detail": "удерживай", "status": "Подматывай · светлая зона даёт бонус контроля",
		"color": CALM, "progress": clampf(session.tension, 0.0, 1.0)}
	if session.tension >= TensionMeter.DANGER_FROM:
		result.merge({"label": "ОТПУСТИ", "detail": "леска на пределе", "status": "ОТПУСТИ · леска на пределе!", "color": DANGER}, true)
	elif session.tension <= FishingSession.SLACK_TENSION:
		result.merge({"detail": "не дай провиснуть", "status": "ПОДМАТЫВАЙ · не дай леске провиснуть"}, true)
	elif session.is_thrashing:
		result.merge({"label": "ОТПУСТИ", "detail": "рывок рыбы", "status": "РЫВОК · отпусти и дай рыбе выдохнуться", "color": WARNING}, true)
	elif session.is_telegraphing():
		result.merge({"label": "ГОТОВЬСЯ", "detail": "к рывку", "status": "Готовится рывок · будь готов отпустить", "color": WARNING,
			"progress": session.telegraph_progress()}, true)
	elif session.control >= 0.8:
		var bonus := roundi(session.control * FishingSession.CONTROL_REEL_BONUS * 100)
		result.merge({"label": "ДЕРЖИ", "detail": "+%d%% подмотки" % bonus, "status": "ХОРОШИЙ КОНТРОЛЬ · подмотка +%d%%" % bonus, "color": CONTROL}, true)
	return result
