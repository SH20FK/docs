# lib/tracker.gd
# Движок автотрекинга шагов плана: валидация условий и обновление статусов.

# Проверка выполнения конкретного шага
static func evaluate_check(game: PaxGame, check: Dictionary, store_flags: Dictionary) -> bool:
	var kind: String = str(check.get("kind", "manual"))
	var a: Variant = check.get("a", "")
	var b: Variant = check.get("b", "")
	var body: String = str(check.get("body", game.home_body()))

	match kind:
		"war":
			var target: String = str(a)
			return game.at_war(target)
		"peace":
			var target: String = str(a)
			return not game.at_war(target)
		"province":
			var prov_id: int = int(check.get("id", a))
			var expected_owner: String = str(b)
			if expected_owner.is_empty():
				expected_owner = game.country()
			return game.province_owner(body, prov_id) == expected_owner
		"law":
			var needle: String = str(a).to_lower()
			var current_laws: PackedStringArray = game.laws()
			for l in current_laws:
				if l.to_lower().contains(needle):
					return true
			return false
		"flag":
			var flag_key: String = str(a)
			return bool(store_flags.get(flag_key, false))
		"resource":
			var res_key: String = str(a)
			var needed_amount: float = float(b)
			var stocks: Dictionary = game.resources(body)
			var current_amount: float = float(stocks.get(res_key, 0.0))
			return current_amount >= needed_amount
		"money":
			var needed_money: float = float(a)
			return game.money() >= needed_money
		"colony":
			var colony_body: String = str(a)
			return game.colonies().has(colony_body)
		"relation":
			var country_name: String = str(a)
			var threshold: float = float(b)
			return game.relation(country_name) >= threshold
		"ship_arrived":
			var ship_tag: String = str(a)
			var arrived_key: String = "ship_arrived_" + ship_tag
			return bool(store_flags.get(arrived_key, false))
		"army_near":
			var target_str: String = str(a)
			var min_count: int = int(b)
			# Проверка наличия провинций у игрока рядом с целевой точкой
			var prov_count: int = game.provinces_of(body, game.country()).size()
			return prov_count >= min_count
		"army_count":
			var min_armies: int = int(a)
			var total_provs: int = game.provinces_of(body, game.country()).size()
			return total_provs >= min_armies
		"manual":
			return false
		_:
			return false

# Прогон проверки по всем планам и шагам
static func update_all_plans(game: PaxGame, plans: Array, store_flags: Dictionary) -> Array:
	var current_day: int = game.day()
	var completed_steps: Array = []

	for plan_any in plans:
		if not (plan_any is Dictionary):
			continue
		var plan: Dictionary = plan_any
		if plan.get("status", "") != "active":
			continue

		var steps: Array = plan.get("steps", [])
		var all_done: bool = true

		for step_any in steps:
			if not (step_any is Dictionary):
				continue
			var step: Dictionary = step_any
			var status: String = str(step.get("status", "pending"))

			if status == "pending":
				var check: Dictionary = step.get("check", {})
				var since_day: int = int(step.get("since_day", current_day))
				var days_term: int = int(step.get("days", 30))

				if evaluate_check(game, check, store_flags):
					step["status"] = "done"
					step["done_day"] = current_day
					completed_steps.append({
						"plan_id": plan.get("id", ""),
						"step": step
					})
				elif days_term > 0 and (current_day - since_day) > (days_term * 2):
					step["status"] = "stalled"
					all_done = false
				else:
					all_done = false
			elif status != "done":
				all_done = false

		if all_done and not steps.is_empty():
			plan["status"] = "done"

	return completed_steps
