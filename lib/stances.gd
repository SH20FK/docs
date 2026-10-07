# lib/stances.gd
# Классификатор геополитических позиций держав, тиры, 10 осей координат, значимость и сигнатурный хеш.

enum Tier {
	ALLY = 0,
	FRIENDLY = 1,
	NEUTRAL = 2,
	WARY = 3,
	HOSTILE = 4,
	AT_WAR = 5
}

static var _border_cache: Dictionary = {} # "body:country_a:country_b" -> bool

static func invalidate_cache() -> void:
	_border_cache.clear()

# Определение тира по шкале отношений
static func evaluate_base_tier(relation: float, is_at_war: bool) -> int:
	if is_at_war:
		return Tier.AT_WAR
	if relation >= 0.85:
		return Tier.ALLY
	elif relation >= 0.65:
		return Tier.FRIENDLY
	elif relation >= 0.35:
		return Tier.NEUTRAL
	elif relation >= 0.15:
		return Tier.WARY
	else:
		return Tier.HOSTILE

# Проверка наличия сухопутной границы между державами с кэшированием
static func check_shared_border(game: PaxGame, body_name: String, country_a: String, country_b: String) -> bool:
	var cache_key: String = "%s:%s:%s" % [body_name, country_a, country_b]
	if _border_cache.has(cache_key):
		return bool(_border_cache[cache_key])

	var my_provs: Array = game.provinces_of(body_name, country_a)
	if my_provs.is_empty():
		_border_cache[cache_key] = false
		return false

	for p_any in my_provs:
		var p_id: int = int(p_any)
		var p_info: Dictionary = game.province(body_name, p_id)
		var neighbours: Array = p_info.get("neighbours", [])
		for n_any in neighbours:
			var n_id: int = int(n_any)
			var owner: String = game.province_owner(body_name, n_id)
			if owner == country_b:
				_border_cache[cache_key] = true
				return true

	_border_cache[cache_key] = false
	return false

# Полный пересчёт тиров и индексов для конкретной державы
static func evaluate_country(game: PaxGame, country_name: String, existing_info: Dictionary, history: Array) -> Dictionary:
	var player_country: String = game.country()
	var home_body: String = game.home_body()
	var is_war: bool = game.at_war(country_name)
	var rel_raw: float = game.relation(country_name)
	if rel_raw < 0.0:
		rel_raw = 0.5 # fallback

	var base_tier: int = evaluate_base_tier(rel_raw, is_war)
	var has_border: bool = check_shared_border(game, home_body, player_country, country_name)
	var prov_ids: Array = game.provinces_of(home_body, country_name)
	var prov_count: int = prov_ids.size()

	# Сбор флагов и активности в истории
	var flags: Array = []
	if has_border:
		flags.append("пограничник")

	var is_traitor: bool = false
	var action_count: int = 0
	var cur_day: int = game.day()

	for h_any in history:
		if h_any is Dictionary:
			var h_dict: Dictionary = h_any
			var text_val: String = str(h_dict.get("text", ""))
			var h_day: int = int(h_dict.get("day", 0))
			if text_val.contains(country_name):
				if (cur_day - h_day) <= 365:
					action_count += 1
				if text_val.contains("разрыв") or text_val.contains("нападение"):
					is_traitor = true

	if is_traitor:
		flags.append("предатель")
		if base_tier < Tier.HOSTILE:
			base_tier = Tier.HOSTILE

	if is_war:
		flags.append("война")
	elif base_tier == Tier.ALLY:
		flags.append("союз")

	if prov_count <= 2:
		flags.append("лёгкая цель")

	var prev_flags: Array = existing_info.get("flags", [])
	if prev_flags.has("должник"):
		flags.append("должник")

	# 1. Расчёт индексов угроз и возможностей
	var strength_score: float = clampf(float(prov_count) * 4.0, 0.0, 40.0)
	var proximity_score: float = 25.0 if has_border else 5.0
	var hostility_score: float = 0.0
	match base_tier:
		Tier.AT_WAR:
			hostility_score = 20.0
		Tier.HOSTILE:
			hostility_score = 16.0
		Tier.WARY:
			hostility_score = 10.0
		Tier.NEUTRAL:
			hostility_score = 4.0
		_:
			hostility_score = 0.0
	var allies_score: float = 5.0
	var aggression_score: float = 5.0 if is_traitor else 0.0

	var threat_index: float = clampf(strength_score + proximity_score + hostility_score + allies_score + aggression_score, 0.0, 100.0)

	var weakness_score: float = clampf(40.0 - float(prov_count) * 3.0, 5.0, 40.0)
	var wealth_score: float = 20.0
	var opp_proximity: float = 20.0 if has_border else 5.0
	var isolation_score: float = 10.0 if flags.has("лёгкая цель") else 0.0

	var opportunity_index: float = clampf(weakness_score + wealth_score + opp_proximity + isolation_score, 0.0, 100.0)
	if base_tier == Tier.ALLY:
		opportunity_index = 0.0

	# 2. Расчёт 10 осей
	var axis_relation: float = clampf((rel_raw - 0.5) * 2.0, -1.0, 1.0)
	var axis_power: float = clampf(float(prov_count) * 3.2 + (15.0 if has_border else 5.0) + (15.0 if is_war else 0.0), 5.0, 100.0)
	var axis_threat: float = threat_index
	var axis_opportunity: float = opportunity_index
	var axis_economy: float = clampf(float(prov_count) * 3.5 + 10.0, 5.0, 100.0)
	var axis_army: float = clampf(float(prov_count) * 3.0 + (20.0 if is_war else 8.0), 5.0, 100.0)
	var axis_distance: float = 0.0 if has_border else clampf(35.0 + float(prov_count) * 1.5, 10.0, 100.0)
	var axis_border: float = 100.0 if has_border else 0.0
	var axis_activity: float = clampf(float(action_count) * 20.0, 5.0, 100.0)
	var axis_stability: float = clampf(75.0 - (30.0 if is_war else 0.0) - (20.0 if is_traitor else 0.0) + (15.0 if base_tier == Tier.ALLY else 0.0), 10.0, 100.0)

	# 3. Формула значимости (Significance)
	var significance: float = (
		0.4 * axis_power +
		0.3 * axis_border +
		0.2 * (100.0 if is_war else 0.0) +
		0.1 * axis_activity
	)

	var since_day: int = int(existing_info.get("since_day", cur_day))

	return {
		"tier": base_tier,
		"relation": rel_raw,
		"war": is_war,
		"border": has_border,
		"flags": flags,
		"since_day": since_day,
		"threat_index": threat_index,
		"opportunity_index": opportunity_index,
		"provinces": prov_count,
		"significance": significance,
		# 10 осей
		"axis_relation": axis_relation,
		"axis_power": axis_power,
		"axis_threat": axis_threat,
		"axis_opportunity": axis_opportunity,
		"axis_economy": axis_economy,
		"axis_army": axis_army,
		"axis_distance": axis_distance,
		"axis_border": axis_border,
		"axis_activity": axis_activity,
		"axis_stability": axis_stability
	}

# Получение конкретного значения оси для державы
static func get_axis_value(country_data: Dictionary, axis_key: String) -> float:
	match axis_key:
		"relation":
			return float(country_data.get("axis_relation", (float(country_data.get("relation", 0.5)) - 0.5) * 2.0))
		"power":
			return float(country_data.get("axis_power", float(country_data.get("provinces", 1)) * 3.0))
		"threat":
			return float(country_data.get("axis_threat", country_data.get("threat_index", 0.0)))
		"opportunity", "opp":
			return float(country_data.get("axis_opportunity", country_data.get("opportunity_index", 0.0)))
		"economy", "econ":
			return float(country_data.get("axis_economy", 50.0))
		"army":
			return float(country_data.get("axis_army", 50.0))
		"distance", "dist":
			return float(country_data.get("axis_distance", 50.0))
		"border":
			return float(country_data.get("axis_border", 100.0 if country_data.get("border", false) else 0.0))
		"activity":
			return float(country_data.get("axis_activity", 20.0))
		"stability":
			return float(country_data.get("axis_stability", 70.0))
		_:
			return float(country_data.get("axis_power", 50.0))

# Генерация сигнатурного хеша для оптимизации токенов
static func compute_data_hash(country_name: String, stance_dict: Dictionary, recent_events_text: String, active_plan_id: String) -> String:
	var rel_val: float = float(stance_dict.get("relation", 0.5))
	var pow_val: float = float(stance_dict.get("axis_power", 50.0))
	var flags_str: String = str(stance_dict.get("flags", []))
	var raw_signature: String = "%s_%.2f_%.1f_%s_%s_%s" % [country_name, rel_val, pow_val, flags_str, recent_events_text, active_plan_id]
	return str(raw_signature.hash())

# Пакетное обновление всей таблицы держав
static func recalculate_all(game: PaxGame, current_stances: Dictionary, history: Array) -> Dictionary:
	var result: Dictionary = {}
	var all_countries: PackedStringArray = game.countries()
	for country_name in all_countries:
		if country_name == game.country():
			continue
		var existing: Dictionary = current_stances.get(country_name, {})
		result[country_name] = evaluate_country(game, country_name, existing, history)
	return result