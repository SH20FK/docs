# lib/simulator.gd
# Военный симулятор и калькулятор шансов победы в войне.

static func simulate_war(game: PaxGame, target_country: String, stances: Dictionary) -> Dictionary:
	var player_country: String = game.country()
	var home_body: String = game.home_body()

	var my_provs: int = game.provinces_of(home_body, player_country).size()
	var enemy_provs: int = game.provinces_of(home_body, target_country).size()
	if enemy_provs <= 0:
		enemy_provs = 1

	var target_info: Dictionary = stances.get(target_country, {})
	var has_border: bool = bool(target_info.get("border", false))
	var threat_idx: float = float(target_info.get("threat_index", 20.0))

	# Базовое соотношение сил по территориям и экономике
	var my_money: float = game.money()
	var money_factor: float = clampf(my_money / 2000.0, 0.5, 2.0)

	var power_ratio: float = (float(my_provs) / float(enemy_provs)) * (1.1 if has_border else 0.9) * money_factor

	# Оценка риска вступления коалиции (подсчёт врагов и союзников цели)
	var allies_count: int = 0
	var my_allies_count: int = 0
	for c_name in stances.keys():
		var s: Dictionary = stances[c_name]
		var t: int = int(s.get("tier", 2))
		if t == 0: # ALLY к нам
			my_allies_count += 1
		elif t == 4 and bool(s.get("border", false)):
			# Пограничный враг, который может ударить в спину
			allies_count += 1

	var coalition_risk: float = clampf(float(allies_count) * 20.0 + (threat_idx * 0.3), 5.0, 95.0)

	# Расчёт итогового шанса победы (0..100)
	var base_chance: float = 50.0 + (power_ratio - 1.0) * 35.0
	base_chance -= (coalition_risk * 0.25)
	base_chance += (float(my_allies_count) * 8.0)
	var win_chance: float = clampf(base_chance, 5.0, 98.0)

	# Прогноз длительности кампании (дней)
	var duration_days: int = int(clampf(float(enemy_provs) * 30.0 / (power_ratio if power_ratio > 0.1 else 0.1), 60.0, 900.0))

	# Вердикт
	var verdict: String = "strat_sim_verdict_favorable"
	if win_chance < 40.0 or coalition_risk > 60.0:
		verdict = "strat_sim_verdict_critical"
	elif win_chance < 65.0:
		verdict = "strat_sim_verdict_risky"

	return {
		"win_chance": win_chance,
		"power_ratio": power_ratio,
		"coalition_risk": coalition_risk,
		"duration_days": duration_days,
		"verdict_key": verdict,
		"my_provinces": my_provs,
		"enemy_provinces": enemy_provs
	}
