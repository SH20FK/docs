# lib/planner.gd
# Планировщик: отправка запросов в канал strategist, валидация и нормализация планов через DTO-фабрики.

const StoreScript = preload("res://mods/strategist/lib/store.gd")

static func request_plan(
	mod_ref: PaxMod,
	game: PaxGame,
	brief_text: String,
	user_goal: String,
	profile: String,
	on_success: Callable,
	on_failure: Callable
) -> void:
	var profile_instruction: String = ""
	match profile:
		"akademik":
			profile_instruction = "Стиль: Академик. Опирайся на точные расчеты, экономический баланс и баланс ресурсов."
		"komandir":
			profile_instruction = "Стиль: Полевой командир. Лаконичные военные директивы, акцент на силе и нейтрализации угроз."
		"lis":
			profile_instruction = "Стиль: Лис. Дипломатические маневры, скрытые преимущества, косвенные ходы и союзы."
		"orakul":
			profile_instruction = "Стиль: Оракул. Предвидение кризисов, исторические аналогии и предупреждение скрытых угроз."
		_:
			profile_instruction = "Стиль: Стратегический советник."

	var prompt_body: String = """
%s
%s
Цель правителя: %s

Составь стратегический план строго в формате JSON:
{
  "title": "Краткое название плана",
  "goal": "Измеримая цель плана",
  "horizon_days": 365,
  "kind": "strategic",
  "steps": [
    {
      "n": 1,
      "what": "Конкретное действие",
      "why": "Зачем это нужно",
      "needs": {"money": 100},
      "days": 60,
      "check": {"kind": "money|war|peace|province|law|flag|relation|manual", "a": "цель_или_порог", "b": 100}
    }
  ],
  "risks": ["Риск 1 с указанием державы", "Риск 2"],
  "indicators": ["Показатель 1", "Показатель 2"],
  "reserve": "План Б на случай неудачи"
}
Ответь ТОЛЬКО валидным JSON.
""" % [profile_instruction, brief_text, user_goal if not user_goal.is_empty() else "Обеспечить безопасность и доминирование державы"]

	var callback: Callable = func(answer: Dictionary) -> void:
		if answer.is_empty():
			on_failure.call("strat_ai_unavailable")
			return

		var plan: Dictionary = validate_and_normalize_plan(game, answer, user_goal)
		if plan.is_empty():
			_retry_short_plan(mod_ref, game, brief_text, user_goal, on_success, on_failure)
		else:
			on_success.call(plan)

	var sent: bool = mod_ref.ask_ai("strategist", prompt_body, {}, callback)
	if not sent:
		on_failure.call("strat_ai_unavailable")

# Повторный запрос при невалидной первой схеме
static func _retry_short_plan(
	mod_ref: PaxMod,
	game: PaxGame,
	brief_text: String,
	user_goal: String,
	on_success: Callable,
	on_failure: Callable
) -> void:
	var short_prompt: String = """
%s
Цель: %s
Верни ТОЛЬКО JSON с 3 шагами:
{
  "title": "Название",
  "goal": "Цель",
  "horizon_days": 180,
  "steps": [
    {"n": 1, "what": "Шаг 1", "why": "Зачем", "needs": {}, "days": 30, "check": {"kind": "manual"}},
    {"n": 2, "what": "Шаг 2", "why": "Зачем", "needs": {}, "days": 60, "check": {"kind": "manual"}},
    {"n": 3, "what": "Шаг 3", "why": "Зачем", "needs": {}, "days": 90, "check": {"kind": "manual"}}
  ],
  "risks": ["Главный риск"],
  "reserve": "Резерв"
}
""" % [brief_text, user_goal]

	var retry_cb: Callable = func(answer: Dictionary) -> void:
		if answer.is_empty():
			on_failure.call("strat_ai_unavailable")
			return
		var plan: Dictionary = validate_and_normalize_plan(game, answer, user_goal)
		if plan.is_empty():
			on_failure.call("strat_ai_unavailable")
		else:
			on_success.call(plan)

	var sent: bool = mod_ref.ask_ai("strategist", short_prompt, {}, retry_cb)
	if not sent:
		on_failure.call("strat_ai_unavailable")

# Валидация структуры и полей плана с использованием DTO фабрик
static func validate_and_normalize_plan(game: PaxGame, raw: Dictionary, default_goal: String) -> Dictionary:
	var title: String = str(raw.get("title", ""))
	if title.is_empty():
		title = "Стратегический план"

	var goal: String = str(raw.get("goal", default_goal))
	var horizon_days: int = int(raw.get("horizon_days", 365))
	var steps_raw: Array = raw.get("steps", [])

	if steps_raw.is_empty():
		return {}

	var normalized_steps: Array = []
	var cur_day: int = game.day()

	for i in range(steps_raw.size()):
		var st_any: Variant = steps_raw[i]
		if not (st_any is Dictionary):
			continue
		var st: Dictionary = st_any
		var what: String = str(st.get("what", ""))
		if what.is_empty():
			continue

		var why: String = str(st.get("why", ""))
		var needs: Dictionary = st.get("needs", {})
		var days_term: int = int(st.get("days", 30))
		var check: Dictionary = st.get("check", {})

		var check_kind: String = str(check.get("kind", "manual"))
		var allowed_kinds: Array = ["war", "peace", "province", "law", "flag", "resource", "money", "army_near", "army_count", "colony", "ship_arrived", "relation", "manual"]
		if not allowed_kinds.has(check_kind):
			check["kind"] = "manual"

		var step_dto: Dictionary = StoreScript.create_step(i + 1, what, why, needs, days_term, check, cur_day)
		normalized_steps.append(step_dto)

	if normalized_steps.is_empty():
		return {}

	var risks: Array = raw.get("risks", [])
	var reserve: String = str(raw.get("reserve", ""))
	var kind: String = str(raw.get("kind", "strategic"))

	return StoreScript.create_plan(title, goal, horizon_days, cur_day, kind, normalized_steps, risks, reserve)
