# lib/brief.gd
# Сборка компактного брифинга текущего положения дел для языковой модели с учётом доктрины.

const DoctrinesScript = preload("res://mods/strategist/lib/doctrines.gd")

static func build_brief(game: PaxGame, store: RefCounted) -> String:
	var lines: PackedStringArray = []

	var my_country: String = game.country()
	var gov_form: String = game.government_form()
	var cur_date: String = game.date_text()
	lines.append("Держава: %s. Форма: %s. Дата: %s." % [my_country, gov_form, cur_date])

	# Доктрина
	var doctrine_id: String = str(store.get("doctrine")) if store != null and store.get("doctrine") != null else "fortress"
	lines.append(DoctrinesScript.get_prompt_modifier(doctrine_id))

	var home_body: String = game.home_body()
	var money_val: float = game.money()
	var res_dict: Dictionary = game.resources(home_body)
	var res_parts: PackedStringArray = []
	for k in res_dict.keys():
		res_parts.append("%s: %s" % [str(k), str(res_dict[k])])
	var res_str: String = ", ".join(res_parts) if not res_parts.is_empty() else "стандартные"
	lines.append("Казна: %.0f. Ресурсы: %s." % [money_val, res_str])

	# Войны и отношения по тирам
	var stances: Dictionary = store.get("stances") if store != null and store.get("stances") != null else {}
	var wars_list: PackedStringArray = []
	var hostile_list: PackedStringArray = []
	var wary_list: PackedStringArray = []
	var ally_list: PackedStringArray = []
	var border_list: PackedStringArray = []

	for c_name in stances.keys():
		var s: Dictionary = stances[c_name]
		var tier: int = int(s.get("tier", 2))
		if s.get("war", false):
			wars_list.append(str(c_name))
		elif tier == 0: # ALLY
			ally_list.append(str(c_name))
		elif tier == 4: # HOSTILE
			hostile_list.append(str(c_name))
		elif tier == 3: # WARY
			wary_list.append(str(c_name))

		if s.get("border", false):
			border_list.append(str(c_name))

	lines.append("Войны: %s." % (", ".join(wars_list) if not wars_list.is_empty() else "нет"))
	lines.append("Враждебные: %s. Настороженные: %s." % [
		", ".join(hostile_list) if not hostile_list.is_empty() else "нет",
		", ".join(wary_list) if not wary_list.is_empty() else "нет"
	])
	lines.append("Союзники: %s. Границы с: %s." % [
		", ".join(ally_list) if not ally_list.is_empty() else "нет",
		", ".join(border_list) if not border_list.is_empty() else "нет"
	])

	var my_provs: Array = game.provinces_of(home_body, my_country)
	lines.append("Наши провинции на %s: всего %d." % [home_body, my_provs.size()])

	# Последнее событие из истории
	var history: Array = store.get("history") if store != null and store.get("history") != null else []
	if not history.is_empty() and history[0] is Dictionary:
		var last_ev: Dictionary = history[0]
		lines.append("Хроника (последнее): %s (день %d)." % [str(last_ev.get("text", "")), int(last_ev.get("day", 0))])

	# Активный план
	var active_plan: Dictionary = store.call("get_active_plan") if store != null and store.has_method("get_active_plan") else {}
	if not active_plan.is_empty():
		var steps: Array = active_plan.get("steps", [])
		var done_count: int = 0
		var current_step_text: String = ""
		for st_any in steps:
			if st_any is Dictionary:
				var st: Dictionary = st_any
				if st.get("status", "") == "done":
					done_count += 1
				elif current_step_text.is_empty():
					current_step_text = str(st.get("what", ""))
		lines.append("Активный план: «%s», шаги %d/%d, текущий — «%s»." % [
			str(active_plan.get("title", "")),
			done_count,
			steps.size(),
			current_step_text
		])

	return "\n".join(lines)
