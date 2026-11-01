class_name AutoPlayer
## Бот для балансных тестов и демо: подсекает сразу и держит
## натяжение ниже опасной зоны.

const TENSION_LIMIT := 0.75


static func wants_action(session: FishingSession) -> bool:
	match session.state:
		FishingSession.State.BITING:
			return true
		FishingSession.State.FIGHTING:
			return session.tension < TENSION_LIMIT
	return false
